-- Move the Nightmare B instance book and its invisible marker together.
-- Final coordinates/name were adjusted in the test database by the user.
-- Preserve the marker/book height and heading differences chosen there.
-- Load a fresh Plane of Nightmare zone after applying to refresh cached doors
-- and spawn positions. The teleport destination and access rules are preserved.

UPDATE spawn2 AS s
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID
SET s.x = 1605, s.y = 123, s.z = 220, s.heading = 6
WHERE s.id = 21450298
  AND s.zone = 'ponightmare'
  AND se.npcID = 7151013;

UPDATE npc_types
SET name = 'Lair of Terris Thule'
WHERE id = 7151013;

UPDATE doors
SET pos_x = 1605, pos_y = 123, pos_z = 217, heading = 20
WHERE id = 6108398
  AND zone = 'ponightmare'
  AND doorid = 61
  AND name = 'POKTELE500'
  AND dest_zone = 'nightmareb'
  AND guild_zone_door = 1;

SELECT s.id AS spawn_id, s.zone, s.x, s.y, s.z, s.heading
FROM spawn2 AS s
WHERE s.id = 21450298 AND s.zone = 'ponightmare';

SELECT id AS door_row_id, zone, doorid, pos_x, pos_y, pos_z, heading,
       dest_zone, dest_x, dest_y, dest_z, dest_heading, guild_zone_door
FROM doors
WHERE id = 6108398 AND zone = 'ponightmare';
