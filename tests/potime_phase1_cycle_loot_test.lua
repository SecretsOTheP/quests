-- Run with Lua 5.1: lua tests/potime_phase1_cycle_loot_test.lua <quest-root>
local root = arg[1] or ".";
local checks = 0;
local function check(ok, message)
    assert(ok, message); checks = checks + 1;
end
local function loadscript(path, env)
    local chunk = assert(loadfile(root .. "/" .. path));
    setfenv(chunk, env); chunk(); return env;
end
local function setlocal(fn, name, value)
    for i = 1, 100 do
        local key = debug.getupvalue(fn, i);
        if not key then break end
        if key == name then debug.setupvalue(fn, i, value); return end
    end
    error("Missing test upvalue: " .. name);
end
local cycle = assert(loadfile(root .. "/lua_modules/potime_cycle.lua"))();
local started, ends = 10000000, 10000000 + cycle.duration;
local blank = "00000;00000;000000000000000000;0000;0000;0";
local zeroTimers = "0;0;0;0;0;0;0;0;0;0;0;0";
local function fixture(now, kills, timers, metadata)
    local f = {now = now, saved = {}};
    local eqmock = {
        debug = function() end,
        get_zone_guild_id = function() return 53 end,
        set_global = function(name, value) f.saved[name] = value end,
    };
    f.env = setmetatable({eq = eqmock, os = {time = function() return f.now end},
        require = function(name)
            if name == "potime_cycle" then return cycle end
            error("No local debug module in fixture");
        end}, {__index = _G});
    loadscript("potimeb/223077.lua", f.env);
    check(f.env.SetInstanceVars(kills or blank, timers or zeroTimers), "Load saved state");
    setlocal(f.env.SetInstanceGlobals, "zoneInstanceID", 55001);
    local globals = {};
    if metadata ~= false then globals.time_cycle_55001 = metadata or (started .. ";" .. ends .. ";0") end
    check(f.env.LoadGuildCycle(globals, 55001), "Restore cycle");
    function f:save()
        self.env.SetInstanceGlobals();
        local ks, ts = {}, {};
        for part in self.saved.time_kills_55001:gmatch("[^;]+") do ks[#ks+1] = part end
        for part in self.saved.time_timers_55001:gmatch("[^;]+") do ts[#ts+1] = tonumber(part)*100 end
        return ks, ts;
    end
    return f;
end

local f = fixture(started + 100);
check(f.env.SetBossKilled(1, 1), "First P1 kill accepted");
local kills, timers = f:save();
check(kills[1] == "10000" and timers[1] == ends, "Only killed P1 boss locks until cycle end");
f.now = started + 86400;
check(f.env.CheckPhaseStatus(1), "Unkilled P1 bosses remain available next day");
kills, timers = f:save();
check(kills[1] == "10000" and timers[1] == ends, "P1 shadow credit survives 12 hours");
check(f.env.SetBossKilled(1, 1), "Shadow death still permits encounter progression");
local _, after = f:save();
check(after[1] == ends, "Repeat kill never extends cycle");

local oldTimers = tostring(math.floor((started+43200)/100)) .. ";0;0;0;0;0;0;0;0;0;0;0";
f = fixture(started+86400, "10101;00000;000000000000000000;0000;0000;0", oldTimers);
kills, timers = f:save();
check(kills[1] == "10101" and timers[1] == ends, "Expired old P1 timer preserves partial saved kills");
local restored = fixture(started+172800, f.saved.time_kills_55001, f.saved.time_timers_55001, f.saved.time_cycle_55001);
kills, timers = restored:save();
check(kills[1] == "10101" and timers[1] == ends, "Save/reload retains P1 shadows");
restored.now = ends;
check(restored.env.CheckPhaseStatus(1), "P1 unlocks at cycle end");
kills, timers = restored:save();
check(kills[1] == "00000" and timers[1] == 0, "Old cycle P1 credit expires at boundary");

for phase = 2, 3 do
    f = fixture(started+100);
    check(f.env.SetBossKilled(phase, 1), "P2/3 kill accepted");
    kills, timers = f:save();
    local deadline = started+100+302400;
    check(timers[phase] == deadline, "P2/3 still uses 3 day 12 hour timer");
    f.now = f.now + 1000;
    f.env.SetBossKilled(phase, 2);
    local _, again = f:save();
    check(again[phase] == deadline, "P2/3 later kills do not extend timer");
    f.now = deadline;
    f.env.CheckPhaseStatus(phase);
    kills, timers = f:save();
    check(not kills[phase]:find("1") and timers[phase] == 0, "P2/3 expiration unchanged");
end
for phase = 4, 6 do
    f = fixture(started+100);
    check(f.env.SetBossKilled(phase,1), "God kill accepted");
    kills, timers = f:save();
    local slot = phase == 4 and 4 or (phase == 5 and 8 or 12);
    check(timers[slot] == ends, "God deadline unchanged");
    check(not f.env.SetBossKilled(phase,1), "Duplicate god kill remains rejected");
end

for _, trial in ipairs({"Air", "Earth", "Fire", "Water", "Undead"}) do
    for _, status in ipairs({0,1}) do
        local cleared = false;
        local env = setmetatable({eq = {set_timer=function() end, set_next_hp_event=function() end}}, {__index=_G});
        loadscript("potimeb/encounters/Phase1" .. trial .. ".lua", env);
        setlocal(env.BossSpawn, "bossStatus", status);
        env.BossSpawn({self={ClearItemList=function() cleared=true end}});
        check(cleared == (status == 1), trial .. " only shadow boss has loot cleared");
    end
end
print("PASS: " .. checks .. " Phase 1 cycle loot checks");
