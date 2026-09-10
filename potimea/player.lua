local POTIMEA_CONTROLLER_TYPE = 219053;
local POTIMEB_CONTROLLER_TYPE = 223077;
local DIALS = { 2, 4, 1, 5, 3 };

local blocks = {};

function event_click_door(e)
	local door_id = e.door:GetDoorID();
	
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
			e.self:Message(15, "DEBUG raid valid: "..tostring(raid.valid)..", members: "..tostring(raid.valid and raid:RaidCount() or 0));
		
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
		local savedGuildID = tonumber(qglobals.time_instance_guild) or 0;
		local currentGuildID = eq.get_zone_guild_id();
		if ( instanceID > 0 and savedGuildID > 0 and savedGuildID ~= currentGuildID ) then
			e.self:Message(13, "The portal recoils from your touch. Your fate is bound to another guild's thread of time.");
			return;
		end

		
		door_id = door_id - 7;
		
		eq.signal(POTIMEA_CONTROLLER_TYPE, 3, 0, charID..";"..DIALS[door_id]..";"..raid:GetID()..";"..instanceID);
		
		blocks[charID] = now + 2;
	end
end
