-- Per-flagger eligibility. Raid/group matching still admits late alts; the
-- kill-time character snapshot also admits earners after camping or raid changes.
-- Entity variables survive quest reloads and disappear with this exact NPC.
local M = {};
local PREFIX = "flagger_v1_";
local function Get(npc, key) return npc:GetEntityVariable(PREFIX .. key); end
local function Set(npc, key, value) npc:SetEntityVariable(PREFIX .. key, tostring(value)); end
local function Number(npc, key) return tonumber(Get(npc, key)) or 0; end
local function Live(mob) return mob and mob.valid and mob:GetID() ~= 0; end
local function Client(mob)
    if not Live(mob) then return nil; end
    if mob:IsClient() then return mob:CastToClient(); end
    if mob:IsPet() then
        local owner = mob:GetOwner();
        if Live(owner) and owner:IsClient() then return owner:CastToClient(); end
    end
    return nil;
end
function M.Notice(npc, key, message)
    if not Live(npc) then eq.debug("[Flagger ERROR] " .. message, 1); return; end
    if Get(npc, "notice_" .. key) == "1" then return; end
    Set(npc, "notice_" .. key, 1);
    local text = "[Flagger " .. npc:GetNPCTypeID() .. " entity=" .. npc:GetID() .. "] " .. message;
    eq.debug(text, 1);
    local list = eq.get_entity_list():GetClientList(); -- retain luabind list owner
    local ids = {};
    for client in list.entries do
        if client.valid and client:GetGM() then ids[#ids + 1] = client:GetID(); end
    end
    for _, id in ipairs(ids) do
        local client = eq.get_entity_list():GetClientByID(id);
        if client.valid and client:GetGM() then client:Message(15, text); end
    end
end
local function Capture(mob)
    local client = Client(mob);
    if not client then return nil; end
    local raid, group = client:GetRaid(), client:GetGroup();
    local context = {rid=0, gid=0, cid=0, characters={}};
    if raid.valid then context.rid = raid:GetID();
    elseif group.valid then context.gid = group:GetID();
    else context.cid = client:CharacterID(); end
    local seen = {};
    local function Add(c)
        local id = c:CharacterID();
        if id > 0 and not seen[id] then
            seen[id] = true; context.characters[#context.characters + 1] = id;
        end
    end
    Add(client);
    -- This entity list contains only clients in this zone instance. Never use
    -- guild membership or an unrestricted database roster as kill eligibility.
    local list = eq.get_entity_list():GetClientList();
    for c in list.entries do
        if c.valid then
            local r, g = c:GetRaid(), c:GetGroup();
            if (context.rid > 0 and r.valid and r:GetID() == context.rid)
                or (context.gid > 0 and g.valid and g:GetID() == context.gid) then Add(c); end
        end
    end
    return context;
end
local function Bind(npc, context)
    if not context then
        M.Notice(npc, "missing_recipient", "ERROR: no valid kill-credit client or pet owner; no eligibility granted.");
        return false;
    end
    Set(npc, "raid", context.rid); Set(npc, "group", context.gid); Set(npc, "solo", context.cid);
    Set(npc, "characters", "|" .. table.concat(context.characters, "|") .. "|");
    Set(npc, "ready", 1); -- publish only after all eligibility fields are written
    M.Notice(npc, "bound", "BOUND: raid=" .. context.rid .. " group=" .. context.gid
        .. " saved characters=" .. #context.characters .. "; raid/group OR saved character may claim.");
    return true;
end
function M.OnSpawn(npc, seconds)
    if Get(npc, "expires") == "" then
        Set(npc, "expires", os.time() + seconds); Set(npc, "paused", 0);
    end
    if Get(npc, "count") == "" then Set(npc, "count", 0); end
end
function M.Spawn(npc_type, grid, unused, x, y, z, heading, killer, seconds)
    -- Capture before spawning, so no queued signal depends on a player remaining
    -- online between the death callback and the flagger's signal handler.
    local context = Capture(killer);
    local npc = eq.spawn2(npc_type, grid, unused, x, y, z, heading);
    if not Live(npc) then
        M.Notice(npc, "spawn_failed", "Flagger " .. npc_type .. " failed to spawn."); return npc;
    end
    M.OnSpawn(npc, seconds or 1200);
    Bind(npc, context);
    return npc;
end
function M.OnSignal(e)
    -- Compatibility with older callers. A late/invalid signal cannot erase or
    -- rebind eligibility already captured by a new death callback.
    if Get(e.self, "ready") == "1" then return; end
    Bind(e.self, Capture(eq.get_entity_list():GetMob(e.signal)));
end
function M.Count(npc) return Number(npc, "count"); end
function M.ShowStatus(e, limit)
    if not e.message:findi("flagstatus") then return false; end
    -- Staff can inspect without enabling GM mode during a player-style test.
    if not e.other:GetGM() and e.other:Admin() < 200 then return false; end
    if Get(e.self, "count") == "" then
        e.other:Message(15, "[Flagger] No saved helper state on this NPC. Use a fresh projection after loading the helper.");
        return true;
    end
    local count = M.Count(e.self);
    local paused = Get(e.self, "paused") == "1";
    local seconds = paused and Number(e.self, "remaining")
        or math.max(0, Number(e.self, "expires") - os.time());
    e.other:Message(15, string.format(
        "[Flagger %d] Bound: %s. Claims used: %d/%d; remaining: %d. Lifetime remaining: %d seconds%s.",
        e.self:GetNPCTypeID(), Get(e.self, "ready") == "1" and "yes" or "no",
        count, limit, math.max(0, limit - count), seconds, paused and " (paused)" or ""));
    return true;
end
function M.SaveCount(npc, count) Set(npc, "count", count); end
function M.OnCombat(npc, joined)
    if joined and Get(npc, "paused") ~= "1" then
        Set(npc, "remaining", math.max(0, Number(npc, "expires") - os.time()));
        Set(npc, "paused", 1);
    elseif not joined and Get(npc, "paused") == "1" then
        Set(npc, "expires", os.time() + Number(npc, "remaining")); Set(npc, "paused", 0);
        eq.set_timer("depop", Number(npc, "remaining") * 1000, npc);
    end
end
function M.CanFlag(npc, mob)
    local client = Client(mob);
    if not client or not mob:IsClient() then return false; end
    local remaining = Get(npc, "paused") == "1" and Number(npc, "remaining")
        or Number(npc, "expires") - os.time();
    if remaining <= 0 then npc:Depop(); return false; end
    if Get(npc, "paused") ~= "1" then
        -- Quest reload may stop timers; re-arm only the original remainder.
        eq.set_timer("depop", remaining * 1000, npc);
    end
    if Get(npc, "ready") ~= "1" then
        M.Notice(npc, "unbound", "ERROR: hail reached this flagger, but kill eligibility was never initialized.");
        return false;
    end
    local character = client:CharacterID();
    local characters = Get(npc, "characters");
    if character == Number(npc, "solo")
        or characters:find("|" .. character .. "|", 1, true) then return true; end
    local raid, group = client:GetRaid(), client:GetGroup();
    if (Number(npc, "raid") > 0 and raid.valid and raid:GetID() == Number(npc, "raid"))
        or (Number(npc, "group") > 0 and group.valid and group:GetID() == Number(npc, "group")) then
        return true;
    end
    M.Notice(npc, "rejected_" .. client:CharacterID(), "REJECT: " .. client:GetName()
        .. " matches neither the original raid/group nor a saved character.");
    return false;
end
return M;
