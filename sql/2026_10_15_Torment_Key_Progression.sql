-- Torment Screaming Sphere progression: entry timer and avatar spawn chances.
-- Deploy potorment/Baraguj_Szuul.lua and potorment/#Baraguj_Szuul.lua together
-- with this change, then reload the affected zone's spawn definitions.
-- The Horror already uses 1800 seconds. Align its entry NPC here.
-- Guild Slow Down and existing saved countdowns are deliberately preserved.
-- Existing countdowns can finish once; this sets subsequent normal cycles.
-- No change to the reward form's 12-hour lifetime, loot, or quest requirements.

UPDATE spawn2
SET respawntime = 1800
WHERE id = 346955
  AND zone = 'potorment'
  AND raid_target_spawnpoint = 0
  AND respawntime IN (86400, 1800)
  AND EXISTS (
      SELECT 1
      FROM spawnentry
      WHERE spawnentry.spawngroupID = spawn2.spawngroupID
        AND spawnentry.npcID = 207028
  );

-- Reissue the intended avatar weights from 2026_10_06 alongside this chain
-- fix. Validate each whole group before changing any weights: missing, extra,
-- or unfamiliar entries skip it. Known old/new mixtures can be completed.
-- Every statement is self-contained: no temporary tables or session variables.
-- GROUP BY materializes the eligibility query before the joined update.
UPDATE spawnentry AS se
JOIN (
    SELECT existing.spawngroupID AS group_id
    FROM spawnentry AS existing FORCE INDEX (PRIMARY)
    WHERE existing.spawngroupID IN (225595, 225594, 207041, 225596)
    GROUP BY existing.spawngroupID
    HAVING COUNT(*) = CASE WHEN existing.spawngroupID = 225596 THEN 4 ELSE 3 END
       AND SUM(CASE
           WHEN existing.spawngroupID = 225595 AND (
               (existing.npcID = 207313 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207009 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207282 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 225594 AND (
               (existing.npcID = 207314 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207288 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207043 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 207041 AND (
               (existing.npcID = 207315 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207041 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207286 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 225596 AND (
               (existing.npcID = 207316 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207218 AND existing.chance IN (22, 14))
               OR (existing.npcID = 207290 AND existing.chance IN (23, 15))
               OR (existing.npcID = 207294 AND existing.chance IN (40, 26))
           ) THEN 1
           ELSE 0 END) = COUNT(*)
) AS eligible ON eligible.group_id = se.spawngroupID
SET se.chance = CASE se.npcID
    WHEN 207313 THEN 45
    WHEN 207009 THEN 27
    WHEN 207282 THEN 28
    WHEN 207314 THEN 45
    WHEN 207288 THEN 27
    WHEN 207043 THEN 28
    WHEN 207315 THEN 45
    WHEN 207041 THEN 27
    WHEN 207286 THEN 28
    WHEN 207316 THEN 45
    WHEN 207218 THEN 14
    WHEN 207290 THEN 15
    WHEN 207294 THEN 26
    ELSE se.chance
END
WHERE se.spawngroupID IN (225595, 225594, 207041, 225596);

-- Standalone verification: all 13 expected entries, including missing rows.
-- An invalid group is reported for review; valid rows show MATCH or DIFF.
SELECT DATABASE() AS checked_database, w.group_id, w.npc_id, n.name,
       se.chance AS actual_chance, w.expected_chance,
       CASE
           WHEN eligible.group_id IS NULL THEN 'SKIPPED GROUP: REVIEW'
           WHEN se.chance = w.expected_chance THEN 'MATCH'
           ELSE 'DIFF'
       END AS result
FROM (
    SELECT 225595 AS group_id, 207313 AS npc_id, 45 AS expected_chance
    UNION ALL
    SELECT 225595, 207009, 27
    UNION ALL
    SELECT 225595, 207282, 28
    UNION ALL
    SELECT 225594, 207314, 45
    UNION ALL
    SELECT 225594, 207288, 27
    UNION ALL
    SELECT 225594, 207043, 28
    UNION ALL
    SELECT 207041, 207315, 45
    UNION ALL
    SELECT 207041, 207041, 27
    UNION ALL
    SELECT 207041, 207286, 28
    UNION ALL
    SELECT 225596, 207316, 45
    UNION ALL
    SELECT 225596, 207218, 14
    UNION ALL
    SELECT 225596, 207290, 15
    UNION ALL
    SELECT 225596, 207294, 26
) AS w
LEFT JOIN spawnentry AS se FORCE INDEX (PRIMARY)
  ON se.spawngroupID = w.group_id AND se.npcID = w.npc_id
LEFT JOIN npc_types AS n FORCE INDEX (PRIMARY) ON n.id = w.npc_id
LEFT JOIN (
    SELECT existing.spawngroupID AS group_id
    FROM spawnentry AS existing FORCE INDEX (PRIMARY)
    WHERE existing.spawngroupID IN (225595, 225594, 207041, 225596)
    GROUP BY existing.spawngroupID
    HAVING COUNT(*) = CASE WHEN existing.spawngroupID = 225596 THEN 4 ELSE 3 END
       AND SUM(CASE
           WHEN existing.spawngroupID = 225595 AND (
               (existing.npcID = 207313 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207009 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207282 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 225594 AND (
               (existing.npcID = 207314 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207288 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207043 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 207041 AND (
               (existing.npcID = 207315 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207041 AND existing.chance IN (42, 27))
               OR (existing.npcID = 207286 AND existing.chance IN (43, 28))
           ) THEN 1
           WHEN existing.spawngroupID = 225596 AND (
               (existing.npcID = 207316 AND existing.chance IN (15, 45))
               OR (existing.npcID = 207218 AND existing.chance IN (22, 14))
               OR (existing.npcID = 207290 AND existing.chance IN (23, 15))
               OR (existing.npcID = 207294 AND existing.chance IN (40, 26))
           ) THEN 1
           ELSE 0 END) = COUNT(*)
) AS eligible ON eligible.group_id = w.group_id
ORDER BY w.group_id, w.npc_id;

SELECT DATABASE() AS checked_database, spawngroupID,
       SUM(chance) AS total_chance
FROM spawnentry FORCE INDEX (PRIMARY)
WHERE spawngroupID IN (225595, 225594, 207041, 225596)
GROUP BY spawngroupID;

SELECT DATABASE() AS checked_database, id AS spawn_id, zone, respawntime,
       respawntime / 60 AS respawn_minutes
FROM spawn2 FORCE INDEX (PRIMARY)
WHERE id IN (346828, 346955)
ORDER BY id;
