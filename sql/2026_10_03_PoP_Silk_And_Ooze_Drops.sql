-- Correct the reversed PoDisease ooze and PoNightmare spider crafting drops.
-- Preserve all other loot entries and the existing chances (8% / 10%).
-- Guard on the old item IDs so rerunning this does not flip them back.
UPDATE lootdrop_entries
SET item_id = 28282 -- Congealed Bile-based Ooze
WHERE lootdrop_id = 22937
  AND item_id = 28281;

UPDATE lootdrop_entries
SET item_id = 28281 -- Creeping Silk Strands
WHERE lootdrop_id = 23779
  AND item_id = 28282;

-- Verify corrected items and retained chances.
SELECT lootdrop_id, item_id, chance
FROM lootdrop_entries
WHERE (lootdrop_id = 22937 AND item_id = 28282)
   OR (lootdrop_id = 23779 AND item_id = 28281)
ORDER BY lootdrop_id;
