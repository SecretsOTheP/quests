-- Hope Stone: halve the shared drop roll from 25% to 12.5% and enforce NO DROP.
-- In this item schema, nodrop=0 means NO DROP; 255 means tradable.
-- The shared item definition applies to existing copies when item data is
-- refreshed and inventories/banks/corpses are loaded with the new definition.
-- No per-character inventory rewrite, item deletion or quest changes.
-- Back up affected rows first; content tables may be MyISAM.
-- Refresh item data and affected zone loot caches after applying. Quest reload
-- alone does not refresh these caches. NPC loot already rolled stays rolled.

UPDATE items SET nodrop = 0
WHERE id = 16258 AND Name = 'Hope Stone';

-- Fixed target plus old-value guard prevents repeated application halving again.
-- This drop contains only Hope Stone; linked tables have no forced minimum.
UPDATE lootdrop_entries SET chance = 12.5
WHERE lootdrop_id = 90402 AND item_id = 16258
  AND chance IN (25, 12.5);

SELECT id, Name, nodrop,
       CASE WHEN nodrop = 0 THEN 'NO DROP' ELSE 'TRADABLE' END AS item_flag
FROM items WHERE id = 16258;
SELECT lootdrop_id, item_id, chance, multiplier, item_charges
FROM lootdrop_entries WHERE item_id = 16258;

-- Check runtime-policy overrides before deploying to another realm.
SELECT rule_name, rule_value FROM rule_values
WHERE rule_name IN ('Items:DisableNoDrop', 'World:FVNoDropFlag');
SELECT varname, value FROM variables WHERE varname = 'disablenodrop';
