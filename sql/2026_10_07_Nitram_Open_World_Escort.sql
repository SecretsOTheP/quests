-- Nitram Anizok is the escort quest starter, not a scheduled raid spawn.
-- Removing this spawnpoint classification allows his existing escort to begin
-- in ordinary open-world Plane of Innovation when raid spawns are disabled.
-- Keep his configured respawn, the escort script, and Xanamech's NPC metadata.
-- Apply before a fresh zone load; quest reload alone does not reload spawn2 flags.
UPDATE spawn2 AS s
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID
SET s.raid_target_spawnpoint = 0,
    s.enabled = 1
WHERE s.id = 345275
  AND s.zone = 'poinnovation'
  AND s.spawngroupID = 206033
  AND se.npcID = 206033; -- Nitram_Anizok

SELECT s.id AS spawn_id, n.id AS npc_id, n.name, s.zone,
       s.enabled, s.raid_target_spawnpoint, s.respawntime
FROM spawn2 AS s
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID
JOIN npc_types AS n ON n.id = se.npcID
WHERE s.id = 345275 AND s.zone = 'poinnovation'
  AND s.spawngroupID = 206033 AND se.npcID = 206033;
