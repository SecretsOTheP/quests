-- Apply after 2026_10_03_Lower_Planes_Named_Respawns.sql with zone
-- processes stopped. Restart zones afterward to reload NPC definitions,
-- saved respawn countdowns and cached character loot lockouts.
-- Back up the affected rows first: some content tables may use MyISAM,
-- so START TRANSACTION cannot roll back every table on an error.
-- All durations below use seconds, except the NPC override in milliseconds.
-- Scripted recovery/repop rules and Guild 1 earthquake behavior are preserved.

CREATE TEMPORARY TABLE pop_named_cycle_alignment (
    spawn_id INT NOT NULL,
    zone_name VARCHAR(32) NOT NULL,
    npc_id INT NOT NULL PRIMARY KEY,
    cycle_seconds INT NOT NULL,
    loot_seconds INT NOT NULL
);

INSERT INTO pop_named_cycle_alignment
    (spawn_id, zone_name, npc_id, cycle_seconds, loot_seconds)
VALUES
    (344762, 'podisease', 205091, 86400, 86400), -- Grummus
    (345473, 'pojustice', 201492, 86400, 86400), -- ancient crawler; shared spawn has placeholders
    (360642, 'codecay', 200245, 86400, 86400), -- Carprin starter / High Priest Ultor reward
    (346764, 'potorment', 207015, 86400, 86400), -- Keeper of Sorrows
    (369184, 'ponightmare', 204010, 86400, 86400), -- Bullyrag Bat
    (345905, 'ponightmare', 204034, 86400, 86400), -- Terror Matriarch
    (345919, 'ponightmare', 204035, 86400, 86400), -- Untel Dak
    (346876, 'potorment', 207002, 86400, 86400), -- Ta Grusch the Abomination
    (346763, 'potorment', 207003, 86400, 86400), -- Acolyte of Affliction
    (346875, 'potorment', 207004, 86400, 86400), -- Maareq the Prophet
    (346877, 'potorment', 207027, 86400, 86400), -- Salczek the Fleshgrinder
    (346955, 'potorment', 207028, 86400, 86400), -- normal Baraguj; event version remains separate
    (364399, 'povalor', 208157, 86400, 86400), -- Sleep Walker variant 1
    (364399, 'povalor', 208202, 86400, 86400), -- Sleep Walker variant 2
    (364399, 'povalor', 208208, 86400, 86400), -- Sleep Walker variant 3
    (367163, 'hohonorb', 220012, 237600, 237600), -- Ralthazor; match Mithaniel Marr
    (367227, 'hohonorb', 220021, 237600, 237600), -- Edium; match Mithaniel Marr
    (366604, 'hohonorb', 220022, 237600, 237600), -- Halon; match Mithaniel Marr
    (360643, 'codecay', 200226, 237600, 237600); -- Spectre starter / Bertox reward; preserve 66-hour cycle

START TRANSACTION;

-- Lockout records contain only expiry, not kill time. For the known old
-- Grummus/Ultor 66h and crawler 162h definitions, infer kill time from expiry
-- and preserve elapsed time when shortening to 24h. This runs before the NPC
-- definitions change, so reapplying the migration cannot shorten them twice.
UPDATE character_loot_lockouts AS cl
JOIN npc_types AS n ON n.id = cl.npctype_id
JOIN pop_named_cycle_alignment AS t ON t.npc_id = n.id
SET cl.expiry = cl.expiry - n.loot_lockout + t.cycle_seconds
WHERE cl.expiry > UNIX_TIMESTAMP()
  AND ((n.id IN (205091, 200245) AND n.loot_lockout = 237600)
    OR (n.id = 201492 AND n.loot_lockout = 583200));

-- Rahlgon has no loot and belongs entirely to Aerin Dar's event.
-- Deploy the matching Aerin Dar / Rahlgon scripts with this migration.
DELETE FROM character_loot_lockouts WHERE npctype_id = 208176;
UPDATE npc_types
SET loot_lockout = 0, instance_spawn_timer_override = 0
WHERE id = 208176;
UPDATE spawn2
SET respawntime = 0, variance = 0, boot_respawntime = 0, enabled = 0
WHERE id = 347213 AND zone = 'povalor';
DELETE FROM respawn_times WHERE id = 347213;

-- Newly locked-out named apply their lockout on future kills. Past kills
-- cannot be backfilled from these tables because no kill timestamp is stored.
UPDATE npc_types AS n
JOIN pop_named_cycle_alignment AS t ON t.npc_id = n.id
SET n.loot_lockout = t.loot_seconds,
    n.instance_spawn_timer_override = CASE
        WHEN n.id = 201492 OR n.instance_spawn_timer_override <> 0
            THEN t.cycle_seconds * 1000
        ELSE 0
    END;

UPDATE spawn2 AS s
JOIN (SELECT DISTINCT spawn_id, zone_name, cycle_seconds
      FROM pop_named_cycle_alignment) AS t
  ON t.spawn_id = s.id AND t.zone_name = s.zone
SET s.respawntime = t.cycle_seconds;

-- Shorten old normal countdowns without resetting their start timestamps.
-- Leave Guild 1 raid-target sentinels, existing shorter countdowns, and
-- scripted retry timers alone. Spectre retries remain controlled by Bertox.
UPDATE respawn_times AS rt
JOIN spawn2 AS s ON s.id = rt.id
JOIN (SELECT DISTINCT spawn_id, zone_name, cycle_seconds
      FROM pop_named_cycle_alignment) AS t
  ON t.spawn_id = s.id AND t.zone_name = s.zone
SET rt.duration = t.cycle_seconds
WHERE rt.duration > t.cycle_seconds
  AND t.spawn_id <> 360643
  AND NOT (rt.guild_id = 1 AND s.raid_target_spawnpoint = 1);

COMMIT;

-- Independent named respawns and loot lockouts should agree.
-- Rahlgon is verified separately: disabled by default, no cooldown or lockout.
SELECT s.id AS spawn_id, t.zone_name, n.id AS npc_id, n.name,
       s.respawntime / 3600 AS base_respawn_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours,
       n.instance_spawn_timer_override / 3600000 AS instance_override_hours
FROM pop_named_cycle_alignment AS t
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = t.zone_name
JOIN npc_types AS n ON n.id = t.npc_id
ORDER BY t.zone_name, s.id, n.id;

SELECT s.id AS spawn_id, s.respawntime, s.boot_respawntime, s.enabled,
       n.id AS npc_id, n.loot_lockout, n.instance_spawn_timer_override
FROM spawn2 AS s JOIN npc_types AS n ON n.id = 208176
WHERE s.id = 347213 AND s.zone = 'povalor';

DROP TEMPORARY TABLE pop_named_cycle_alignment;
