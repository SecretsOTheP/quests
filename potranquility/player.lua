local RaidWilling = require("pop_raid_willing");
local ELEMENTAL_DESTINATIONS = { [81] = 215, [83] = 218, [84] = 216 };

-- Original alternate level access; higher planes still require progression or raid willing.
local level_for_tier_two = 55;
local level_for_tier_three = 62;

function event_click_door(e)
	local qglobals = eq.get_qglobals(e.self);
	local door_id = e.door:GetDoorID();
	local alternate_access_enabled = eq.get_data("pop_alt_access_enabled") == "1";

	-- valor / storms
	if(door_id == 16 or door_id == 21) then
		if((alternate_access_enabled and e.self:GetLevel() >= level_for_tier_two) or (qglobals.mavuin and qglobals.mavuin == "3")) then
			if(e.self:HasZoneFlag(210) == false or e.self:HasZoneFlag(208) == false) then
				e.self:SetZoneFlag(210);
				e.self:SetZoneFlag(208);
			end
		elseif ( not RaidWilling.CanEnter(e.self, door_id == 16 and 210 or 208) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end
  
	-- codecay
	if(door_id == 12) then
	
		if ( not e.self:HasZoneFlag(200) ) then
		
			if (alternate_access_enabled and e.self:GetItemIDAt(0) == 9294 and not e.self:KeyRingCheck(9294)) then
				e.self:KeyRingAdd(9294);
			end
			
			-- zone flag is set by dropping down the Plane of Disease zone-in 'toilet' near Grummus
			if (alternate_access_enabled and (e.self:GetLevel() >= level_for_tier_two or e.self:KeyRingCheck(9294))) then
				e.self:SetZoneFlag(200);
			elseif ( not RaidWilling.CanEnter(e.self, 200) ) then
				e.self:Message(13, "You lack the will to pass through this portal safely.");
			end
		end
	end
  
	-- torment
	if(door_id == 93) then
		if (alternate_access_enabled and e.self:GetItemIDAt(0) == 29213 and not e.self:KeyRingCheck(29213)) then
			e.self:KeyRingAdd(29213);
		end
		if((qglobals.fuirstel and qglobals.fuirstel == "5" and qglobals.thelin and qglobals.thelin == "4") or (alternate_access_enabled and (e.self:GetLevel() >= level_for_tier_two or e.self:KeyRingCheck(29213)))) then
			if(e.self:HasZoneFlag(207) == false) then
				e.self:SetZoneFlag(207);
			end
		elseif ( not RaidWilling.CanEnter(e.self, 207) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end
  
	-- bothunder
	if(door_id == 48) then
		local karana = tonumber(qglobals.karana or 0);
		if((alternate_access_enabled and e.self:GetLevel() >= level_for_tier_three) or karana >= 3 or qglobals.zebuxoruk) then
			if(e.self:HasZoneFlag(209) == false) then
				e.self:SetZoneFlag(209);
			end
		elseif ( not RaidWilling.CanEnter(e.self, 209) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end

	-- hohonora
	if(door_id == 23) then

		if ( not e.self:HasZoneFlag(211) ) then
		
			if (alternate_access_enabled and e.self:GetItemIDAt(0) == 29214 and not e.self:KeyRingCheck(29214)) then
				e.self:KeyRingAdd(29214);
			end
		
			-- zone flag is set by zoning in from PoValor
			if (alternate_access_enabled and (e.self:GetLevel() >= level_for_tier_three or e.self:KeyRingCheck(29214))) then
				e.self:SetZoneFlag(211);
			elseif ( not RaidWilling.CanEnter(e.self, 211) ) then
				e.self:Message(13, "You lack the will to pass through this portal safely.");
			end		
		end
	end

	-- potactics
	if(door_id == 24) then
		local zeks = tonumber(qglobals.zeks or 0);
		if (alternate_access_enabled and e.self:GetItemIDAt(0) == 29215 and not e.self:KeyRingCheck(29215)) then
			e.self:KeyRingAdd(29215);
		end
		if(zeks >= 2 or (alternate_access_enabled and (e.self:GetLevel() >= 60 or e.self:KeyRingCheck(29215)))) then
			if(e.self:HasZoneFlag(214) == false) then
				e.self:SetZoneFlag(214);
			end
		elseif ( not RaidWilling.CanEnter(e.self, 214) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end  
  
	-- solrotower
	if(door_id == 22) then
		local zeks = tonumber(qglobals.zeks or 0);
		if(qglobals.cipher and zeks >= 6) then
			if(e.self:HasZoneFlag(212) == false) then
				e.self:SetZoneFlag(212);
			end
		elseif ( not RaidWilling.CanEnter(e.self, 212) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end
  
	-- pofire
	if(door_id == 82) then

		if ( not e.self:HasZoneFlag(217) and not RaidWilling.CanEnter(e.self, 217) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end

	-- powater / poearth / poair
	if(door_id == 81 or door_id == 83 or door_id == 84) then
		if(qglobals.zebuxoruk and qglobals.zebuxoruk == "2") then
			if(e.self:HasZoneFlag(216) == false or e.self:HasZoneFlag(215) == false or e.self:HasZoneFlag(218) == false) then
				e.self:SetZoneFlag(216);
				e.self:SetZoneFlag(215);
				e.self:SetZoneFlag(218);
			end
		elseif ( not RaidWilling.CanEnter(e.self, ELEMENTAL_DESTINATIONS[door_id]) ) then
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end

	-- potimea
	if(door_id == 18) then
		
		if ( e.self:GetGM() or ( e.self:GetLevel() >= 65 and ((e.self:HasZoneFlag(219) and qglobals.time) or RaidWilling.CanEnter(e.self, 219)) ) ) then
			e.self:Message(0, "The ages begin to tear through your body.  You wake to find yourself in another time.");
			-- e.self:MovePC(219, 223, 140, 9, 170*2);
		else
			e.self:Message(13, "You lack the will to pass through this portal safely.");
		end
	end
end
