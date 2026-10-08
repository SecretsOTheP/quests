-- Apply after the lower-plane alignment migration. Deploy the accompanying
-- Hobgoblin death script. Back up affected rows before applying: content tables
-- can be MyISAM. Reload affected zones after applying to refresh cached NPC
-- definitions, respawn countdowns and character loot lockouts.
-- Apply 2026_10_07_Dresolik_Guardian_Reset.sql for the separate one-time
-- reset of only the four Guardians of Dresolik.
-- Seconds for respawn/loot; milliseconds for NPC overrides.
-- NULL cycle/override means preserve that setting (Air shared/trash spawns).
CREATE TEMPORARY TABLE pop_final_cycle_sync (
    npc_id INT NOT NULL PRIMARY KEY,
    cycle_seconds INT NULL,
    loot_seconds INT NOT NULL,
    override_ms INT NULL
);
INSERT INTO pop_final_cycle_sync (npc_id, cycle_seconds, loot_seconds, override_ms)
VALUES
    (205134, 86400, 0, 0), -- Rallius Rattican
    (204047, 86400, 0, 0), -- Seilaen
    (204028, 86400, 0, 0), -- Vhaksiz the Shade
    (207052, 237600, 237600, 0), -- Sorrowsong
    (214053, 86400, 0, 0), -- Glykus Helmir
    (214054, 86400, 0, 0), -- Tagrin Maldric
    (214092, 86400, 0, 0), -- The Diaku Overseer
    (212014, 237600, 237600, 237600000), -- Jiva
    (212023, 237600, 237600, 237600000), -- Arlyxir
    (212026, 237600, 237600, 237600000), -- Rizlona
    (212046, 237600, 0, 237600000), -- Four Guardians of Dresolik share one NPC type; no loot lockout
    (212055, 237600, 237600, 237600000), -- Xuzl
    (215060, NULL, 0, NULL), -- Lossenmachar; preserve shared spawnpoints
    (215005, NULL, 0, NULL), -- High Councilman; preserve respawn
    (215051, NULL, 0, NULL), -- Servant of Air; preserve respawn
    (215053, NULL, 0, NULL), -- Muzlakh; preserve respawn
    (216040, 64800, 0, 64800000), -- Ofossaa
    (216041, 64800, 0, 64800000), -- Krziik
    (216043, 64800, 0, 64800000), -- Hydrotha
    (217003, 237600, 237600, 237600000), -- Blazzax
    (217005, 237600, 237600, 237600000), -- Babnoxis
    (217019, 237600, 237600, 237600000), -- Arch Mage Yozanni
    (217032, 237600, 237600, 237600000), -- General Reparm
    (217036, 237600, 237600, 237600000), -- General Druav
    (217049, 237600, 237600, 237600000), -- Jaxoliz
    (217051, 237600, 237600, 237600000), -- Criare
    (217056, 237600, 237600, 237600000), -- Quavonis
    (217059, 237600, 237600, 237600000), -- Magmaton
    (217063, 237600, 237600, 237600000), -- Pyronis
    (204010, 86400, 86400, 0), -- Bullyrag; also deploy Hobgoblin death script
    (200020, 86400, 0, 0), -- Paffa starter; approved earlier daily respawn
    (206053, 86400, 0, 0), -- Manaetic Prototype X
    (206054, 86400, 0, 0), -- Manaetic Prototype IX
    (206055, 86400, 0, 0), -- Manaetic Prototype XI
    (209016, 10800, 0, 0), -- Brynju Thunderclap
    (209059, 10800, 0, 0), -- Auliffe Chaoswind
    (209060, 10800, 0, 0), -- six-hour Eindride definition; fast version unchanged
    (209061, 10800, 0, 0), -- Kuanbyr Hailstorm
    (209070, 10800, 0, 0), -- Laef Windfall
    (209071, 10800, 0, 0), -- Gaukr Sandstorm
    (209072, 10800, 0, 0), -- Oreen Wavecrasher
    (209082, 10800, 0, 0); -- Hreidar Lynhillig

-- Capture old timers before changing definitions; convert only known normal
-- countdowns. Short scripted retries and Guild 1 raid sentinels remain intact.
CREATE TEMPORARY TABLE pop_final_spawn_sync AS
SELECT s.id AS spawn_id, s.zone, s.respawntime AS old_base,
       n.instance_spawn_timer_override DIV 1000 AS old_override,
       t.cycle_seconds
FROM pop_final_cycle_sync AS t
JOIN npc_types AS n ON n.id = t.npc_id
JOIN spawnentry AS se ON se.npcID = n.id
JOIN spawn2 AS s ON s.spawngroupID = se.spawngroupID
WHERE t.cycle_seconds IS NOT NULL;
ALTER TABLE pop_final_spawn_sync ADD PRIMARY KEY (spawn_id);

START TRANSACTION;
-- Removing a loot lockout also removes already-recorded character lockouts.
DELETE cl FROM character_loot_lockouts AS cl
JOIN pop_final_cycle_sync AS t ON t.npc_id = cl.npctype_id
WHERE t.loot_seconds = 0;

-- Fire: restore still-active 48-hour loot lockouts to 66 hours while retaining
-- the original kill time. Do not revive expired lockouts. The old-definition
-- guard makes reruns safe, including after the dedicated Fire restoration SQL.
UPDATE character_loot_lockouts AS cl
JOIN npc_types AS n ON n.id = cl.npctype_id
JOIN pop_final_cycle_sync AS t ON t.npc_id = n.id
SET cl.expiry = cl.expiry - n.loot_lockout + t.loot_seconds
WHERE cl.expiry > UNIX_TIMESTAMP()
  AND t.npc_id IN (217003,217005,217019,217032,217036,217049,217051,217056,217059,217063)
  AND t.loot_seconds = 237600 AND n.loot_lockout = 172800;

UPDATE respawn_times AS rt
JOIN pop_final_spawn_sync AS t ON t.spawn_id = rt.id
JOIN spawn2 AS s ON s.id = rt.id
SET rt.duration = t.cycle_seconds
WHERE rt.duration <> t.cycle_seconds
  AND (rt.duration = t.old_base
       OR (t.old_override > 0 AND rt.duration = t.old_override)
       OR (t.spawn_id = 369184 AND rt.duration IN (432000, 604800)))
  AND NOT (rt.guild_id = 1 AND s.raid_target_spawnpoint = 1);

UPDATE spawn2 AS s
JOIN pop_final_spawn_sync AS t ON t.spawn_id = s.id
SET s.respawntime = t.cycle_seconds;

UPDATE npc_types AS n
JOIN pop_final_cycle_sync AS t ON t.npc_id = n.id
SET n.loot_lockout = t.loot_seconds,
    n.instance_spawn_timer_override = COALESCE(t.override_ms, n.instance_spawn_timer_override);
COMMIT;

SELECT n.id, n.name, s.id AS spawn_id,
       s.respawntime / 3600 AS respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM pop_final_cycle_sync AS t
JOIN npc_types AS n ON n.id = t.npc_id
LEFT JOIN spawnentry AS se ON se.npcID = n.id
LEFT JOIN spawn2 AS s ON s.spawngroupID = se.spawngroupID
ORDER BY n.id, s.id;
DROP TEMPORARY TABLE pop_final_spawn_sync;
DROP TEMPORARY TABLE pop_final_cycle_sync;
