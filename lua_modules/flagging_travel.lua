-- Keep earned encounter travel open until its deadline or final flagger expires.
-- State belongs to these NPC entities: quest reloads cannot reset the deadline,
-- while a zone unload clears this attempt along with its temporary flaggers.
local M = {};
local PREFIX = "flagging_travel_";
local TIMER = "flagging_travel";
local function Live(npc) return npc and npc.valid and npc:GetID() ~= 0; end
local function Get(npc, key) return npc:GetEntityVariable(PREFIX .. key); end
local function Set(npc, key, value) npc:SetEntityVariable(PREFIX .. key, tostring(value)); end
local function Bind(npc, flagger)
    local deadline = tonumber(Get(flagger, "deadline"));
    if not deadline then return; end
    Set(npc, "deadline", deadline);
    Set(npc, "flagger", flagger:GetID());
end
function M.CanUse(npc)
    if not Live(npc) then return false; end
    local fixed_deadline = tonumber(Get(npc, "fixed_deadline"));
    if fixed_deadline then
        local remaining = fixed_deadline - os.time();
        if remaining <= 0 then
            npc:Depop();
            return false;
        end
        eq.set_timer(TIMER, math.min(10000, remaining * 1000), npc);
        return true;
    end
    if Get(npc, "final_type") == "" then return true; end -- ordinary entrance NPC
    local deadline = tonumber(Get(npc, "deadline"));
    if deadline then
        local flagger = eq.get_entity_list():GetMobID(tonumber(Get(npc, "flagger")) or 0);
        if os.time() >= deadline or not Live(flagger)
            or flagger:GetNPCTypeID() ~= tonumber(Get(npc, "final_type"))
            or tonumber(Get(flagger, "deadline")) ~= deadline then
            npc:Depop();
            return false;
        end
    end
    eq.set_timer(TIMER, 10000, npc);
    return true;
end
function M.StartFixed(npc, deadline)
    if not Live(npc) then return; end
    local current = tonumber(Get(npc, "fixed_deadline"));
    -- Keeper supplies one absolute deadline to both Tylis copies. A later
    -- spawn callback or repeated setup must never extend their window.
    if not current or deadline < current then Set(npc, "fixed_deadline", deadline); end
    eq.stop_timer("depop", npc);
    return M.CanUse(npc);
end
function M.Start(npc, final_type)
    if not Live(npc) then return; end
    if Get(npc, "final_type") == "" then Set(npc, "final_type", final_type); end
    eq.stop_timer("depop", npc);
    -- A vortex first opened after the kill gets only the remaining window.
    if Get(npc, "deadline") == "" then
        local flagger = eq.get_entity_list():GetMobByNpcTypeID(final_type);
        if Live(flagger) then Bind(npc, flagger); end
    end
    M.CanUse(npc);
end
function M.OpenWindow(flagger, seconds, types)
    if Get(flagger, "deadline") == "" then Set(flagger, "deadline", os.time() + seconds); end
    local list = eq.get_entity_list():GetNPCList(); -- retain luabind list owner
    for npc in list.entries do
        if Live(npc) and types[npc:GetNPCTypeID()]
            and tonumber(Get(npc, "final_type")) == flagger:GetNPCTypeID() then
            Bind(npc, flagger);
            M.CanUse(npc);
        end
    end
end
function M.OnTimer(e)
    if e.timer == TIMER then M.CanUse(e.self); end
end
return M;
