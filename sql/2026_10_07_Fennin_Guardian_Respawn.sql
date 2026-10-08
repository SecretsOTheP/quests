-- Match the Guardian's normal fallback to Fennin's 138-hour successful reuse.
-- The encounter script still explicitly sets an 18-hour retry after failure.
-- Future timers only: do not rewrite saved respawn_times or character lockouts.
-- Fresh Fire zones pick up these definitions. Back up content rows first;
-- content tables may be MyISAM.
UPDATE npc_types
SET instance_spawn_timer_override = 496800000
WHERE id = 217050;

UPDATE spawn2 AS s
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = 217050
SET s.respawntime = 496800
WHERE s.id = 367088 AND s.zone = 'pofire';

SELECT n.id, n.name, n.loot_lockout,
       n.instance_spawn_timer_override / 3600000 AS override_hours,
       s.respawntime / 3600 AS base_respawn_hours
FROM npc_types AS n
JOIN spawnentry AS se ON se.npcID = n.id
JOIN spawn2 AS s ON s.spawngroupID = se.spawngroupID
WHERE n.id = 217050 AND s.id = 367088 AND s.zone = 'pofire';
