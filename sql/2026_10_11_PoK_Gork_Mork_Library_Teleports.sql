-- Gork and Mork: repeatable installation/repair of just these two library NPCs.
-- Install both matching poknowledge Lua files, run this entire file in one
-- connection, and load the quest/spawn data. Merging does not execute SQL.
-- Uses explicit ogre settings; no appearance-template NPC is required.
-- Recognized existing Gork/Mork rows are repaired; missing rows are inserted.
-- Foreign rows at the reserved IDs block ALL persistent changes. No deletes.
-- Back up first: MyISAM cannot roll back an interrupted install. Rerun this
-- file to finish a partial install, then require two final INSTALLED results.
-- Existing elevator/doors, players, saved spawn timers and other NPCs are untouched.

DROP TEMPORARY TABLE IF EXISTS pok_lift_npcs, pok_lift_groups, pok_lift_entries,
                               pok_lift_spawns, pok_lift_preflight;
CREATE TEMPORARY TABLE pok_lift_npcs LIKE npc_types;
INSERT INTO pok_lift_npcs (id, name, face, helmtexture) VALUES
    (7151301, 'Gork,_Theoretical_Physicist', 4, 0),
    (7151302, 'Mork,_Applied_Physicist', 0, 3);
UPDATE pok_lift_npcs SET
    `lastname` = '',
    `level` = 65,
    `race` = 10,
    `class` = 1,
    `bodytype` = 1,
    `hp` = 10000,
    `mana` = 0,
    `gender` = 0,
    `texture` = 1,
    `size` = 7.5,
    `chesttexture` = 1,
    `armtexture` = 1,
    `bracertexture` = 1,
    `handtexture` = 1,
    `legtexture` = 1,
    `feettexture` = 1,
    `luclin_hairstyle` = 255,
    `luclin_haircolor` = 255,
    `luclin_eyecolor` = 255,
    `luclin_eyecolor2` = 255,
    `luclin_beardcolor` = 255,
    `luclin_beard` = 255,
    `armortint_id` = 0,
    `armortint_red` = 0,
    `armortint_green` = 0,
    `armortint_blue` = 0,
    `d_melee_texture1` = 0,
    `d_melee_texture2` = 0,
    `light` = 0,
    `flymode` = -1,
    `npc_faction_id` = 1424,
    `loottable_id` = 0,
    `merchant_id` = 0,
    `npc_spells_id` = 0,
    `npc_spells_effects_id` = 0,
    `emoteid` = 0,
    `special_abilities` = '14,1^19,1^20,1^24,1^25,1^35,1',
    `npc_aggro` = 0,
    `aggro_pc` = 0,
    `aggroradius` = 0,
    `assistradius` = 0,
    `runspeed` = 0,
    `walkspeed` = 0,
    `exp_pct` = 0,
    `raid_target` = 0,
    `rare_spawn` = 0,
    `loot_lockout` = 0,
    `instance_spawn_timer_override` = 0,
    `skip_global_loot` = 1,
    `spawn_limit` = 1,
    `unique_spawn_by_name` = 0,
    `underwater` = 0,
    `ignore_despawn` = 0,
    `qglobal` = 0;

CREATE TEMPORARY TABLE pok_lift_groups LIKE spawngroup;
INSERT INTO pok_lift_groups (id, name) VALUES
    (7151301, 'pok_library_gork'), (7151302, 'pok_library_mork');
UPDATE pok_lift_groups SET
`spawn_limit` = 1, `despawn` = 0, `rand_spawns` = 0, `wp_spawns` = 0, `max_x` = 0, `min_x` = 0, `max_y` = 0, `min_y` = 0;

CREATE TEMPORARY TABLE pok_lift_entries LIKE spawnentry;
INSERT INTO pok_lift_entries (spawngroupID, npcID, chance, mintime, maxtime, min_expansion, max_expansion, content_flags, content_flags_disabled) VALUES
    (7151301,7151301,100,0,0,-1,-1,NULL,NULL),
    (7151302,7151302,100,0,0,-1,-1,NULL,NULL);

