-- HoH A trial scripts reset their rooms after 18 hours, but depop_with_timer
-- leaves the three native starters on their configured 72-hour respawns.
-- Existing saved cooldowns are intentionally unchanged and expire normally.
-- Fresh zone loads pick up the new definitions; quest reload alone does not.
-- Back up affected rows first: content tables may be MyISAM.
-- Respawn seconds; NPC override milliseconds.
CREATE TEMPORARY TABLE hoh_trial_starter_sync (
    spawn_id INT NOT NULL PRIMARY KEY,
    npc_id INT NOT NULL UNIQUE
);
INSERT INTO hoh_trial_starter_sync (spawn_id, npc_id) VALUES
    (360859, 211051), -- Trydan Faye / Rydda Dar
    (360971, 211050), -- Rhaliq Trell / Villagers
    (361021, 211060); -- Alekson Garn / Crazed Norrathians

START TRANSACTION;

-- Future respawns only: leave every existing saved countdown untouched.
UPDATE spawn2 AS s
JOIN hoh_trial_starter_sync AS t ON t.spawn_id = s.id
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
SET s.respawntime = 64800
WHERE s.zone = 'hohonora';

-- The current starters have no NPC override. Preserve zero and unrelated
-- overrides, but align a legacy explicit 72-hour override if one exists.
UPDATE npc_types AS n
JOIN hoh_trial_starter_sync AS t ON t.npc_id = n.id
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = 'hohonora'
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = n.id
SET n.instance_spawn_timer_override = 64800000
WHERE n.instance_spawn_timer_override = 259200000;

COMMIT;

SELECT s.id AS spawn_id, n.id AS npc_id, n.name,
       s.respawntime / 3600 AS base_respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS instance_override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM hoh_trial_starter_sync AS t
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = 'hohonora'
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
JOIN npc_types AS n ON n.id = t.npc_id
ORDER BY s.id;

DROP TEMPORARY TABLE hoh_trial_starter_sync;
