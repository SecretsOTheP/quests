function event_combat(e)
	if ( e.joined ) then
		eq.set_timer("drophate", 1000);
	else
		eq.stop_timer("drophate");
		
		-- this is to mimic certain behavior Sony's servers had/has.  NPCs aggroed a long time sometimes warp home or
		-- some distance away in the direction of home and heal somewhat when they hate list wipe.  The exact logic to this
		-- behavior is unknown.  Bosses with the tank hate list drop mechanic need this in order to not trivialize the
		-- encounter using mem blur.  This is a crude solution that works well enough
		local ratio = e.self:GetHPRatio();
		if ( ratio < 50 or math.random(100) > ratio ) then
			e.self:GMMove(e.self:GetGuardPointX(), e.self:GetGuardPointY(), e.self:GetGuardPointZ(), e.self:GetSpawnPointH());
			e.self:SetHP(e.self:GetHP() + math.floor(e.self:GetMaxHP() * 0.3));
		end
	end
end

function event_timer(e)

	if ( e.timer == "drophate") then
	
		if ( math.random() < 0.01666 ) then -- averages to once per minute
			local target = e.self:GetTarget();
			if ( target and target.valid ) then
				local hate = e.self:GetHateAmount(target);

				if ( hate > 0 ) then
					e.self:SetHate(target, math.max(1, math.floor(hate * 0.05)));
					eq.debug(e.self:GetName().." reduced hate on "..target:GetName().." to 5%", 2);
				end
			end
		end
	end
end
