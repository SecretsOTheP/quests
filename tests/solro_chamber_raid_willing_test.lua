-- Run from the quest root with Lua 5.1.
package.path = "./lua_modules/?.lua;" .. package.path;
local checks = 0;
local function check(value, message)
    checks = checks + 1;
    assert(value, message);
end
local buckets, roster, total, globals, writes, moved, eligible, claims;
local raid = {valid = true};
function raid:IsRaidMember(name) return name == "Visitor"; end
function raid:RaidCount() return total; end
function raid:GetMember(i) return roster[i] or {valid = false}; end
local client = {valid = true};
function client:GetName() return "Visitor"; end
function client:GetRaid() return raid; end
function client:Message() end
function client:MovePC(zone, x, y, z, heading)
    moved = {zone, x, y, z, heading};
end
function client:GetPet() return {valid = false}; end
local function reset(size, flagged, percent)
    buckets = {pop_alt_access_enabled = "1", pop_raid_flagged_percent = tostring(percent or 85)};
    total, roster, globals, writes, moved, eligible, claims = size, {}, {}, 0, nil, true, 0;
    raid.valid = true;
    for i = 0, flagged - 1 do
        roster[i] = {valid = true, flags = {sol_room = "11111", zeks = "7"}};
    end
end
eq = {
    get_data = function(key) return buckets[key] or ""; end,
    get_qglobals = function(c) return c == client and globals or c.flags; end,
    set_global = function(key, value) globals[key] = value; writes = writes + 1; end,
    delete_global = function(key) globals[key] = nil; writes = writes + 1; end
};
local access = require("pop_internal_access");
for _, size in ipairs({7, 20, 40, 54, 72}) do
    for percent = 1, 100 do
        local required = math.ceil(size * percent / 100);
        reset(size, required, percent);
        check(access.CanRaidWill(client, "solro"), "exact threshold denied");
        reset(size, required - 1, percent);
        check(not access.CanRaidWill(client, "solro"), "below threshold admitted");
    end
end
reset(40, 34);
buckets.pop_alt_access_enabled = "0";
check(not access.CanRaidWill(client, "solro"), "disabled access admitted");
reset(40, 34); raid.valid = false;
check(not access.CanRaidWill(client, "solro"), "no raid admitted");
reset(0, 0);
check(not access.CanRaidWill(client, "solro"), "empty raid admitted");
reset(40, 34);
local outsider = {GetName = function() return "Outsider"; end, GetRaid = function() return raid; end};
check(not access.CanRaidWill(outsider, "solro"), "nonmember admitted");
for _, raw in ipairs({"", "invalid", "0", "101", "-1", "85.9", "85suffix"}) do
    reset(40, 34); buckets.pop_raid_flagged_percent = raw;
    check(access.CanRaidWill(client, "solro"), "native percentage parsing mismatch");
    roster[33] = nil;
    check(not access.CanRaidWill(client, "solro"), "invalid percentage default mismatch");
end
reset(40, 34);
roster[33].valid = false;
check(not access.CanRaidWill(client, "solro"), "absent member supplied flags");
for _, flags in ipairs({{}, {sol_room = "11110", zeks = "7"}, {sol_room = "11111", zeks = "6"}}) do
    reset(40, 34); roster[33].flags = flags;
    check(not access.CanRaidWill(client, "solro"), "incomplete member counted");
end
local function script(path)
    local env = setmetatable({}, {__index = _G});
    setfenv(assert(loadfile(path)), env)();
    return env;
end
local player = script("solrotower/player.lua");
for _, door in ipairs({44, 45}) do
    local e = {self = client, door = {GetDoorID = function() return door; end}};
    reset(40, 34);
    player.event_click_door(e);
    check(moved and moved[1] == 212 and moved[3] == -847, "borrowed chamber teleport missing");
    check(writes == 0 and not globals.sol_room and not globals.zeks, "door granted permanent flags");
    reset(40, 33);
    player.event_click_door(e);
    check(not moved, "door ignored ratio");
    reset(40, 34); buckets.pop_alt_access_enabled = "0";
    player.event_click_door(e);
    check(not moved, "door ignored disabled setting");
    reset(0, 0); buckets.pop_alt_access_enabled = "0";
    globals = {sol_room = "11111", zeks = "7"};
    player.event_click_door(e);
    check(moved and writes == 0, "normal personal access changed");
end
package.loaded.projection_eligibility = {
    ShowStatus = function() return false; end,
    Count = function() return claims; end,
    CanFlag = function() return eligible; end,
    SaveCount = function(_, n) claims = n; end
};
function string.findi(s, text) return string.find(string.lower(s), string.lower(text), 1, true); end
local projection = script("solrotower/A_Planar_Projection.lua");
local hail = {self = {}, other = client, message = "hail"};
reset(40, 34); globals = {pofire = "1", zeks = "7"};
projection.event_say(hail);
check(globals.cl_solusek == "1" and globals.pofire == "1" and not globals.sol_room, "missing minis did not produce checklist only");
check(claims == 1, "checklist did not consume claim");
projection.event_say(hail);
check(claims == 1 and writes == 1, "repeated hail duplicate claim");
globals.sol_room = "11111";
projection.event_say(hail);
check(globals.pofire == "2" and not globals.cl_solusek, "normal completion failed");
reset(40, 34); eligible = false;
projection.event_say(hail);
check(writes == 0 and claims == 0, "ineligible player received reward");
reset(40, 34); claims = 72;
projection.event_say(hail);
check(writes == 0 and claims == 72, "flag cap bypassed");
reset(40, 34); globals = {sol_room = "11111", pofire = "1", zeks = "6"};
projection.event_say(hail);
check(globals.cl_solusek == "1" and globals.pofire == "1", "missing Rallos completion bypass");
print("Sol Ro chamber raid-willing: " .. checks .. " checks passed");
