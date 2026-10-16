-- Run with Lua 5.1: lua tests/baraguj_entry_respawn_test.lua <quest-root>
local root = arg[1] or ".";
local checks = 0;
local function check(value, message)
    assert(value, message);
    checks = checks + 1;
end

local function fixture()
    local state = {entry = false, reward = false, reward_corpse = false,
        depops = {}, timers = {}};
    local eqmock = {};
    function eqmock.get_entity_list()
        return {IsMobSpawnedByNpcTypeID = function(_, id)
            assert(id == 207319, "Only inspect the reward NPC type");
            return state.reward;
        end};
    end
    function eqmock.depop_with_timer(id)
        assert(id == nil or id == 207028, "Never depop the reward form");
        state.entry = false;
        table.insert(state.depops, id or "self");
    end
    function eqmock.set_timer(name, duration) state.timers[name] = duration; end
    function eqmock.depop() state.reward = false; end
    local function script(path)
        local env = setmetatable({eq = eqmock}, {__index = _G});
        local chunk = assert(loadfile(root .. "/" .. path));
        setfenv(chunk, env); chunk();
        return env;
    end
    state.entry_script = script("potorment/Baraguj_Szuul.lua");
    state.reward_script = script("potorment/#Baraguj_Szuul.lua");
    function state:spawn_entry(npc_id)
        self.entry = true;
        self.entry_script.event_spawn({self = {
            GetNPCTypeID = function() return npc_id or 207028; end
        }});
    end
    function state:spawn_reward()
        self.reward = true;
        self.reward_script.event_spawn({});
    end
    return state;
end

local normal = fixture();
normal:spawn_entry();
check(normal.entry and #normal.depops == 0, "Normal entry spawn remains available");
normal:spawn_reward();
check(not normal.entry and normal.reward, "Reward spawn removes an existing entry form");
check(normal.depops[1] == 207028, "Reward spawn restarts only the entry NPC's native timer");
check(normal.timers.depop == 43200000, "Keep the reward's original 12-hour lifetime");
normal:spawn_entry();
check(not normal.entry and normal.reward, "Entry expiry cannot overlap the living reward");
check(normal.depops[2] == "self", "Blocked entry uses its native timer, not a scripted override");
normal:spawn_entry();
check(not normal.entry and normal.reward, "Repeated entry expiry leaves the reward intact");
normal.reward = false; normal.reward_corpse = true;
normal:spawn_entry();
check(normal.entry and normal.reward_corpse, "After reward death, allow entry and retain its corpse");

local expired = fixture();
expired:spawn_reward();
expired.reward_script.event_timer({timer = "depop"});
expired:spawn_entry();
check(expired.entry and not expired.reward, "Reward timeout releases the entry gate");

local unrelated = fixture();
unrelated.reward = true;
unrelated:spawn_entry(207319);
check(#unrelated.depops == 0, "Entry script cannot suppress another NPC type");

local first, second = fixture(), fixture();
first:spawn_reward(); first:spawn_entry(); second:spawn_entry();
check(not first.entry and second.entry, "Reward presence is local to its zone instance");
print(checks .. " Baraguj entry lifecycle checks passed");
