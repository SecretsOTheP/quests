-- Read-only installation check. Always returns one row per requested NPC.
-- Run against the content database AFTER applying the install SQL.
-- Checks identity, appearance, spawn links and enabled landing settings.
SET STATEMENT max_statement_time=2 FOR
SELECT DATABASE() AS checked_database, wanted.id AS npc_id,
       wanted.name AS expected_name, n.name AS actual_name,
       n.race, n.texture, n.helmtexture, n.face, n.size,
       g.id AS spawn_group, e.npcID AS spawn_entry_npc, e.chance,
       s.id AS spawn_point, s.zone, s.enabled, s.x, s.y, s.z, s.heading,
       CASE
         WHEN n.id IS NULL OR g.id IS NULL OR e.npcID IS NULL OR s.id IS NULL
           THEN 'MISSING: INSTALL SQL REQUIRED'
         WHEN BINARY n.name = BINARY wanted.name
           AND n.race = 10 AND n.texture = 1
           AND n.helmtexture = wanted.helm AND n.face = wanted.face
           AND ABS(n.size - 7.5) < 0.01
           AND n.class = 1 AND n.loottable_id = 0 AND n.merchant_id = 0
           AND n.loot_lockout = 0 AND n.skip_global_loot = 1
           AND g.name = wanted.group_name AND g.spawn_limit = 1 AND g.despawn = 0
           AND g.rand_spawns = 0 AND g.wp_spawns = 0
           AND e.chance = 100 AND e.mintime = 0 AND e.maxtime = 0
           AND e.min_expansion = -1 AND e.max_expansion = -1
           AND e.content_flags IS NULL AND e.content_flags_disabled IS NULL
           AND s.spawngroupID = wanted.id AND s.zone = 'poknowledge' AND s.enabled = 1
           AND ABS(s.x - wanted.x) < 0.01 AND ABS(s.y - wanted.y) < 0.01
           AND ABS(s.z - wanted.z) < 0.01 AND ABS(s.heading - 157) < 0.01
           AND s.respawntime = 60 AND s.variance = 0 AND s.pathgrid = 0
           AND s._condition = 0 AND s.raid_target_spawnpoint = 0
           AND s.min_expansion = -1 AND s.max_expansion = -1
           AND s.content_flags IS NULL AND s.content_flags_disabled IS NULL
           THEN 'INSTALLED'
         ELSE 'DIFF: REVIEW INSTALL OUTPUT'
       END AS result
FROM (
    SELECT 7151301 AS id, 'Gork,_Theoretical_Physicist' AS name,
           'pok_library_gork' AS group_name, 0 AS helm, 4 AS face,
           949 AS x, 25 AS y, 3.4 AS z
    UNION ALL
    SELECT 7151302, 'Mork,_Applied_Physicist', 'pok_library_mork', 3, 0, 948, 44, 389.4
) wanted
LEFT JOIN npc_types n FORCE INDEX (PRIMARY) ON n.id = wanted.id
LEFT JOIN spawngroup g FORCE INDEX (PRIMARY) ON g.id = wanted.id
LEFT JOIN spawnentry e FORCE INDEX (PRIMARY)
    ON e.spawngroupID = wanted.id AND e.npcID = wanted.id
LEFT JOIN spawn2 s FORCE INDEX (PRIMARY) ON s.id = wanted.id
ORDER BY wanted.id;
