-- REQUIRED: APPLY THIS SQL MANUALLY to the intended game database.
-- Merging this PR does not apply the database changes. Validate on TEST first.
-- No server rebuild required. Refresh affected loot caches or restart affected
-- zones after applying. Existing spawned NPC loot is not regenerated.
-- Obsidianwood Sap (29495): increase the existing Plane of Fire spider drop
-- from 5% to 9%. Only the item chance changes; parent probabilities, other
-- items, multipliers, and all other loot settings remain unchanged.
-- The local snapshot links lootdrop 115556 to tables 6180, 6099, 6737, 87714.
-- Re-running is safe. The 5% guard preserves any different custom chance.

UPDATE lootdrop_entries
SET chance = 9
WHERE lootdrop_id = 115556
  AND item_id = 29495
  AND chance = 5;

-- Verify the item chance is 9; inspect parent probabilities without changing them.
SELECT le.lootdrop_id, le.item_id, le.chance,
       lt.loottable_id, lt.probability AS parent_probability
FROM lootdrop_entries le
JOIN loottable_entries lt ON lt.lootdrop_id = le.lootdrop_id
WHERE le.lootdrop_id = 115556 AND le.item_id = 29495
ORDER BY lt.loottable_id;
