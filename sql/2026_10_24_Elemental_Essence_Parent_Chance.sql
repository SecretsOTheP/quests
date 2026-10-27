-- REQUIRED: APPLY THIS SQL MANUALLY to the intended game database.
-- Merging this PR does not apply the database changes. Validate on TEST first.
-- No server rebuild required. Refresh affected loot caches or restart affected
-- zones after applying. Existing spawned NPC loot is not regenerated.
-- Complements EQMacEmu PR #425, which sets the item-level chance to 100%.
-- Only these four parent probabilities change; all other loot fields stay intact.
-- Re-running is safe: each matching parent remains at 100%.

UPDATE loottable_entries
SET probability = 100
WHERE (loottable_id = 4250 AND lootdrop_id = 90126)   -- Xegony: Wind
   OR (loottable_id = 4258 AND lootdrop_id = 8176)    -- Coirnav: Water
   OR (loottable_id = 87722 AND lootdrop_id = 23569)  -- Fennin Ro: Fire
   OR (loottable_id = 87627 AND lootdrop_id = 115539); -- Avatar of Earth: Earth

-- Verify: four parent rows, each with probability 100.
SELECT loottable_id, lootdrop_id, probability,
       multiplier, multiplier_min, droplimit, mindrop
FROM loottable_entries
WHERE (loottable_id = 4250 AND lootdrop_id = 90126)
   OR (loottable_id = 4258 AND lootdrop_id = 8176)
   OR (loottable_id = 87722 AND lootdrop_id = 23569)
   OR (loottable_id = 87627 AND lootdrop_id = 115539)
ORDER BY loottable_id, lootdrop_id;
