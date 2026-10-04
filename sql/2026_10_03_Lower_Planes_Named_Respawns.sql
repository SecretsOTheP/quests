-- Set the selected lower-plane named/event spawn points to 24 hours.
-- Aerin Dar, The Seventh Hammer, and Manaetic Behemoth remain unchanged at 66 hours.
-- Preserve variance and realm/raid access rules. Does not clear saved countdowns.
-- Aramin already uses 24 hours. The crawler shares its spawn point with placeholders.

-- Banord Paffa
UPDATE spawn2 SET respawntime = 86400
WHERE id = 360632 AND zone = 'codecay' AND respawntime IN (259200, 86400);

-- Spectre of Corruption
UPDATE spawn2 SET respawntime = 86400
WHERE id = 360643 AND zone = 'codecay' AND respawntime IN (237600, 86400);

-- Carprin Deatharn
UPDATE spawn2 SET respawntime = 86400
WHERE id = 360642 AND zone = 'codecay' AND respawntime IN (237600, 86400);

-- Aramin the Spider Guardian (already 24 hours)
UPDATE spawn2 SET respawntime = 86400
WHERE id = 344766 AND zone = 'podisease' AND respawntime IN (86400, 86400);

-- Grummus
UPDATE spawn2 SET respawntime = 86400
WHERE id = 344762 AND zone = 'podisease' AND respawntime IN (237600, 86400);

-- Rallius Rattican
UPDATE spawn2 SET respawntime = 86400
WHERE id = 344765 AND zone = 'podisease' AND respawntime IN (259200, 86400);

-- Manaetic Prototype IX
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345148 AND zone = 'poinnovation' AND respawntime IN (259200, 86400);

-- Manaetic Prototype X
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345147 AND zone = 'poinnovation' AND respawntime IN (259200, 86400);

-- Manaetic Prototype XI
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345149 AND zone = 'poinnovation' AND respawntime IN (259200, 86400);

-- Ancient crawler shared spawn, including its placeholders
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345473 AND zone = 'pojustice' AND respawntime IN (237600, 86400);

-- Terror Matriarch
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345905 AND zone = 'ponightmare' AND respawntime IN (259200, 86400);

-- The Bullyrag Bat
UPDATE spawn2 SET respawntime = 86400
WHERE id = 369184 AND zone = 'ponightmare' AND respawntime IN (604800, 86400);

-- Seilaen
UPDATE spawn2 SET respawntime = 86400
WHERE id = 346307 AND zone = 'ponightmare' AND respawntime IN (259200, 86400);

-- Untel Dak
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345919 AND zone = 'ponightmare' AND respawntime IN (259200, 86400);

-- Vhaksiz the Shade
UPDATE spawn2 SET respawntime = 86400
WHERE id = 345916 AND zone = 'ponightmare' AND respawntime IN (259200, 86400);

-- The Sleep Walker (all three NPC versions)
UPDATE spawn2 SET respawntime = 86400
WHERE id = 364399 AND zone = 'povalor' AND respawntime IN (259200, 86400);

-- Rahlgon
UPDATE spawn2 SET respawntime = 86400
WHERE id = 347213 AND zone = 'povalor' AND respawntime IN (345600, 86400);

-- Verify the selected spawn points.
SELECT id, zone, respawntime, variance FROM spawn2
WHERE id IN (360632, 360643, 360642, 344766, 344762, 344765, 345148, 345147, 345149, 345473, 345905, 369184, 346307, 345919, 345916, 364399, 347213) ORDER BY zone, id;

-- BoT named: six hours -> three hours. Only the six-hour Eindride spawn.
-- Leave Agnarr, Emmerik, Evynd, and the separate fast Eindride spawn unchanged.
UPDATE spawn2 SET respawntime = 10800
WHERE zone = 'bothunder'
  AND respawntime = 21600
  AND id IN (
    360516, -- Gaukr Sandstorm
    364400, -- Hreidar Lynhillig
    364397, -- Laef Windfall
    364401, -- Oreen Wavecrasher
    360270, -- Auliffe Chaoswind
    360252, -- Brynju Thunderclap
    360610, -- Kuanbyr Hailstorm
    364398  -- Eindride Icestorm
  );

SELECT id, zone, respawntime, variance FROM spawn2
WHERE id IN (360516, 364400, 364397, 364401, 360270, 360252, 360610, 364398)
ORDER BY id;

-- Dolshak is intentionally untouched: Neffiken.lua schedules his spawn
-- 15-60 minutes after Neffiken dies and depops him when Neffiken spawns.
