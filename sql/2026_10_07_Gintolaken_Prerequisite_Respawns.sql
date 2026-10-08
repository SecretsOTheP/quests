-- Deploy with the matching poearthb scripts and gintolaken_cycle module.
-- Use a 66-hour future prerequisite/event cycle and keep chieftain loot at 66h.
-- Existing saved respawn_times are unchanged. Remove only Gintolaken's loot
-- lockout and all existing character records for his NPC type (222038).
-- Spawnpoint 369490 remains the separate 84-hour Council access window.
-- Fresh Earth B zones pick up these definitions. Back up content rows first;
-- content tables may be MyISAM.
CREATE TEMPORARY TABLE gintolaken_prerequisite_sync (
    spawn_id INT NOT NULL PRIMARY KEY,
    npc_id INT NOT NULL
);
INSERT INTO gintolaken_prerequisite_sync (spawn_id, npc_id) VALUES
    (369438, 222008),
    (369439, 222008),
    (369440, 222008),
    (369441, 222008),
    (369442, 222009),
    (369443, 222009),
    (369444, 222009),
    (369445, 222009),
    (369446, 222010),
    (369447, 222010),
    (369448, 222010),
    (369449, 222010),
    (369487, 222042),
    (369488, 222042),
    (369489, 222042);

UPDATE spawn2 AS s
JOIN gintolaken_prerequisite_sync AS t ON t.spawn_id = s.id
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
SET s.respawntime = 237600
WHERE s.zone = 'poearthb';

-- The three combat prerequisite types can safely have explicit overrides.
-- Do NOT override NPC 222042: it is shared with the 84-hour Council marker.
-- Chieftain deaths explicitly set the three marker timers in Lua instead.
UPDATE npc_types AS n
JOIN gintolaken_prerequisite_sync AS t ON t.npc_id = n.id
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = 'poearthb'
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = n.id
SET n.instance_spawn_timer_override = 237600000
WHERE n.id IN (222008,222009,222010);

-- Gintolaken has no loot cooldown. Keep his normal respawn/instance timer.
-- Clear every old Gintolaken record, without filtering characters or expiry.
UPDATE npc_types SET loot_lockout = 0 WHERE id = 222038;
DELETE FROM character_loot_lockouts WHERE npctype_id = 222038;

SELECT s.id AS spawn_id, n.id AS npc_id, n.name,
       s.respawntime / 3600 AS base_respawn_hours,
       n.instance_spawn_timer_override / 3600000 AS override_hours,
       n.loot_lockout / 3600 AS loot_lockout_hours
FROM gintolaken_prerequisite_sync AS t
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = 'poearthb'
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
JOIN npc_types AS n ON n.id = t.npc_id
ORDER BY s.id;

DROP TEMPORARY TABLE gintolaken_prerequisite_sync;

SELECT n.id, n.name, n.loot_lockout,
       n.instance_spawn_timer_override / 3600000 AS override_hours,
       (SELECT COUNT(*) FROM character_loot_lockouts WHERE npctype_id = 222038)
           AS gintolaken_character_lockouts_remaining
FROM npc_types AS n WHERE n.id = 222038;
