-- Restore missing headers for two existing elemental instrument lootdrops.
-- Azobian, Javonn, Reaxnous and Hebabbilys already use loottable 87723,
-- which rolls lootdrop 217425 twice at 10%; item 27996 has a 100% entry.
-- Peregrin Rockskull uses loottable 4478 with the same two 10% rolls for
-- lootdrop 218374 / War Drums of the Rathe (27998).
-- Without these headers, the server skips the lootdrops entirely.
-- Insert only when each existing item mapping is present. Preserve any
-- existing header and all drop rates, items, NPC assignments and timers.
-- Apply to the content database, then refresh affected zone loot caches
-- before new event NPCs spawn. Quest reload alone does not reload loot.

INSERT INTO lootdrop
    (id, name, min_expansion, max_expansion, content_flags, content_flags_disabled)
SELECT 217425, 'Fennin event - Blaring Horn of Fire', -1, -1, NULL, NULL
FROM DUAL
WHERE EXISTS (
    SELECT 1
    FROM loottable_entries AS t
    JOIN lootdrop_entries AS e ON e.lootdrop_id = t.lootdrop_id
    WHERE t.loottable_id = 87723
      AND t.lootdrop_id = 217425
      AND e.item_id = 27996
)
AND NOT EXISTS (SELECT 1 FROM lootdrop WHERE id = 217425);

INSERT INTO lootdrop
    (id, name, min_expansion, max_expansion, content_flags, content_flags_disabled)
SELECT 218374, 'Peregrin Rockskull - War Drums of the Rathe', -1, -1, NULL, NULL
FROM DUAL
WHERE EXISTS (
    SELECT 1
    FROM loottable_entries AS t
    JOIN lootdrop_entries AS e ON e.lootdrop_id = t.lootdrop_id
    WHERE t.loottable_id = 4478
      AND t.lootdrop_id = 218374
      AND e.item_id = 27998
)
AND NOT EXISTS (SELECT 1 FROM lootdrop WHERE id = 218374);

-- Verify both complete links. A missing header after these statements means
-- the expected mapping was absent and requires inspection.
SELECT d.id AS lootdrop_id, d.name, t.loottable_id,
       t.multiplier AS table_rolls, t.probability AS chance_per_roll,
       e.item_id, e.chance AS item_chance, e.multiplier AS item_multiplier
FROM loottable_entries AS t
JOIN lootdrop AS d ON d.id = t.lootdrop_id
JOIN lootdrop_entries AS e ON e.lootdrop_id = d.id
WHERE (t.loottable_id = 87723 AND d.id = 217425 AND e.item_id = 27996)
   OR (t.loottable_id = 4478 AND d.id = 218374 AND e.item_id = 27998)
ORDER BY d.id;
