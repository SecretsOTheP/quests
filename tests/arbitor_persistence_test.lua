-- Lua 5.1: lua tests/arbitor_persistence_test.lua /path/to/Quests
-- Runs the actual controller with simulated NPCs and persistent buckets.
local root = arg[1] or ".";
local file = assert(io.open(root.."/poeartha/arbitor_guy.lua"));
local source = file:read("*a"); file:close();
local checks = 0;
local function check(condition, message)
	assert(condition, message);
	checks = checks + 1;
end
local function key(guild) return "poeartha-arbitor-rings-v1-"..guild; end
local function world()
	local w = {now = 1000000, buckets = {}, npcs = {}, attempts = 0, spawns = 0,
		depops = 0, reads = 0, writes = 0, deletes = 0, logs = {}};
	function w:load(guild, skipSpawn)
		local timers = {};
		local env = {os = {time = function() return w.now; end}};
		env.eq = {
			get_zone_guild_id = function() return guild; end,
			get_data = function(k)
				w.reads = w.reads + 1;
				local bucket = w.buckets[k];
				return bucket and bucket.expires > w.now and bucket.value or "";
			end,
			set_data = function(k, value, ttl)
				w.writes = w.writes + 1;
				w.buckets[k] = {value = value, expires = w.now + tonumber(ttl)};
			end,
			delete_data = function(k) w.deletes = w.deletes + 1; w.buckets[k] = nil; end,
			set_timer = function(name, ms) timers[name] = ms; end,
			stop_timer = function(name) timers[name] = nil; end,
			debug = function(message) w.logs[#w.logs + 1] = message; end,
			depop_with_timer = function() w.depops = w.depops + 1; end,
			unique_spawn = function(id, grid, unused, x, y, z, heading)
				check(id == 218375 and grid == 0 and unused == 0 and x == 1530 and y == -2739 and z == 28 and heading == 192,
					"original Arbitor and spawn location preserved");
				w.attempts = w.attempts + 1;
				if w.failure == "nil" then return nil; end
				if w.failure == "invalid" then return {valid = false}; end
				local npc = w.npcs[guild];
				if npc then return npc; end
				npc = {valid = true, id = w.spawns + 100, hp = 1000, born = w.now};
				function npc:GetID() return self.id; end
				function npc:GetHP() return self.hp; end
				function npc:IsCorpse() return self.corpse or false; end
				w.npcs[guild] = npc;
				w.spawns = w.spawns + 1;
				return npc;
			end
		};
		setmetatable(env, {__index = _G});
		setfenv(assert(loadstring(source, "arbitor_guy.lua")), env)();
		local controller = {};
		function controller:signal(id) env.event_signal({signal = id}); end
		function controller:respawn() env.event_spawn({}); end
		function controller:retry()
			check(timers.arbitor_spawn_retry == 30000, "retry is armed for 30 seconds");
			env.event_timer({timer = "arbitor_spawn_retry"});
		end
		function controller:timer(name) env.event_timer({timer = name}); end
		function controller:hasRetry() return timers.arbitor_spawn_retry ~= nil; end
		if not skipSpawn then env.event_spawn({}); end
		return controller;
	end
	return w;
end
local function finish(controller, rings)
	for _, ring in ipairs(rings or {1, 2, 3, 4}) do controller:signal(ring); end
end

-- Every ordering works, including Dust before the last ring, with an unload
-- after every completion. New Lua contexts share only persistent buckets.
for a = 1, 4 do for b = 1, 4 do for c = 1, 4 do for d = 1, 4 do
	if a ~= b and a ~= c and a ~= d and b ~= c and b ~= d and c ~= d then
		local w = world();
		for _, ring in ipairs({a, b, c, d}) do
			w:load(72):signal(ring);
			w.now = w.now + 60;
		end
		check(w.spawns == 1 and w.depops == 1, "all ring orders survive unloads");
		check(w.buckets[key(72)] == nil, "successful spawn consumes saved progress");
		w:load(72);
		check(w.attempts == 1, "fresh controller cannot reuse consumed progress");
	end
end end end end

do
	local w = world();
	w:load(72):signal(1);
	w.now = w.now + 22 * 3600;
	finish(w:load(72), {2, 3, 4});
	check(w.spawns == 1, "overnight 22-hour visit gap still qualifies");
end

do
	local w = world();
	w:load(72):signal(1);
	finish(w:load(73), {2, 3, 4});
	check(w.spawns == 0, "guilds cannot combine ring credit");
	finish(w:load(72), {2, 3, 4});
	check(w.spawns == 1 and w.buckets[key(73)] ~= nil, "one guild's success preserves another's credit");
	w:load(73):signal(1);
	check(w.spawns == 2, "each guild can complete independently");
end

do
	local w = world();
	w:load(72):signal(1);
	w.now = w.now + 86400;
	finish(w:load(72), {2, 3, 4});
	check(w.spawns == 1, "exact 24-hour boundary retains original eligibility");
end

do
	local w = world();
	w:load(72):signal(1);
	w.now = w.now + 86401;
	finish(w:load(72), {2, 3, 4});
	check(w.spawns == 0, "expired bucket cannot supply old credit");
	w:load(72):signal(1);
	check(w.spawns == 1, "fresh completion replaces expired credit");
end

do
	local w = world();
	w:load(72):signal(1);
	w.now = w.now + 23 * 3600;
	w:load(72):signal(2);
	check(w.buckets[key(72)].value == "1000000|1082800|0|0", "later kill preserves earlier timestamp");
	w.now = w.now + 3601;
	finish(w:load(72), {3, 4});
	check(w.spawns == 0, "refreshing bucket expiry does not extend earlier ring credit");
end

for _, invalid in ipairs({"garbage", "1|2|3", "1|2|3|4|5", "-1|0|0|0", "nan|0|0|0"}) do
	local w = world();
	w.buckets[key(72)] = {value = invalid, expires = w.now + 86401};
	finish(w:load(72), {2, 3, 4});
	check(w.spawns == 0, "malformed saved progress cannot unlock Arbitor");
end

for _, timestamp in ipairs({1000001, 913599}) do
	local w = world();
	w.buckets[key(72)] = {value = timestamp.."|1000000|1000000|1000000", expires = w.now + 86401};
	w:load(72);
	check(w.spawns == 0, "future or expired saved timestamp cannot unlock Arbitor");
end

do
	local w = world(); local controller = w:load(72, true);
	for _, signal in ipairs({0, 5, -1, 1.5, "1"}) do controller:signal(signal); end
	check(w.reads == 0 and w.writes == 0 and w.spawns == 0, "invalid signals do not load or alter progress");
	controller:signal(1);
	check(w.reads == 1 and w.writes == 1, "first signal lazily loads after a quest reload");
	w.now = w.now + 30;
	finish(w:load(72, true), {2, 3, 4});
	check(w.spawns == 1, "quest reload without spawn event restores progress");
end

for _, failure in ipairs({"nil", "invalid"}) do
	local w = world(); w.failure = failure;
	local controller = w:load(72); finish(controller);
	check(w.depops == 0 and w.buckets[key(72)] ~= nil and controller:hasRetry(), "failed spawn retains all progress and controller");
	local logCount = #w.logs;
	w.now = w.now + 30; controller:retry();
	check(#w.logs == logCount, "repeated spawn failures do not flood logs");
	w.failure = nil; w.now = w.now + 30; controller:retry();
	check(w.spawns == 1 and w.depops == 1 and not controller:hasRetry(), "retry succeeds without another ring kill");
	finish(controller);
	check(w.spawns == 1 and w.depops == 1, "late duplicate signals cannot spawn or reset again");
end

do
	local w = world(); w.failure = "nil";
	finish(w:load(72));
	w.failure = nil; w.now = w.now + 60;
	w:load(72);
	check(w.spawns == 1 and w.depops == 1, "unload during failed spawn recovers from saved completions");
end

do
	local w = world(); w.failure = "nil";
	local controller = w:load(72); finish(controller);
	w.now = w.now + 86401; controller:retry();
	check(w.attempts == 1 and not controller:hasRetry() and w.depops == 0, "retry stops when original completion window expires");
end

do
	local w = world(); local controller = w:load(72);
	finish(controller);
	local born = w.npcs[72].born;
	w.buckets[key(72)] = {value = "1000000|1000000|1000000|1000000", expires = w.now + 86401};
	w.now = w.now + 60; w:load(72);
	check(w.spawns == 1 and w.npcs[72].born == born, "existing Arbitor is not duplicated or given a fresh lifetime");
end

for _, invalid in ipairs({"corpse", "dead", "zero_id"}) do
	local w = world(); finish(w:load(72));
	local npc = w.npcs[72];
	if invalid == "corpse" then npc.corpse = true; elseif invalid == "dead" then npc.hp = 0; else npc.id = 0; end
	w.buckets[key(72)] = {value = "1000000|1000000|1000000|1000000", expires = w.now + 86401};
	local controller = w:load(72);
	check(w.depops == 1 and w.buckets[key(72)] ~= nil and controller:hasRetry(), "nonliving NPC does not consume completions");
end

for _, guild in ipairs({1, 0, -1}) do
	local w = world(); w:load(guild):signal(1);
	local controller = w:load(guild); finish(controller, {2, 3, 4});
	check(w.spawns == 0 and w.reads == 0 and w.writes == 0, "Guild 1/open-world persistence is unchanged");
	controller:signal(1);
	check(w.spawns == 1 and w.deletes == 0, "original same-session behavior still works without persistence");
end

do
	local w = world(); local controller = w:load(72);
	finish(controller);
	w.now = w.now + 66 * 3600; w.npcs[72] = nil;
	controller:respawn();
	check(w.spawns == 1, "normal controller respawn cannot reuse old completions");
	finish(controller);
	check(w.spawns == 2 and w.depops == 2, "second event cycle works without unloading the Lua context");
end

do
	local w = world(); local controller = w:load(72);
	controller:signal(1); controller:signal(2);
	controller:respawn();
	finish(controller, {3, 4});
	check(w.spawns == 1, "fresh controller reloads durable partial credit");
end

do
	local w = world(); local controller = w:load(72);
	controller:signal(1);
	local reads, writes = w.reads, w.writes;
	for i = 1, 100 do controller:timer("unrelated"); end
	check(w.reads == reads and w.writes == writes and not controller:hasRetry(), "incomplete progress does not poll the database");
end

print("PASS: "..checks.." Arbitor persistence checks");
