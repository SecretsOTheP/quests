-- Run from the quest root using Lua 5.1. No server or database changes.
package.path = "./lua_modules/?.lua;" .. package.path;
function string.findi(s, text) return s:lower():find(text:lower(), 1, true); end
local checks = 0;
local function check(ok, message) checks = checks + 1; assert(ok, message); end
local enabled, percent, members, total, now, writes, timers, engaged, present, removed;
local invalid = {valid = false, GroupCount = function() return 0; end};
local raid = {valid = true};
function raid:IsRaidMember(name) return name == "Visitor"; end
function raid:RaidCount() return total; end
function raid:GetMember(i) return members[i] or invalid; end
local function person(name)
    local c = {valid = true, name = name, flags = {}, vars = {}, items = {}, cursor = 0, moves = 0};
    function c:GetName() return self.name; end
    function c:GetRaid() return raid; end
    function c:GetGroup() return invalid; end
    function c:GetItemIDAt() return self.cursor; end
    function c:HasItem(id) return self.items[id] or false; end
    function c:KeyRingCheck(id) return self.key == id; end
    function c:GetEntityVariable(k) return self.vars[k] or ""; end
    function c:SetEntityVariable(k, v) self.vars[k] = v; end
    function c:Message(_, text) self.message = text; end
    function c:MovePC(...) self.move = {...}; self.moves = self.moves + 1; end
    function c:GetPet() return invalid; end
    function c:GetID() return 100; end
    function c:SummonItem(id) self.items[id] = true; writes = writes + 1; end
    return c;
end
local visitor;
local entity = {};
function entity:RemoveFromHateLists() removed = true; end
function entity:IsMobSpawnedByNpcTypeID() return present; end
function entity:GetNPCByNPCTypeID() return {IsEngaged = function() return engaged; end}; end
eq = {
    get_data = function(k) return k == "pop_alt_access_enabled" and enabled or tostring(percent); end,
    get_qglobals = function(c, other) return (other or c).flags; end,
    get_entity_list = function() return entity; end,
    clock = function() return now; end,
    set_timer = function(k) timers[k] = true; end,
    stop_timer = function(k) timers[k] = nil; end,
    set_global = function(k,v) visitor.flags[k] = v; writes = writes + 1; end
};
local access = require("pop_internal_access");
local flags = {crypt = {bertox_key = "1"}, seventh = {seventh = "1"}, tylis = {tylis = "1"}};
local function reset(gate, size, qualified, pct)
    enabled, percent, total, now = "1", pct or 85, size or 40, 1000;
    members, timers, writes, engaged, present, removed = {}, {}, 0, false, true, false;
    raid.valid = true;
    visitor = person("Visitor");
    for i = 0, (qualified or 34) - 1 do
        members[i] = person("Member" .. i);
        members[i].flags = flags[gate];
    end
end
local function script(path)
    local env = setmetatable({}, {__index = _G});
    setfenv(assert(loadfile(path)), env)();
    return env;
end
for gate in pairs(flags) do
    for _, size in ipairs({7, 20, 40, 54, 72}) do
        for pct = 1, 100 do
            local required = math.ceil(size * pct / 100);
            reset(gate, size, required, pct);
            check(access.CanRaidWill(visitor, gate), gate .. " threshold denied");
            reset(gate, size, required - 1, pct);
            check(not access.CanRaidWill(visitor, gate), gate .. " under threshold admitted");
        end
    end
    reset(gate); enabled = "0";
    check(not access.CanRaidWill(visitor, gate), gate .. " disabled access admitted");
    reset(gate); members[33].valid = false;
    check(not access.CanRaidWill(visitor, gate), gate .. " absent member counted");
    reset(gate); raid.valid = false;
    check(not access.CanRaidWill(visitor, gate), gate .. " nonraid admitted");
    reset(gate);
    check(not access.CanRaidWill(visitor, "invalid"), "unknown gate admitted");