-- Stand beside the landings, eight Y units from the teleport arrivals.
CREATE TEMPORARY TABLE pok_lift_spawns LIKE spawn2;
INSERT INTO pok_lift_spawns (`id`, `spawngroupID`, `zone`, `x`, `y`, `z`, `heading`, `respawntime`, `variance`, `pathgrid`, `_condition`, `cond_value`, `enabled`, `animation`, `boot_respawntime`, `clear_timer_onboot`, `boot_variance`, `force_z`, `min_expansion`, `max_expansion`, `raid_target_spawnpoint`, `content_flags`, `content_flags_disabled`) VALUES
    (7151301,7151301,'poknowledge',949,25,3.4,157,60,0,0,0,1,1,0,0,0,0,0,-1,-1,0,NULL,NULL),
    (7151302,7151302,'poknowledge',948,44,389.4,157,60,0,0,0,1,1,0,0,0,0,0,-1,-1,0,NULL,NULL);

-- Bare TEST names are recognized only with their known PoK group and spawnpoint.
-- The ownership preflight is time-bounded; stop on any SQL error.
SET STATEMENT max_statement_time=2 FOR
CREATE TEMPORARY TABLE pok_lift_preflight AS
SELECT (
    NOT EXISTS (SELECT 1 FROM npc_types n JOIN pok_lift_npcs t ON n.id = t.id
                WHERE NOT (BINARY n.name <=> BINARY t.name)
                  AND NOT ((BINARY n.name <=> BINARY IF(t.id = 7151301, 'Gork', 'Mork'))
                    AND EXISTS (SELECT 1 FROM spawngroup g WHERE g.id = n.id
                        AND BINARY g.name = BINARY IF(n.id = 7151301, 'pok_library_gork', 'pok_library_mork'))
                    AND EXISTS (SELECT 1 FROM spawn2 s WHERE s.id = n.id
                        AND s.spawngroupID = n.id AND s.zone = 'poknowledge')))
    AND NOT EXISTS (SELECT 1 FROM spawnentry
                    WHERE npcID IN (7151301,7151302) AND spawngroupID <> npcID)
    AND NOT EXISTS (SELECT 1 FROM spawngroup g JOIN pok_lift_groups t ON g.id = t.id
                    WHERE NOT (g.name <=> t.name))
    AND NOT EXISTS (SELECT 1 FROM spawngroup
                    WHERE name IN ('pok_library_gork','pok_library_mork')
                      AND id NOT IN (7151301,7151302))
    AND NOT EXISTS (SELECT 1 FROM spawn2 s JOIN pok_lift_spawns t ON s.id = t.id
                    WHERE NOT (s.zone <=> t.zone) OR NOT (s.spawngroupID <=> t.spawngroupID))
    AND NOT EXISTS (SELECT 1 FROM spawn2
                    WHERE spawngroupID IN (7151301,7151302)
                      AND id NOT IN (7151301,7151302))
    AND NOT EXISTS (SELECT 1 FROM spawnentry
                    WHERE spawngroupID IN (7151301,7151302) AND npcID <> spawngroupID)
) AS ready;

UPDATE npc_types r JOIN pok_lift_npcs t ON r.`id` = t.`id`
JOIN pok_lift_preflight p ON p.ready = 1
SET r.`name` = t.`name`,
    r.`face` = t.`face`,
    r.`helmtexture` = t.`helmtexture`,
    r.`lastname` = t.`lastname`,
    r.`level` = t.`level`,
    r.`race` = t.`race`,
    r.`class` = t.`class`,
    r.`bodytype` = t.`bodytype`,
    r.`hp` = t.`hp`,
    r.`mana` = t.`mana`,
    r.`gender` = t.`gender`,
    r.`texture` = t.`texture`,
    r.`size` = t.`size`,
    r.`chesttexture` = t.`chesttexture`,
    r.`armtexture` = t.`armtexture`,
    r.`bracertexture` = t.`bracertexture`,
    r.`handtexture` = t.`handtexture`,
    r.`legtexture` = t.`legtexture`,
    r.`feettexture` = t.`feettexture`,
    r.`luclin_hairstyle` = t.`luclin_hairstyle`,
    r.`luclin_haircolor` = t.`luclin_haircolor`,
    r.`luclin_eyecolor` = t.`luclin_eyecolor`,
    r.`luclin_eyecolor2` = t.`luclin_eyecolor2`,
    r.`luclin_beardcolor` = t.`luclin_beardcolor`,
    r.`luclin_beard` = t.`luclin_beard`,
    r.`armortint_id` = t.`armortint_id`,
    r.`armortint_red` = t.`armortint_red`,
    r.`armortint_green` = t.`armortint_green`,
    r.`armortint_blue` = t.`armortint_blue`,
    r.`d_melee_texture1` = t.`d_melee_texture1`,
    r.`d_melee_texture2` = t.`d_melee_texture2`,
    r.`light` = t.`light`,
    r.`flymode` = t.`flymode`,
    r.`npc_faction_id` = t.`npc_faction_id`,
    r.`loottable_id` = t.`loottable_id`,
    r.`merchant_id` = t.`merchant_id`,
    r.`npc_spells_id` = t.`npc_spells_id`,
    r.`npc_spells_effects_id` = t.`npc_spells_effects_id`,
    r.`emoteid` = t.`emoteid`,
    r.`special_abilities` = t.`special_abilities`,
    r.`npc_aggro` = t.`npc_aggro`,
    r.`aggro_pc` = t.`aggro_pc`,
    r.`aggroradius` = t.`aggroradius`,
    r.`assistradius` = t.`assistradius`,
    r.`runspeed` = t.`runspeed`,
    r.`walkspeed` = t.`walkspeed`,
    r.`exp_pct` = t.`exp_pct`,
    r.`raid_target` = t.`raid_target`,
    r.`rare_spawn` = t.`rare_spawn`,
    r.`loot_lockout` = t.`loot_lockout`,
    r.`instance_spawn_timer_override` = t.`instance_spawn_timer_override`,
    r.`skip_global_loot` = t.`skip_global_loot`,
    r.`spawn_limit` = t.`spawn_limit`,
    r.`unique_spawn_by_name` = t.`unique_spawn_by_name`,
    r.`underwater` = t.`underwater`,
    r.`ignore_despawn` = t.`ignore_despawn`,
    r.`qglobal` = t.`qglobal`;
