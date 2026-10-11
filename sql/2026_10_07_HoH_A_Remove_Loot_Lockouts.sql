-- No NPC loot lockouts anywhere in Halls of Honor A (zone 211).
-- The zone's NPC-type block is 211000-211999. This covers native NPCs and
-- scripted trial waves/bosses, including Rydda'Dar; a spawn2-only join misses
-- the scripted NPCs. All current native/scripted HoH A NPCs were checked.
-- Supersedes 2026_08_19_Halls_of_Honor_Trial_Lockouts.sql.
-- Respawn timers, instance overrides, trial success reuse and failure retries
-- are unchanged. Halls of Honor B (NPC block 220000-220999) is unaffected.
-- Back up affected rows first; content tables may be MyISAM. Fresh zone/client
-- loads are needed to refresh cached NPC definitions and character lockouts.

START TRANSACTION;

UPDATE npc_types
SET loot_lockout = 0
WHERE id BETWEEN 211000 AND 211999;

-- Remove every existing HoH A record, including expired entries and records
-- for old NPC definitions. No character, guild or expiry filter.
DELETE FROM character_loot_lockouts
WHERE npctype_id BETWEEN 211000 AND 211999;

COMMIT;

-- Both remaining-lockout counts must be zero.
SELECT
    (SELECT COUNT(*) FROM npc_types WHERE id BETWEEN 211000 AND 211999)
        AS hohonora_npc_definitions,
    (SELECT COUNT(*) FROM npc_types
      WHERE id BETWEEN 211000 AND 211999 AND loot_lockout <> 0)
        AS hohonora_npcs_with_loot_lockouts,
    (SELECT COUNT(*) FROM character_loot_lockouts
      WHERE npctype_id BETWEEN 211000 AND 211999)
        AS hohonora_character_lockouts_remaining;
