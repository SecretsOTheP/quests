-- Let codecay/player.lua enforce bertox_key and handle the throne teleport.
-- Deploy the Lua with this SQL and restart loaded Codecay zone processes.
UPDATE doors
SET dest_zone = 'NONE', dest_x = 0, dest_y = 0, dest_z = 0, dest_heading = 0
WHERE zone = 'codecay' AND doorid = 7 AND name = 'CDTHRONE501';
