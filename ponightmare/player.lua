local RaidWilling = require("pop_raid_willing");

function event_click_door(e)
	local qglobals = eq.get_qglobals(e.self);
	local door_id = e.door:GetDoorID();

	if ( door_id == 59 ) then
		if ( qglobals.thelin and (tonumber(qglobals.thelin) or 0) > 1 ) then
			if ( e.self:HasZoneFlag(221) == false ) then
				e.self:SetZoneFlag(221);
			end
		elseif ( not RaidWilling.CanEnter(e.self, 221) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end
end
