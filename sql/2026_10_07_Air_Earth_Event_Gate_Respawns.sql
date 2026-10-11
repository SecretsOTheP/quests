-- Hidden encounter gates still used 71-hour native respawns while their
-- encounter/reward cycles use 66 hours. When a gate is absent, the scripts
-- select an alternate boss instead of the normal reward encounter.
-- Future cooldowns only: existing saved countdowns must expire normally.
-- Fresh zone loads pick up spawn/NPC definitions; quest reload alone does not.
-- Back up affected rows first: content tables may be MyISAM.
-- Respawn seconds; NPC instance override milliseconds.
CREATE TEMPORARY TABLE pop_elemental_gate_sync (
    spawn_id INT NOT NULL PRIMARY KEY,
    zone_name VARCHAR(32) NOT NULL,
    npc_id INT NOT NULL UNIQUE
);
INSERT INTO pop_elemental_gate_sync (spawn_id, zone_name, npc_id) VALUES
    (369495, 'poair', 215414), -- Wind: stormrider_guy
    (369498, 'poair', 215415), -- Smoke: elemental_guy
    (369497, 'poair', 215416), -- Mist: phoenix_guy
    (369496, 'poair', 215417), -- Dust: spider_man
    (369482, 'poeartha', 218391), -- Stone: stone_guy
    (369483, 'poeartha', 218390), -- Mud: muddite_guy
    (369484, 'poeartha', 218392), -- Vine: vegerog_guy
    (369485, 'poeartha', 218412); -- Dust: POEElem3day

START TRANSACTION;

UPDATE spawn2 AS s
JOIN pop_elemental_gate_sync AS t ON t.spawn_id = s.id AND t.zone_name = s.zone
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
SET s.respawntime = 237600;

-- These non-raid control NPCs need an explicit encounter timer so ordinary
-- instance/trash timer substitution cannot replace their 66-hour policy.
UPDATE npc_types AS n
JOIN pop_elemental_gate_sync AS t ON t.npc_id = n.id
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = t.zone_name
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = n.id
SET n.instance_spawn_timer_override = 237600000;

COMMIT;

SELECT s.id AS spawn_id, s.zone, n.id AS npc_id, n.name,
       s.respawntime / 3600 AS base_respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS instance_override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM pop_elemental_gate_sync AS t
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = t.zone_name
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
JOIN npc_types AS n ON n.id = t.npc_id
ORDER BY s.zone, s.id;

DROP TEMPORARY TABLE pop_elemental_gate_sync;
