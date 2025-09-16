function event_click_door(e)
	local door_id = e.door:GetDoorID();

	if ( door_id == 17 ) then -- Inner AC Statue click up
		if ( not e.self:KeyRingCheck(5972) and e.self:HasItem(5972) ) then
			e.self:KeyRingAdd(5972);
		end
		if( e.self:KeyRingCheck(5972) ) then
			MoveGroup(e.self:GetGroup(),e.self, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 125, 225, -275, 10, 128);
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
					client_v:MovePC(154, tgt_x, tgt_y, tgt_z, tgt_h); -- Zone: Acrylia Caverns
				end
			end
		end
	else
		player:MovePC(154, tgt_x, tgt_y, tgt_z, tgt_h); -- Zone: Acrylia Caverns
	end
end
