-- Vallon Zek fake 2

function event_spawn(e)
	e.self:SetEntityVariable("rallos_copy", (e.self:GetX()>0 and e.self:GetZ()>150) and "1" or "0");
	eq.set_timer("depop", 120000);
end

function event_combat(e)
	if ( e.joined ) then
		eq.set_timer("bounds", 6000);
		eq.pause_timer("depop");
	else
		eq.stop_timer("bounds");
		eq.resume_timer("depop");
	end
end

function event_timer(e)

	if ( e.timer == "depop" ) then
		eq.depop();
		
	elseif ( e.timer == "bounds" ) then
		if ( e.self:GetEntityVariable("rallos_copy")~="1" and e.self:GetY() < 1750 and e.self:GetX() < 0 ) then
			e.self:GMMove(-625, 1980, 204.5, 64);
		end
	end
end
