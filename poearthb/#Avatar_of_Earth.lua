local PLANAR_PROJECTION_TYPE = 222041; -- Essence_of_Earth
local COUNCIL_SPAWN_IDS = { 369377, 369380, 369382, 369384, 369386, 369387, 369376, 369378, 369379, 369381, 369383, 369385 };

function SetCouncilRespawn(seconds)
	for _, id in ipairs(COUNCIL_SPAWN_IDS) do
		eq.update_spawn_timer(id, seconds * 1000);
	end
end

function event_death_complete(e)
	eq.spawn2(PLANAR_PROJECTION_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);
	eq.signal(PLANAR_PROJECTION_TYPE, e.killer:GetID()); -- e.killer for death_complete is somebody with kill rights, not death blow
	SetCouncilRespawn(237600); -- restart the Council 2 days, 18 hours after Avatar dies
end

function event_spawn(e)
	eq.set_timer("depop", 9000000); -- 2.5 hours; paused while Avatar is engaged
end

function event_combat(e)
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function event_timer(e)
	if ( e.timer == "depop" ) then
		eq.debug("Avatar of Earth depop");
		SetCouncilRespawn(420); -- failed Avatar attempt: restore the Council after 7 minutes
		eq.depop();
	end
end
