local module = {}
local turn_ins = {[29112] = true, [29131] = true, [29132] = true}

local function key(client)
    return "pop_spell_pending:" .. client:CharacterID()
end

local function review(client)
    client:Message(15, "Your spell or parchment delivery needs GM review. Please contact a GM before handing in more items; hailing will not retry an uncertain delivery.")
end

local function save(name, value)
    -- SetData has no success return; verify persistence before delivering anything.
    local ok, verified = pcall(function()
        eq.set_data(name, value)
        return eq.get_data(name) == value
    end)
    return ok and verified
end

-- P = pending; I = delivery attempted; R = legacy/malformed record needing review.
-- No expiry. Never turn an uncertain delivery back into a pending one on a new trade.
local function hold(client, id, charges)
    local name = key(client)
    local pending = eq.get_data(name) or ""
    if pending == "" then
        pending = "P|"
    elseif not pending:match("^[PIR]|") then
        pending = "R|" .. pending
    end
    if not save(name, pending .. id .. ":" .. charges .. ";") then
        eq.debug("PoK spell hold could not be verified: character " .. client:CharacterID() .. ", item " .. id .. ", charges " .. charges)
        review(client)
    end
end

function module.Claim(e)
    local name = key(e.other)
    local pending = eq.get_data(name) or ""
    if pending == "" then return end
    -- Old unmarked queues may already have delivered their first item before a crash.
    -- Preserve them for review rather than guessing that another delivery is safe.
    if pending:sub(1, 2) ~= "P|" then review(e.other); return end
    pending = pending:sub(3)
    if pending == "" or pending:gsub("%d+:%d+;", "") ~= "" then review(e.other); return end
    while pending ~= "" do
        local id, charges, rest = pending:match("^(%d+):(%d+);(.*)$")
        if not id then break end
        id, charges = tonumber(id), tonumber(charges)
        local item = ItemInst(id, charges)
        if not item.valid then break end
        local inventory = e.other:GetInventory()
        local slot = inventory:FindFreeSlot(false, false, item:GetItem():Size())
        -- Never use the cursor or let SummonItem choose a ground-drop fallback.
        if slot == -1 or slot == 65535 or slot == 30 or inventory:GetItem(slot).valid then break end
        -- Persist the entire queue before touching inventory. A crash, exception or
        -- failed completion write leaves I| intact and future hails stop for a GM.
        if not save(name, "I|" .. pending) then review(e.other); return end
        e.other:SummonItem(id, charges, slot, true)
        local delivered = inventory:GetItem(slot)
        if not delivered.valid or delivered:GetID() ~= id or delivered:GetCharges() ~= charges then review(e.other); return end
        if eq.get_data(name) ~= "I|" .. pending then review(e.other); return end
        if not save(name, rest ~= "" and "P|" .. rest or "") then review(e.other); return end
        pending = rest
        e.other:Message(15, "You receive " .. item:GetName() .. ".")
    end
    if pending ~= "" then
        e.other:Message(15, "Your spell or parchment is being held for you. Make room in your bags, then hail any planar spell turn-in vendor to collect it.")
    end
end

function module.ReturnProtectedItems(e)
    local returned = false
    for slot = 1, 4 do
        local field = "item" .. slot
        local item = e.trade[field]
        if item and item.valid and turn_ins[item:GetID()] then
            hold(e.other, item:GetID(), math.max(1, item:GetCharges()))
            e.trade[field] = nil
            returned = true
        end
    end
    if returned then module.Claim(e) end
    return returned
end

function module.RejectMultipleTurnIns(e)
    local count = 0
    for slot = 1, 4 do
        local item = e.trade["item" .. slot]
        if item and item.valid and turn_ins[item:GetID()] then
            count = count + math.max(1, item:GetCharges())
        end
    end
    if count <= 1 then return false end
    e.other:Message(15, "Please hand me only one parchment or rune at a time.")
    module.ReturnProtectedItems(e)
    return true
end

-- Inspect without consuming; Reward records what is owed before clearing it.
function module.Count(e, id)
    for slot = 1, 4 do
        local item = e.trade["item" .. slot]
        if item and item.valid and item:GetID() == id then return 1 end
    end
    return 0
end

function module.Reward(e, input_id, reward_id)
    if module.Count(e, input_id) == 0 then return end
    local reward = ItemInst(reward_id, 1)
    if not reward.valid then
        module.ReturnProtectedItems(e)
        e.other:Message(15, "I cannot prepare that spell right now. Your parchment has been saved for return.")
        return
    end
    hold(e.other, reward_id, 1)
    for slot = 1, 4 do
        local field = "item" .. slot
        local item = e.trade[field]
        if item and item.valid and item:GetID() == input_id then e.trade[field] = nil end
    end
    -- Preserve the existing faction/reward notification without summoning twice.
    e.other:QuestReward(e.self, 0, 0, 0, 0, 0)
    module.Claim(e)
end

return module
