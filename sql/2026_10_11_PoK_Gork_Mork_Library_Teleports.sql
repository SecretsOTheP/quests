-- Add Gork and Mork beside the Plane of Knowledge library lift.
-- Preflight: NPC, spawngroup and spawn2 IDs 7151301/7151302 must be unused.
-- NPC appearance is copied from Loreseeker Olgrim (202026), a PoK ogre merchant.
-- Applies only new NPC/spawn rows. No doors, player data or saved timers change.
-- Load both matching full-name scripts in poknowledge before repopping the zone.
-- Roles are part of the visible name: Zeal does not render NPC surnames.
-- MyISAM content tables require a backup; transaction rollback
-- does not protect these inserts. Run once, after the stated ID preflight.

-- Gate every insert together: an occupied ID or missing appearance template
-- makes the entire script a no-op, including when it is run a second time.
CREATE TEMPORARY TABLE pok_lift_preflight AS
SELECT (
    EXISTS (SELECT 1 FROM npc_types WHERE id = 202026
            AND name = 'Loreseeker_Olgrim' AND race = 10)
    AND NOT EXISTS (SELECT 1 FROM npc_types WHERE id IN (7151301, 7151302))
    AND NOT EXISTS (SELECT 1 FROM spawngroup WHERE id IN (7151301, 7151302))
    AND NOT EXISTS (SELECT 1 FROM spawn2 WHERE id IN (7151301, 7151302))
    AND NOT EXISTS (SELECT 1 FROM spawnentry WHERE spawngroupID IN (7151301, 7151302))
) AS ready;

SELECT CASE WHEN ready = 1 THEN 'READY: adding Gork and Mork'
            ELSE 'SKIPPED: template missing or one of the reserved IDs is already in use'
       END AS pok_library_setup
FROM pok_lift_preflight;

CREATE TEMPORARY TABLE pok_lift_ogre_template AS
SELECT * FROM npc_types WHERE id = 202026 AND race = 10
AND (SELECT ready FROM pok_lift_preflight) = 1;

UPDATE pok_lift_ogre_template
SET id = 7151301, name = 'Gork,_Theoretical_Physicist', lastname = '',
    level = 65, class = 1, hp = 10000, mana = 0, size = 7.5,
    loottable_id = 0, merchant_id = 0, npc_spells_id = 0,
    npc_spells_effects_id = 0, emoteid = 0,
    special_abilities = '14,1^19,1^20,1^24,1^25,1^35,1',
    npc_aggro = 0, aggro_pc = 0, aggroradius = 0, assistradius = 0,
    runspeed = 0, walkspeed = 0, exp_pct = 0,
    raid_target = 0, rare_spawn = 0, loot_lockout = 0,
    instance_spawn_timer_override = 0, skip_global_loot = 1;

INSERT INTO npc_types SELECT * FROM pok_lift_ogre_template;

UPDATE pok_lift_ogre_template
SET id = 7151302, name = 'Mork,_Applied_Physicist', lastname = '', face = 0,
    helmtexture = 3; -- Plate safety helmet; retain the ogre's cloth outfit.

INSERT INTO npc_types SELECT * FROM pok_lift_ogre_template;
DROP TEMPORARY TABLE pok_lift_ogre_template;

INSERT INTO spawngroup (id, name, spawn_limit)
SELECT 7151301, 'pok_library_gork', 1 FROM pok_lift_preflight WHERE ready = 1
UNION ALL
SELECT 7151302, 'pok_library_mork', 1 FROM pok_lift_preflight WHERE ready = 1;

INSERT INTO spawnentry
    (spawngroupID, npcID, chance, mintime, maxtime,
     min_expansion, max_expansion, content_flags, content_flags_disabled)
SELECT 7151301, 7151301, 100, 0, 0, -1, -1, NULL, NULL
FROM pok_lift_preflight WHERE ready = 1
UNION ALL
SELECT 7151302, 7151302, 100, 0, 0, -1, -1, NULL, NULL
FROM pok_lift_preflight WHERE ready = 1;

-- Stand eight units beside the supplied arrival points, leaving space to land.
-- Heading 314 in a player's #loc is internal NPC heading 157.
INSERT INTO spawn2
    (id, spawngroupID, zone, x, y, z, heading,
     respawntime, variance, pathgrid, _condition, cond_value,
     enabled, animation, boot_respawntime, clear_timer_onboot,
     boot_variance, force_z, min_expansion, max_expansion,
     raid_target_spawnpoint, content_flags, content_flags_disabled)
SELECT 7151301, 7151301, 'poknowledge', 949, 25, 3.4, 157,
       60, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, -1, -1, 0, NULL, NULL
FROM pok_lift_preflight WHERE ready = 1
UNION ALL
SELECT 7151302, 7151302, 'poknowledge', 948, 44, 389.4, 157,
       60, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, -1, -1, 0, NULL, NULL
FROM pok_lift_preflight WHERE ready = 1;

DROP TEMPORARY TABLE pok_lift_preflight;
