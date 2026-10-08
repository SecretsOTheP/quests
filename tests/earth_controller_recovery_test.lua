-- Lua 5.1: lua tests/earth_controller_recovery_test.lua /path/to/Quests
local root = arg[1] or ".";
local checks = 0;
local function check(ok, message) assert(ok, message); checks = checks + 1; end
local function loadScript(path, env)
	setmetatable(env, {__index = _G});
	setfenv(assert(loadfile(root.."/"..path)), env)();
end

-- Depop's native timer may differ from the scripted Council-access window.
-- SetTimer alone must not leave that different value saved after an unload.
for _, guild in ipairs({72, 73, 1, -1}) do
	local now = 1000000;
	local liveDeadline, savedDeadline, writes, depops = 0, 0, 0, 0;
	local marker = {valid = true};
	function marker:Depop(repop)
		check(repop == true, "marker starts its normal respawn on depop");
		depops = depops + 1;
		liveDeadline = now + 336 * 3600;
		savedDeadline = liveDeadline;
	end
	local point = {valid = true};
	function point:GetNPC() return marker; end
	function point:SetTimer(ms) liveDeadline = now + ms / 1000; end
	local elist = {};
	function elist:GetSpawnByID(id)
		check(id == 369490, "only Council-access marker is changed");
		return point;
	end
	local env = {eq = {
		get_zone_guild_id = function() return guild; end,
		get_entity_list = function() return elist; end,
		update_spawn_timer = function(id, ms)
			check(id == 369490 and ms == 302400000, "saved window stays exactly 84 hours");
			savedDeadline = now + ms / 1000; writes = writes + 1;
		end
	}};
	loadScript("poearthb/#Warlord_Gintolaken.lua", env);
	env.event_death_complete({});
	check(depops == 1 and liveDeadline == now + 84 * 3600, "loaded-zone Council access is unchanged");
	if guild > 1 then
		check(writes == 1 and savedDeadline == liveDeadline, "guild instance saves the same deadline");
		now = now + 12 * 3600;
		liveDeadline = savedDeadline; -- fresh zone loads the saved respawn row
		check(liveDeadline - now == 72 * 3600, "unload does not shorten or restart Council access");
	else
		check(writes == 0, "Guild 1/open world native timer behavior is unchanged");
	end
end

-- Encounter registrations must survive unloading StoneRing independently.
do
	local registry, timers, saved, enabled, removed = {}, {}, {}, {}, {};
	local depopped = false;
	local events = {spawn = 1, timer = 2, death_complete = 3, combat = 4, waypoint_arrive = 5, signal = 6, hp = 7};
	local elist = {};
	function elist:GetSpawnByID(id)
		return {Enable = function() enabled[id] = true; end};
	end
	local env = {Event = events, eq = {
		register_npc_event = function(owner, event, npc, callback)
			registry[#registry + 1] = {owner = owner, event = event, npc = npc, callback = callback};
		end,
		set_timer = function(name, ms) timers[name] = ms; end,
		get_entity_list = function() return elist; end,
		update_spawn_timer = function(id, ms) saved[id] = ms; end,
		depop_all = function(id) removed[id] = true; end,
		depop = function() depopped = true; end,
		debug = function() end
	}};
	loadScript("poeartha/encounters/MudRing.lua", env);
	env.event_encounter_load({});
	local spawn, timeout;
	for _, entry in ipairs(registry) do
		check(entry.owner == "MudRing", "all Mud Ring callbacks belong to their own encounter");
		if entry.owner ~= "StoneRing" and entry.npc == 218394 then
			if entry.event == events.spawn then spawn = entry.callback; end
			if entry.event == events.timer then timeout = entry.callback; end
		end
	end
	check(spawn ~= nil and timeout ~= nil, "Mud timeout survives Stone encounter unload");
	spawn({});
	check(timers.depop == 5880000, "original 98-minute Mud deadline preserved");
	timeout({timer = "depop"});
	local count = 0;
	for id, ms in pairs(saved) do
		check(ms == 900000 and enabled[id], "failure saves and enables the original 15-minute retry");
		count = count + 1;
	end
	check(count == 16 and depopped, "all 16 Mud triggers recover on timeout");
	check(removed[218360] and removed[218365] and removed[218419], "timeout cleans up bosses and runners");
end

print("PASS: "..checks.." Earth controller recovery checks");
