function event_click_door(e)
	local door_id = e.door:GetDoorID();

	if ( door_id == 17 ) then -- Sseru Arx Key Click Up
		if ( not e.self:KeyRingCheck(3650) and e.self:HasItem(3650) ) then
			e.self:KeyRingAdd(3650);
		end
		if( e.self:KeyRingCheck(3650) ) then
			MoveGroup(e.self:GetGroup(),e.self, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 200, -234, -290, 59, 0);
		end
	end
end

function MoveGroup(ac_group, player, src_x, src_y, src_z, distance, tgt_x, tgt_y, tgt_z, tgt_h)
	if ( ac_group.valid ) then
		local ac_count = ac_group:GroupCount();

		for i = 0, ac_count - 1, 1 do
			local client_v = ac_group:GetMember(i):CastToClient();
		
			if (client_v.valid) then
				-- check the distance and port them up if close enough
				if (client_v:CalculateDistance(src_x, src_y, src_z) <= distance) then
					-- port the player up
					client_v:MovePC(159, tgt_x, tgt_y, tgt_z, tgt_h); -- Zone: Sseru
				end
			end
		end
	else
		player:MovePC(159, tgt_x, tgt_y, tgt_z, tgt_h); -- Zone: Sseru
	end
end
