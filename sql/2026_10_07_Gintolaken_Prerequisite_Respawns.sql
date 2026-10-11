-- Restore the original prerequisite/marker definitions for the existing scripts.
-- Groups reset after 60 hours plus 1-1440 random minutes, from the group clear.
-- Gintolaken's death does not restart the whole prerequisite chain.
-- Existing saved respawn_times are unchanged. Remove loot lockouts and all old
-- character records for the prerequisites, three chieftains and Gintolaken.
-- Spawnpoint 369490 remains the separate 84-hour Council access window.
-- Fresh Earth B zones pick up these definitions. Back up content rows first;
-- content tables may be MyISAM.
CREATE TEMPORARY TABLE gintolaken_prerequisite_sync (
    spawn_id INT NOT NULL PRIMARY KEY,
    npc_id INT NOT NULL,
    respawn_seconds INT NOT NULL
);
INSERT INTO gintolaken_prerequisite_sync (spawn_id, npc_id, respawn_seconds) VALUES
    (369438, 222008, 302400),
    (369439, 222008, 302400),
    (369440, 222008, 302400),
    (369441, 222008, 302400),
    (369442, 222009, 302400),
    (369443, 222009, 302400),
    (369444, 222009, 302400),
    (369445, 222009, 302400),
    (369446, 222010, 302400),
    (369447, 222010, 302400),
    (369448, 222010, 302400),
    (369449, 222010, 302400),
    (369487, 222042, 216000),
    (369488, 222042, 216000),
    (369489, 222042, 216000);

UPDATE spawn2 AS s
JOIN gintolaken_prerequisite_sync AS t ON t.spawn_id = s.id
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = t.npc_id
SET s.respawntime = t.respawn_seconds
WHERE s.zone = 'poearthb';

-- Restore the prerequisites' original zero overrides. Their existing Lua
-- scripts own the randomized group reset. Do NOT override shared NPC 222042:
-- its three chieftain markers use 60-hour bases, Council access uses 84 hours.
UPDATE npc_types AS n
JOIN gintolaken_prerequisite_sync AS t ON t.npc_id = n.id
JOIN spawn2 AS s ON s.id = t.spawn_id AND s.zone = 'poearthb'
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID AND se.npcID = n.id
SET n.instance_spawn_timer_override = 0
WHERE n.id IN (222008,222009,222010);

-- No loot lockouts on this chain: three prerequisite types, three chieftains,
-- and Gintolaken. Clear every old record without a character/guild/expiry filter.
-- Council/Avatar and shared invisible marker 222042 are outside this scope.
UPDATE npc_types
SET loot_lockout = 0
WHERE id IN (222008,222009,222010,222035,222036,222037,222038);
DELETE FROM character_loot_lockouts
WHERE npctype_id IN (222008,222009,222010,222035,222036,222037,222038);

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

SELECT id, name, loot_lockout,
       instance_spawn_timer_override / 3600000 AS override_hours
FROM npc_types
WHERE id IN (222008,222009,222010,222035,222036,222037,222038)
ORDER BY id;

SELECT COUNT(*) AS gintolaken_chain_character_lockouts_remaining
FROM character_loot_lockouts
WHERE npctype_id IN (222008,222009,222010,222035,222036,222037,222038);
