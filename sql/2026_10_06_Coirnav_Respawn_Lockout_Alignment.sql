-- Deploy with the matching Coirnav recovery script. Load a fresh Water zone
-- afterward to refresh cached NPC overrides and respawn countdowns.
-- Coirnav successful reuse is 138h; the Guardian is an event starter with no loot lockout.
UPDATE npc_types
SET instance_spawn_timer_override = 496800000
WHERE id IN (216048, 216053);

UPDATE npc_types SET loot_lockout = 496800 WHERE id = 216048;
UPDATE npc_types SET loot_lockout = 0 WHERE id = 216053;

UPDATE spawn2 SET respawntime = 496800
WHERE zone = 'powater' AND id IN (365647, 366321);

-- Extend only known normal 66h countdowns, keeping elapsed time. Preserve
-- ten-minute scripted retries and Guild 1 earthquake-owned sentinels.
UPDATE respawn_times AS rt
JOIN spawn2 AS s ON s.id = rt.id
SET rt.duration = 496800
WHERE s.zone = 'powater' AND s.id IN (365647, 366321)
  AND rt.duration = 237600
  AND NOT (rt.guild_id = 1 AND s.raid_target_spawnpoint = 1);

SELECT s.id AS spawn_id, n.id AS npc_id, n.name,
       s.respawntime / 3600 AS base_respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS instance_override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM spawn2 AS s
JOIN spawnentry AS e ON e.spawngroupID = s.spawngroupID
JOIN npc_types AS n ON n.id = e.npcID
WHERE s.zone = 'powater' AND s.id IN (365647, 366321);
