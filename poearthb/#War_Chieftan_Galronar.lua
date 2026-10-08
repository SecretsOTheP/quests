local Cycle = require("gintolaken_cycle");

function event_spawn(e)
	eq.set_timer("check", 1000);
end

function event_timer(e)
	eq.stop_timer(e.timer);
	if ( eq.get_entity_list():IsMobSpawnedByNpcTypeID(222010) ) then -- A_Rock_Studded_Champion
		eq.depop_with_timer();
		return;
	end
end

function event_death_complete(e)
	Cycle.ChieftainKilled(222036);
	eq.signal(222034, 1);
end