INSERT INTO npc_types
SELECT t.* FROM pok_lift_npcs t CROSS JOIN pok_lift_preflight p
WHERE p.ready = 1 AND NOT EXISTS (SELECT 1 FROM npc_types r WHERE r.`id` = t.`id`);

UPDATE spawngroup r JOIN pok_lift_groups t ON r.`id` = t.`id`
JOIN pok_lift_preflight p ON p.ready = 1
SET r.`name` = t.`name`,
    r.`spawn_limit` = t.`spawn_limit`,
    r.`despawn` = t.`despawn`,
    r.`rand_spawns` = t.`rand_spawns`,
    r.`wp_spawns` = t.`wp_spawns`,
    r.`max_x` = t.`max_x`,
    r.`min_x` = t.`min_x`,
    r.`max_y` = t.`max_y`,
    r.`min_y` = t.`min_y`;
INSERT INTO spawngroup
SELECT t.* FROM pok_lift_groups t CROSS JOIN pok_lift_preflight p
WHERE p.ready = 1 AND NOT EXISTS (SELECT 1 FROM spawngroup r WHERE r.`id` = t.`id`);

UPDATE spawnentry r JOIN pok_lift_entries t ON r.`spawngroupID` = t.`spawngroupID` AND r.`npcID` = t.`npcID`
JOIN pok_lift_preflight p ON p.ready = 1
SET r.`chance` = t.`chance`,
    r.`mintime` = t.`mintime`,
    r.`maxtime` = t.`maxtime`,
    r.`min_expansion` = t.`min_expansion`,
    r.`max_expansion` = t.`max_expansion`,
    r.`content_flags` = t.`content_flags`,
    r.`content_flags_disabled` = t.`content_flags_disabled`;
INSERT INTO spawnentry
SELECT t.* FROM pok_lift_entries t CROSS JOIN pok_lift_preflight p
WHERE p.ready = 1 AND NOT EXISTS (SELECT 1 FROM spawnentry r WHERE r.`spawngroupID` = t.`spawngroupID` AND r.`npcID` = t.`npcID`);

UPDATE spawn2 r JOIN pok_lift_spawns t ON r.`id` = t.`id`
JOIN pok_lift_preflight p ON p.ready = 1
SET r.`spawngroupID` = t.`spawngroupID`,
    r.`zone` = t.`zone`,
    r.`x` = t.`x`,
    r.`y` = t.`y`,
    r.`z` = t.`z`,
    r.`heading` = t.`heading`,
    r.`respawntime` = t.`respawntime`,
    r.`variance` = t.`variance`,
    r.`pathgrid` = t.`pathgrid`,
    r.`_condition` = t.`_condition`,
    r.`cond_value` = t.`cond_value`,
    r.`enabled` = t.`enabled`,
    r.`animation` = t.`animation`,
    r.`boot_respawntime` = t.`boot_respawntime`,
    r.`clear_timer_onboot` = t.`clear_timer_onboot`,
    r.`boot_variance` = t.`boot_variance`,
    r.`force_z` = t.`force_z`,
    r.`min_expansion` = t.`min_expansion`,
    r.`max_expansion` = t.`max_expansion`,
    r.`raid_target_spawnpoint` = t.`raid_target_spawnpoint`,
    r.`content_flags` = t.`content_flags`,
    r.`content_flags_disabled` = t.`content_flags_disabled`;
