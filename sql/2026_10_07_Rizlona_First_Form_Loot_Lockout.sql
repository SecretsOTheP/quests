-- Remove only Rizlona's first-form loot lockout (NPC 212026).
-- Killing this form spawns dragon 212407. If the dragon's idle timer expires,
-- its script returns the first form ten minutes later; a 66-hour first-form
-- lockout would prevent the same players from retrying.
-- Keep dragon 212407's 66-hour reward lockout and all spawn/retry timers.
-- Back up affected rows first; content tables may be MyISAM. Fresh zone/client
-- loads are needed to refresh cached NPC definitions and character lockouts.

START TRANSACTION;

UPDATE npc_types
SET loot_lockout = 0
WHERE id = 212026;

-- Clear every existing first-form character record, including expired entries.
-- No character, guild or expiry filter. Dragon records are unchanged.
DELETE FROM character_loot_lockouts
WHERE npctype_id = 212026;

COMMIT;

SELECT id, name, loot_lockout,
       instance_spawn_timer_override / 3600000 AS override_hours
FROM npc_types
WHERE id IN (212026, 212407)
ORDER BY id;

SELECT COUNT(*) AS first_form_character_lockouts_remaining
FROM character_loot_lockouts
WHERE npctype_id = 212026;
