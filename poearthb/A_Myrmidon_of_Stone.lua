local Cycle = require("gintolaken_cycle");
local INVIS_MAN_ID = 369489;
local AWISANO_TYPE = 222037;
local AWISANO_SPAWNID = 369492;
local SPAWNIDS = { 369438, 369439, 369440, 369441 };

-- force them to respawn at same time
function event_spawn(e)
	for _, id in ipairs(SPAWNIDS) do
		eq.update_spawn_timer(id, 1000);
	end
	eq.depop_with_timer(AWISANO_TYPE);
	eq.update_spawn_timer(INVIS_MAN_ID, 1000);
end

function event_death_complete(e)

	if ( not eq.get_entity_list():IsMobSpawnedByNpcTypeID(222008) ) then -- A_Myrmidon_of_Stone

		eq.update_spawn_timer(AWISANO_SPAWNID, 1000);
		
		Cycle.GroupCleared(AWISANO_TYPE);
	end
end
