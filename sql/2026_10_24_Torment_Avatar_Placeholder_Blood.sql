-- REQUIRED: APPLY THIS SQL MANUALLY to the intended game database.
-- Merging this PR does not apply the database changes. Validate on TEST first.
-- No server rebuild required. Refresh affected NPC loot caches or restart the
-- affected zone after applying; existing spawned NPC loot is not regenerated.
-- Reuses the 2026_10_17 blood tables if present; already-covered NPCs are unchanged.
-- Applies to these NPC definitions wherever they spawn, not only avatar locations.
-- Item 26635: Putrescent Blood. One independent 7% roll, one item maximum.
-- Existing flayed horror / skinless creature drop remains 5%.
-- Add to the nine placeholder NPC definitions in the Agony, Anguish,
-- Pain and Suffering avatar spawn groups. Keep all current blood sources.
-- These share the source creatures' model, not their bodytype (24 vs 3).
-- Clone table 3699: it is also used by summoned adds, which must stay unchanged.
-- Run once at a time. Re-running preserves existing rows and avoids duplicate rolls.
-- Database tables are MyISAM; this file does not claim transactional rollback.

SET @blood_drop_name = 'potorment_putrescent_blood_26635';
SET @blood_table_name = 'potorment_constructs_putrescent_blood_26635';

INSERT INTO lootdrop (name,min_expansion,max_expansion,content_flags,content_flags_disabled)
SELECT @blood_drop_name,min_expansion,max_expansion,content_flags,content_flags_disabled
FROM lootdrop WHERE id=96885
AND NOT EXISTS (SELECT 1 FROM lootdrop existing WHERE existing.name=@blood_drop_name);
SET @blood_drop_id = (SELECT MIN(id) FROM lootdrop WHERE name=@blood_drop_name);

INSERT INTO lootdrop_entries
 (lootdrop_id,item_id,item_charges,equip_item,chance,minlevel,maxlevel,multiplier,
  disabled_chance,min_expansion,max_expansion,min_looter_level,item_loot_lockout_timer,
  content_flags_disabled,content_flags)
SELECT @blood_drop_id,item_id,item_charges,equip_item,7,minlevel,maxlevel,multiplier,
       disabled_chance,min_expansion,max_expansion,min_looter_level,item_loot_lockout_timer,
       content_flags_disabled,content_flags
FROM lootdrop_entries WHERE lootdrop_id=96885 AND item_id=26635
AND @blood_drop_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM lootdrop_entries existing WHERE existing.lootdrop_id=@blood_drop_id AND existing.item_id=26635);

INSERT INTO loottable
 (name,mincash,maxcash,avgcoin,done,min_expansion,max_expansion,content_flags,content_flags_disabled)
SELECT @blood_table_name,mincash,maxcash,avgcoin,done,min_expansion,max_expansion,content_flags,content_flags_disabled
FROM loottable WHERE id=3699
AND NOT EXISTS (SELECT 1 FROM loottable existing WHERE existing.name=@blood_table_name);
SET @blood_table_id = (SELECT MIN(id) FROM loottable WHERE name=@blood_table_name);

INSERT INTO loottable_entries (loottable_id,lootdrop_id,multiplier,probability,droplimit,mindrop,multiplier_min)
SELECT @blood_table_id,src.lootdrop_id,src.multiplier,src.probability,src.droplimit,src.mindrop,src.multiplier_min
FROM loottable_entries src WHERE src.loottable_id=3699
AND @blood_table_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM loottable_entries existing WHERE existing.loottable_id=@blood_table_id AND existing.lootdrop_id=src.lootdrop_id);

INSERT INTO loottable_entries (loottable_id,lootdrop_id,multiplier,probability,droplimit,mindrop,multiplier_min)
SELECT @blood_table_id,@blood_drop_id,multiplier,probability,droplimit,mindrop,multiplier_min
FROM loottable_entries WHERE loottable_id=91732 AND lootdrop_id=96885
AND @blood_table_id IS NOT NULL AND @blood_drop_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM loottable_entries existing WHERE existing.loottable_id=@blood_table_id AND existing.lootdrop_id=@blood_drop_id);

UPDATE npc_types SET loottable_id=@blood_table_id
WHERE id IN (207009,207041,207043,207218,207282,207286,207288,207290,207294)
AND race=281 AND bodytype=24 AND loottable_id=3699
AND @blood_table_id IS NOT NULL
AND EXISTS (SELECT 1 FROM loottable_entries t JOIN lootdrop_entries d ON d.lootdrop_id=t.lootdrop_id
            WHERE t.loottable_id=@blood_table_id AND d.item_id=26635
              AND t.multiplier=1 AND t.probability=100 AND t.droplimit=0 AND t.mindrop=0
              AND d.chance=7 AND d.multiplier=1);

-- Expected: nine selected NPCs, chance 7, probability 100, both multipliers 1.
SELECT n.id,n.name,n.loottable_id,d.chance,t.probability,t.multiplier AS table_multiplier,d.multiplier AS item_multiplier
FROM npc_types n JOIN loottable_entries t ON t.loottable_id=n.loottable_id
JOIN lootdrop_entries d ON d.lootdrop_id=t.lootdrop_id
WHERE n.id IN (207009,207041,207043,207218,207282,207286,207288,207290,207294) AND d.item_id=26635;

-- Expected: all three remain on 3699, with no newly added blood roll.
SELECT id,name,loottable_id FROM npc_types WHERE id IN (207295,207306,207308);
