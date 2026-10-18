local Cycle = require("potime_cycle");
local POTIMEA_CONTROLLER_TYPE = 219053;
local POTIMEB_CONTROLLER_TYPE = 223077;
local DIALS = { 2, 4, 1, 5, 3 };

local blocks = {};

-- Missing records have expired naturally; partial or malformed records must
-- not release a character from another guild's still-unknown loot lockouts.
local function ForeignTimeLockouts(timerData, killData, now)
	if ( not timerData and not killData ) then return false, true end
	if ( not timerData or not killData or not timerData:match("^%d[%;%d]*%d$")
		or timerData:find(";;", 1, true) ) then return false, false end
	local count, active = 0, false;
	for value in timerData:gmatch("[^;]+") do
		local deadline = tonumber(value);
		if ( not deadline or deadline == math.huge ) then return false, false end
		count = count + 1;
		if ( deadline * 100 >= now ) then active = true end
	end
	return active, count == 12;
end

-- A new allocation gets a distinct identity even when its numeric ID is reused.
-- Existing saves without this marker remain legacy timelines.
local function ValidTimeGeneration(value, instanceID)
	local epoch = type(value) == "string" and value:match("^"..instanceID..":(%d+)$");
	return epoch and tonumber(epoch) > 0 and tonumber(epoch) < math.huge;
end

function event_click_door(e)
	local door_id = e.door:GetDoorID();

	if ( door_id == 13 ) then
		-- Handle the graveyard tombstone in Lua before the native door handler
		-- can send the player to the public copy of Time B. Open type 57 skips
		-- that default teleport; only change it once per door load.
		if ( e.door:GetOpenType() ~= 57 ) then
			e.door:SetOpenType(57);
		end
		if ( e.self:GetHP() > 0 ) then
			-- Follow the source instance, including visitors and public Time A.
			e.self:MovePCGuildID(223, eq.get_zone_guild_id(), 865, -150, 395, 0);
		end
		return;
	end
	
	if ( door_id >= 8 and door_id <= 12 ) then

		-- prevent spam clicks from sending multiple signals
		local now = os.time();
		local charID = e.self:CharacterID();
		if ( blocks[charID] and blocks[charID] > now ) then
			return;
		end

		if ( eq.get_zone_guild_id() == 1 and not eq.guild_one_raid_window_open() ) then
			e.self:Message(13, "The flow of time is too stable for this portal to open.");
			return;
		end

		local raid = e.self:GetRaid();
		
		if ( not e.self:GetGM() and e.self:GetLevel() < 65 ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
			return;
		end
		if ( not e.self:GetGM() and (not raid.valid or raid:RaidCount() < 7) ) then
			e.self:Message(13, "You don't have sufficient power to affect things in the Plane of Time. Gather your forces to increase your strength.");
			return;
		end

		local qglobals = eq.get_qglobals(e.self);
		local instanceID = 0;
		if ( qglobals.time_instance ) then
			instanceID = tonumber(qglobals.time_instance) or 0;
		end
		local currentGuildID = eq.get_zone_guild_id();
		local timelineGlobals = eq.get_qglobals(POTIMEB_CONTROLLER_TYPE, 223);
		if ( instanceID > 0 ) then
			local generation = timelineGlobals["time_generation_"..instanceID];
			local savedGeneration = qglobals.time_instance_generation;
			if ( (generation ~= nil and not ValidTimeGeneration(generation, instanceID))
				or (savedGeneration ~= nil and savedGeneration ~= "0" and not ValidTimeGeneration(savedGeneration, instanceID))
				or (generation == nil and savedGeneration ~= nil and savedGeneration ~= "0"
					and (timelineGlobals["time_kills_"..instanceID] or timelineGlobals["time_timers_"..instanceID])) ) then
				e.self:Message(13, "Your saved thread of time could not be read safely. Please contact support.");
				return;
			end
			if ( generation ~= nil and savedGeneration ~= generation ) then
				-- The old records expired and this ID now belongs to a new run.
				-- Pre-marker character bindings are also stale for new allocations.
				instanceID = 0;
			end
		end
		if ( instanceID > 0 ) then
			local cycle, valid = Cycle.decode(timelineGlobals["time_cycle_"..instanceID]);
			if ( not valid ) then
				e.self:Message(13, "Your saved thread of time could not be read safely. Please contact support.");
				return;
			end
			if ( Cycle.expired(cycle, now) ) then instanceID = 0 end
		end
		local savedGuildID = tonumber(timelineGlobals["time_guild_"..instanceID])
			or tonumber(qglobals.time_instance_guild);
		if ( instanceID > 0 and savedGuildID ~= nil and savedGuildID ~= currentGuildID ) then
			-- A saved pointer may outlive its loot locks. Only the actual boss
			-- deadlines bind a character to the other guild's timeline.
			local killData = timelineGlobals["time_kills_"..instanceID];
			local timerData = timelineGlobals["time_timers_"..instanceID];
			local active, valid = ForeignTimeLockouts(timerData, killData, now);
			if ( not valid ) then
				e.self:Message(13, "Your saved thread of time could not be read safely. Please contact support.");
				return;
			end
			if ( active ) then
				e.self:Message(13, "The portal recoils from your touch. Your fate is bound to another guild's thread of time.");
				return;
			end
			-- Do not offer an expired foreign save to Time B for restoration.
			instanceID = 0;
		end

		
		door_id = door_id - 7;
		
		eq.signal(POTIMEA_CONTROLLER_TYPE, 3, 0, charID..";"..DIALS[door_id]..";"..raid:GetID()..";"..instanceID);
		
		blocks[charID] = now + 2;
	end
end
