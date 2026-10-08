local BOSS_TYPES = { 222035, 222037, 222036, 222008, 222009, 222010 }; -- Chieftans, Chieftan spawners

function event_spawn(e)
	eq.set_timer("check", 1000);
end

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
	if ( e.timer == "drophate" ) then
	
		if ( e.self:GetX() < -137 ) then
			e.self:GMMove(e.self:GetSpawnPointX(), e.self:GetSpawnPointY(), e.self:GetSpawnPointZ(), e.self:GetSpawnPointH());
			e.self:WipeHateList();
			e.self:CastSpell(3230, e.self:GetID()); -- Balance of the Nameless
			return;
		end
		
		if ( math.random() < (1.0 / 45.0) ) then -- averages to once per 45 seconds
			local target = e.self:GetTarget();
			if ( target and target.valid ) then
				local hate = e.self:GetHateAmount(target);

				if ( hate > 0 ) then
					e.self:SetHate(target, math.max(1, math.floor(hate * 0.05)));
					eq.debug(e.self:GetName().." reduced hate on "..target:GetName().." to 5%", 2);
				end
			end
		end
	
	elseif ( e.timer == "check" ) then
		eq.stop_timer(e.timer);

		-- Ginto has a spawn2 so he'll be up if the zone goes down.  need to despawn him if triggers are up
		local elist = eq.get_entity_list();
		for _, id in ipairs(BOSS_TYPES) do
			if ( elist:IsMobSpawnedByNpcTypeID(id) ) then
				eq.depop_with_timer();
				return;
			end
		end
	end
end

function event_death_complete(e)
	eq.get_entity_list():GetSpawnByID(369490):GetNPC():Depop(true);
	eq.get_entity_list():GetSpawnByID(369490):SetTimer(302400000);
	-- SetTimer changes only the loaded spawnpoint. Save the same 84-hour
	-- Council-access window across unloads; retain Guild 1 quake handling.
	if eq.get_zone_guild_id() > 1 then
		eq.update_spawn_timer(369490, 302400000);
	end
end