end
local crypt = script("codecay/player.lua");
local function door(id) return {self = visitor, door = {GetDoorID = function() return id; end}}; end
reset("crypt"); crypt.event_click_door(door(7));
check(visitor.move and visitor.move[1] == 200 and removed, "borrowed crypt entry failed");
check(writes == 0 and not visitor.flags.bertox_key, "crypt granted personal flag");
reset("crypt",40,33); crypt.event_click_door(door(7));
check(visitor.moves == 0, "crypt ratio bypass");
reset("crypt"); enabled = "0"; visitor.flags = flags.crypt;
crypt.event_click_door(door(7));
check(visitor.moves == 1, "normal crypt flag changed");
reset("crypt"); crypt.event_click_door(door(6));
check(visitor.moves == 0, "unrelated crypt door changed");
local justice = script("pojustice/player.lua");
local tribunal = script("pojustice/The_Tribunal.lua");
local tribunal_npc = {GetSpawnPointID = function() return 345327; end};
local function request() tribunal.event_say({self = tribunal_npc, other = visitor, message = "knowledge"}); end
for id = 1, 6 do
    reset("seventh"); justice.event_click_door(door(id));
    check(not timers.seventh, "ordinary trial portal redirected");
    request();
    check(visitor.vars[access.SeventhRequest] and writes == 0 and not visitor.items[31599], "borrowed request granted permanent key/flag");
    justice.event_click_door(door(id));
    check(timers.seventh, "borrowed portal timer missing");
    justice.event_timer({self = visitor, timer = "seventh"});
    check(visitor.move and visitor.move[1] == 201 and visitor.move[3] == 1310, "Seventh teleport failed");
    check(visitor.vars[access.SeventhRequest] == "", "one-shot request not cleared");
end
reset("seventh"); request(); engaged = true;
justice.event_click_door(door(1)); justice.event_timer({self = visitor, timer = "seventh"});
check(visitor.moves == 0, "engaged Seventh guard bypassed");
reset("seventh"); request(); now = 1300;
justice.event_click_door(door(1));
check(not timers.seventh, "expired request used");
reset("seventh"); request(); justice.event_click_door(door(1)); members[33].valid = false;
justice.event_timer({self = visitor, timer = "seventh"});
check(visitor.moves == 0, "ratio not rechecked at teleport");
reset("seventh"); request(); enabled = "0"; justice.event_click_door(door(1));
check(not timers.seventh, "request bypassed disabled setting");
reset("seventh"); enabled = "0"; visitor.cursor = 31599;
justice.event_click_door(door(1)); justice.event_timer({self = visitor, timer = "seventh"});
check(visitor.moves == 1, "normal Mark of Justice entry changed");
reset("seventh"); enabled = "0"; visitor.flags = {seventh = "1"}; request();
check(visitor.items[31599], "normal Tribunal key recovery changed");
reset("seventh"); enabled = "0";
for _, id in ipairs({31796,31842,31844,31845,31846,31960}) do visitor.items[id] = true; end
request(); check(visitor.flags.seventh == "1" and visitor.items[31599], "normal six-trial completion changed");
local tylis = script("potorment/Tylis_Newleaf.lua");
local function npc(deadline)
    local n = {valid = true, vars = {}, casts = 0};
    if deadline then n.vars.flagging_travel_fixed_deadline = tostring(deadline); end
    function n:GetID() return 1; end
    function n:GetEntityVariable(k) return self.vars[k] or ""; end
    function n:Say(text) self.message = text; end
    function n:CastSpell(spell) self.casts = self.casts + 1; self.spell = spell; end
    function n:Depop() self.valid = false; end
    return n;
end
local function ready(n, message) tylis.event_say({self = n, other = visitor, message = message or "i am ready"}); end
reset("tylis"); local n = npc(); ready(n);
check(n.casts == 0, "raid willing bypassed Screaming Sphere");
members[0].key = 22954; ready(n, "will assist you");
check(n.message and n.casts == 0, "Tylis assist dialogue failed");
ready(n); check(n.casts == 1 and n.spell == 1134 and writes == 0 and not visitor.flags.tylis, "borrowed Tylis entry failed");
reset("tylis"); n = npc(os.time() + 300); ready(n);
check(n.casts == 1, "active Keeper window failed");
reset("tylis"); n = npc(os.time() - 1); members[0].key = 22954; ready(n);
check(n.casts == 0 and not n.valid, "expired Keeper window bypassed");
reset("tylis",40,33); n = npc(os.time() + 300); ready(n);
check(n.casts == 0, "Keeper window bypassed ratio");
reset("tylis"); enabled = "0"; n = npc(); visitor.flags = {tylis = "1"}; visitor.key = 22954; ready(n);
check(n.casts == 1, "normal Tylis access changed");
reset("tylis"); enabled = "0"; n = npc(os.time()+300); ready(n);
check(n.casts == 0, "Tylis disabled access admitted");
print("Internal planar raid willing: " .. checks .. " checks passed");