INSERT INTO spawn2
SELECT t.* FROM pok_lift_spawns t CROSS JOIN pok_lift_preflight p
WHERE p.ready = 1 AND NOT EXISTS (SELECT 1 FROM spawn2 r WHERE r.`id` = t.`id`);

-- Report the final database state, not just readiness to run.
SELECT n.id AS npc_id, n.name AS expected_name, a.name AS actual_name,
       a.race, a.texture, a.helmtexture, g.id AS spawn_group,
       e.npcID AS spawn_entry_npc, e.chance, s.id AS spawn_point,
       s.zone, s.enabled, s.x, s.y, s.z,
       CASE WHEN p.ready <> 1 THEN 'STOP: RESERVED ID CONFLICT; NOTHING CHANGED'
            WHEN a.id IS NULL OR g.id IS NULL OR e.npcID IS NULL OR s.id IS NULL
                THEN 'INCOMPLETE: MISSING ROWS'
            WHEN
                (a.`name` <=> n.`name`)
                AND (a.`face` <=> n.`face`)
                AND (a.`helmtexture` <=> n.`helmtexture`)
                AND (a.`lastname` <=> n.`lastname`)
                AND (a.`level` <=> n.`level`)
                AND (a.`race` <=> n.`race`)
                AND (a.`class` <=> n.`class`)
                AND (a.`bodytype` <=> n.`bodytype`)
                AND (a.`hp` <=> n.`hp`)
                AND (a.`mana` <=> n.`mana`)
                AND (a.`gender` <=> n.`gender`)
                AND (a.`texture` <=> n.`texture`)
                AND (a.`size` <=> n.`size`)
                AND (a.`chesttexture` <=> n.`chesttexture`)
                AND (a.`armtexture` <=> n.`armtexture`)
                AND (a.`bracertexture` <=> n.`bracertexture`)
                AND (a.`handtexture` <=> n.`handtexture`)
                AND (a.`legtexture` <=> n.`legtexture`)
                AND (a.`feettexture` <=> n.`feettexture`)
                AND (a.`luclin_hairstyle` <=> n.`luclin_hairstyle`)
                AND (a.`luclin_haircolor` <=> n.`luclin_haircolor`)
                AND (a.`luclin_eyecolor` <=> n.`luclin_eyecolor`)
                AND (a.`luclin_eyecolor2` <=> n.`luclin_eyecolor2`)
                AND (a.`luclin_beardcolor` <=> n.`luclin_beardcolor`)
                AND (a.`luclin_beard` <=> n.`luclin_beard`)
                AND (a.`armortint_id` <=> n.`armortint_id`)
                AND (a.`armortint_red` <=> n.`armortint_red`)
                AND (a.`armortint_green` <=> n.`armortint_green`)
                AND (a.`armortint_blue` <=> n.`armortint_blue`)
                AND (a.`d_melee_texture1` <=> n.`d_melee_texture1`)
                AND (a.`d_melee_texture2` <=> n.`d_melee_texture2`)
                AND (a.`light` <=> n.`light`)
                AND (a.`flymode` <=> n.`flymode`)
                AND (a.`npc_faction_id` <=> n.`npc_faction_id`)
                AND (a.`loottable_id` <=> n.`loottable_id`)
                AND (a.`merchant_id` <=> n.`merchant_id`)
                AND (a.`npc_spells_id` <=> n.`npc_spells_id`)
                AND (a.`npc_spells_effects_id` <=> n.`npc_spells_effects_id`)
                AND (a.`emoteid` <=> n.`emoteid`)
                AND (a.`special_abilities` <=> n.`special_abilities`)
                AND (a.`npc_aggro` <=> n.`npc_aggro`)
                AND (a.`aggro_pc` <=> n.`aggro_pc`)
                AND (a.`aggroradius` <=> n.`aggroradius`)
                AND (a.`assistradius` <=> n.`assistradius`)
                AND (a.`runspeed` <=> n.`runspeed`)
                AND (a.`walkspeed` <=> n.`walkspeed`)
                AND (a.`exp_pct` <=> n.`exp_pct`)
                AND (a.`raid_target` <=> n.`raid_target`)
                AND (a.`rare_spawn` <=> n.`rare_spawn`)
                AND (a.`loot_lockout` <=> n.`loot_lockout`)
                AND (a.`instance_spawn_timer_override` <=> n.`instance_spawn_timer_override`)
                AND (a.`skip_global_loot` <=> n.`skip_global_loot`)
                AND (a.`spawn_limit` <=> n.`spawn_limit`)
                AND (a.`unique_spawn_by_name` <=> n.`unique_spawn_by_name`)
                AND (a.`underwater` <=> n.`underwater`)
                AND (a.`ignore_despawn` <=> n.`ignore_despawn`)
                AND (a.`qglobal` <=> n.`qglobal`)
                AND (g.`name` <=> tg.`name`)
                AND (g.`spawn_limit` <=> tg.`spawn_limit`)
                AND (g.`despawn` <=> tg.`despawn`)
                AND (g.`rand_spawns` <=> tg.`rand_spawns`)
                AND (g.`wp_spawns` <=> tg.`wp_spawns`)
                AND (g.`max_x` <=> tg.`max_x`)
                AND (g.`min_x` <=> tg.`min_x`)
                AND (g.`max_y` <=> tg.`max_y`)
                AND (g.`min_y` <=> tg.`min_y`)
                AND (e.`chance` <=> te.`chance`)
                AND (e.`mintime` <=> te.`mintime`)
                AND (e.`maxtime` <=> te.`maxtime`)
                AND (e.`min_expansion` <=> te.`min_expansion`)
                AND (e.`max_expansion` <=> te.`max_expansion`)
                AND (e.`content_flags` <=> te.`content_flags`)
                AND (e.`content_flags_disabled` <=> te.`content_flags_disabled`)
                AND (s.`spawngroupID` <=> ts.`spawngroupID`)
                AND (s.`zone` <=> ts.`zone`)
                AND (s.`x` <=> ts.`x`)
                AND (s.`y` <=> ts.`y`)
                AND (s.`z` <=> ts.`z`)
                AND (s.`heading` <=> ts.`heading`)
                AND (s.`respawntime` <=> ts.`respawntime`)
                AND (s.`variance` <=> ts.`variance`)
                AND (s.`pathgrid` <=> ts.`pathgrid`)
                AND (s.`_condition` <=> ts.`_condition`)
                AND (s.`cond_value` <=> ts.`cond_value`)
                AND (s.`enabled` <=> ts.`enabled`)
                AND (s.`animation` <=> ts.`animation`)
                AND (s.`boot_respawntime` <=> ts.`boot_respawntime`)
                AND (s.`clear_timer_onboot` <=> ts.`clear_timer_onboot`)
                AND (s.`boot_variance` <=> ts.`boot_variance`)
                AND (s.`force_z` <=> ts.`force_z`)
                AND (s.`min_expansion` <=> ts.`min_expansion`)
                AND (s.`max_expansion` <=> ts.`max_expansion`)
                AND (s.`raid_target_spawnpoint` <=> ts.`raid_target_spawnpoint`)
                AND (s.`content_flags` <=> ts.`content_flags`)
                AND (s.`content_flags_disabled` <=> ts.`content_flags_disabled`)
                THEN 'INSTALLED' ELSE 'INCOMPLETE: SETTINGS DIFFER' END AS result
FROM pok_lift_npcs n
JOIN pok_lift_groups tg ON tg.id = n.id
JOIN pok_lift_entries te ON te.spawngroupID = n.id AND te.npcID = n.id
JOIN pok_lift_spawns ts ON ts.id = n.id
CROSS JOIN pok_lift_preflight p
LEFT JOIN npc_types a ON a.id = n.id
LEFT JOIN spawngroup g ON g.id = n.id
LEFT JOIN spawnentry e ON e.spawngroupID = n.id AND e.npcID = n.id
LEFT JOIN spawn2 s ON s.id = n.id
ORDER BY n.id;

DROP TEMPORARY TABLE pok_lift_npcs, pok_lift_groups, pok_lift_entries,
                     pok_lift_spawns, pok_lift_preflight;
