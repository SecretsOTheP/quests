-- Register Plane of Power access keys with the key ring.
-- Key physical doors by zone and door ID; door row IDs vary between databases.

UPDATE doors
SET nokeyring = 0
WHERE (zone = 'poair' AND doorid = 1 AND keyitem = 28638 AND altkeyitem = 0)
   OR (zone = 'poeartha' AND doorid = 7 AND keyitem = 28636 AND altkeyitem = 0)
   OR (zone = 'podisease' AND doorid = 15 AND keyitem = 28999 AND altkeyitem = 0);

-- Correct the existing metadata entry for the Enchanted Ring of Torden.
UPDATE keyring_data
SET key_name = 'Enchanted Ring of Torden', zoneid = 209, stage = 0
WHERE key_item = 9425;

INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 25596, 'A Crystalline Globe', 208, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 25596);

INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 9425, 'Enchanted Ring of Torden', 209, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 9425);

INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 9433, 'Symbol of Torden', 209, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 9433);

INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 28638, 'A Wind Etched Key', 215, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 28638);

INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 28636, 'A Gem-Etched Key', 218, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 28636);

-- One Screaming Sphere (22954) opens Saryrn's tower for the raid. The existing
-- Plane of Torment door and Tylis script already support keyring checks.
INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 22954, 'A Screaming Sphere', 207, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 22954);

-- Gryme's temporary key opens the inner castle door leading to Aramin/Grummus.
INSERT INTO keyring_data (key_item, key_name, zoneid, stage)
SELECT 28999, 'Grymes Crypt Key', 203, 0
WHERE NOT EXISTS (SELECT 1 FROM keyring_data WHERE key_item = 28999);
