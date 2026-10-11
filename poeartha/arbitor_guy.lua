local WINDOW = 86400;
local RETRY_TIMER = "arbitor_spawn_retry";
local killTimes = {};
local loaded, completed, retryPending = false, false, false;
local stateKey;

local function LoadProgress()
	if loaded then return; end
	loaded = true;
	local guild = eq.get_zone_guild_id();
	-- Guild 1 retains its existing in-memory earthquake behavior.
	if guild <= 1 then return; end
	stateKey = "poeartha-arbitor-rings-v1-"..tostring(guild);
	local raw = eq.get_data(stateKey);
	if not raw or raw == "" then return; end
	local a, b, c, d = raw:match("^(%d+)|(%d+)|(%d+)|(%d+)$");
	if not a then
		eq.debug("Arbitor: ignored malformed saved ring progress for guild "..guild);
		return;
	end
	local now = os.time();
	for i, value in ipairs({a, b, c, d}) do
		local timestamp = tonumber(value);
		if timestamp and timestamp > 0 and timestamp <= now and timestamp >= now - WINDOW then
			killTimes[i] = timestamp;
		end
	end
end

local function SaveProgress(now)
	local values = {};
	for i = 1, 4 do
		local timestamp = killTimes[i];
		if timestamp and (timestamp < now - WINDOW or timestamp > now) then
			killTimes[i] = nil;
		end
		values[i] = tostring(killTimes[i] or 0);
	end
	if stateKey then
		-- Original timestamps enforce each ring's window even if a later kill
		-- refreshes the bucket's expiry. Include the exact 24-hour boundary.
		eq.set_data(stateKey, table.concat(values, "|"), tostring(WINDOW + 1));
	end
end

local function TrySpawn()
	if completed then return; end
	local now = os.time();
	for i = 1, 4 do
		local timestamp = killTimes[i];
		if not timestamp or timestamp < now - WINDOW or timestamp > now then
			if retryPending then
				eq.stop_timer(RETRY_TIMER);
				retryPending = false;
				eq.debug("Arbitor spawn retry stopped: ring "..i.." is outside the 24-hour window");
			end
			return;
		end
	end

	local mob = eq.unique_spawn(218375, 0, 0, 1530, -2739, 28, 192);
	if not mob or not mob.valid or mob:GetID() == 0 or mob:GetHP() <= 0 or mob:IsCorpse() then
		if not retryPending then
			eq.debug("Arbitor spawn failed; retaining ring progress and retrying in 30 seconds");
			eq.set_timer(RETRY_TIMER, 30000);
			retryPending = true;
		end
		return;
	end

	-- unique_spawn also returns an existing Arbitor; never replace it or
	-- restart its lifetime. Consume progress only after confirming a live NPC.
	completed = true;
	retryPending = false;
	eq.stop_timer(RETRY_TIMER);
	if stateKey then eq.delete_data(stateKey); end
	killTimes = {};
	eq.debug("Arbitor present; ring progress consumed for guild "..eq.get_zone_guild_id());
	eq.depop_with_timer();
end

function event_spawn(e)
	-- NPC-type Lua state can outlive an individual controller. Its normal
	-- respawn must permit a new cycle even if the zone never unloaded.
	killTimes = {};
	loaded, completed, retryPending = false, false, false;
	stateKey = nil;
	eq.stop_timer(RETRY_TIMER);
	LoadProgress();
	TrySpawn();
end

function event_signal(e)
	if completed or type(e.signal) ~= "number" or e.signal < 1 or e.signal > 4 or e.signal ~= math.floor(e.signal) then
		return;
	end
	LoadProgress();
	local now = os.time();
	killTimes[e.signal] = now;
	SaveProgress(now);
	eq.debug("Arbitor: ring "..e.signal.." completed for guild "..eq.get_zone_guild_id());
	TrySpawn();
end

function event_timer(e)
	if e.timer == RETRY_TIMER then
		LoadProgress();
		TrySpawn();
	end
end
