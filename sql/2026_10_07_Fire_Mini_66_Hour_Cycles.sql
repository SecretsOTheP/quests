-- Restore only the ten Plane of Fire raid minis to 66-hour spawn/loot cycles.
-- Compatible with either order of the revised 2026_10_06_Final_PoP_Respawn_Lockout_Sync.sql.
-- Back up affected rows and apply while affected zones are unloaded. Content
-- tables may be MyISAM; START TRANSACTION does not make those tables rollback-safe.
-- Respawn/loot values are seconds; NPC instance overrides are milliseconds.
CREATE TEMPORARY TABLE fire_mini_restore (
    npc_id INT NOT NULL PRIMARY KEY,
    spawn_id INT NOT NULL UNIQUE,
    spawn_group_id INT NOT NULL
);
INSERT INTO fire_mini_restore (npc_id, spawn_id, spawn_group_id) VALUES
    (217003, 367351, 217003),
    (217005, 367063, 217005),
    (217019, 366356, 217019),
    (217032, 366505, 217032),
    (217036, 367462, 217036),
    (217049, 367325, 217417),
    (217051, 366652, 217418),
    (217056, 366735, 217056),
    (217059, 366567, 217059),
    (217063, 367421, 217063);

-- Require the complete, expected mapping before making any changes.
SET @fire_mini_restore_ok = (
    SELECT COUNT(*) = 10
    FROM fire_mini_restore AS t
    JOIN npc_types AS n ON n.id = t.npc_id
    JOIN spawn2 AS s ON s.id = t.spawn_id
        AND s.zone = 'pofire' AND s.spawngroupID = t.spawn_group_id
    JOIN spawnentry AS se ON se.spawngroupID = t.spawn_group_id AND se.npcID = t.npc_id
);

START TRANSACTION;
-- Extend only still-active lockouts recorded under the 48-hour definition.
-- Preserve the inferred kill time; never revive expired claims. Changing the
-- NPC definition below prevents another extension if this migration is rerun.
UPDATE character_loot_lockouts AS cl
JOIN fire_mini_restore AS t ON t.npc_id = cl.npctype_id
JOIN npc_types AS n ON n.id = t.npc_id
SET cl.expiry = cl.expiry + 64800
WHERE @fire_mini_restore_ok = 1
  AND n.loot_lockout = 172800
  AND cl.expiry > UNIX_TIMESTAMP();

-- Retain elapsed time on known 48-hour / legacy 60-hour countdowns.
-- Preserve short retries, custom timers, and Guild 1 earthquake admission.
UPDATE respawn_times AS rt
JOIN fire_mini_restore AS t ON t.spawn_id = rt.id
SET rt.duration = 237600
WHERE @fire_mini_restore_ok = 1
  AND rt.duration IN (172800, 216000)
  AND rt.guild_id <> 1;

UPDATE spawn2 AS s
JOIN fire_mini_restore AS t ON t.spawn_id = s.id
SET s.respawntime = 237600
WHERE @fire_mini_restore_ok = 1;

UPDATE npc_types AS n
JOIN fire_mini_restore AS t ON t.npc_id = n.id
SET n.loot_lockout = 237600,
    n.instance_spawn_timer_override = 237600000
WHERE @fire_mini_restore_ok = 1;
COMMIT;

SELECT IF(@fire_mini_restore_ok = 1, 'APPLIED: verify all ten rows below',
          'STOP: expected Fire mini mapping differs; no changes made') AS result;
SELECT n.id, n.name, s.id AS spawn_id,
       s.respawntime / 3600 AS respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM fire_mini_restore AS t
JOIN npc_types AS n ON n.id = t.npc_id
JOIN spawn2 AS s ON s.id = t.spawn_id
ORDER BY n.id;
DROP TEMPORARY TABLE fire_mini_restore;
