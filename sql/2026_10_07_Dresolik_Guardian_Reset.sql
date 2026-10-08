-- One-time reset for ONLY the four Guardians of Dresolik (NPC 212046).
-- Run once; rerunning will also clear Guardian cooldowns earned after this reset.
-- Unload affected Sol Ro Tower instances before applying, then load them fresh
-- so cached NPC definitions, character loot lockouts and spawn timers refresh.
-- Quest reload alone does not replace native spawn countdowns.
-- Future Guardian respawns stay at their existing 66-hour cycle.
-- Guild 1 raid respawns remain controlled by earthquakes.

START TRANSACTION;

-- Prevent new Guardian loot lockouts. The Protector is a different NPC type.
UPDATE npc_types
SET loot_lockout = 0
WHERE id = 212046;

-- Clear EVERY character's Guardian record, including expired entries.
-- Deliberately no character, guild or expiry filter.
DELETE FROM character_loot_lockouts
WHERE npctype_id = 212046;

-- Clear only the four verified Guardian spawnpoints, in all ordinary guild
-- instances and open world. Keep Guild 1's earthquake admission state intact.
DELETE rt FROM respawn_times AS rt
JOIN spawn2 AS s ON s.id = rt.id
JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID
WHERE rt.id IN (367793, 367794, 367795, 367796)
  AND rt.guild_id <> 1
  AND s.zone = 'solrotower'
  AND se.npcID = 212046;

COMMIT;

-- Both counts should be zero; Guild 1 timers are intentionally excluded.
SELECT
    (SELECT loot_lockout FROM npc_types WHERE id = 212046)
        AS guardian_future_loot_lockout_seconds,
    (SELECT COUNT(*) FROM character_loot_lockouts WHERE npctype_id = 212046)
        AS guardian_character_lockouts_remaining,
    (SELECT COUNT(*)
       FROM respawn_times AS rt
       JOIN spawn2 AS s ON s.id = rt.id
       JOIN spawnentry AS se ON se.spawngroupID = s.spawngroupID
      WHERE rt.id IN (367793, 367794, 367795, 367796)
        AND rt.guild_id <> 1
        AND s.zone = 'solrotower'
        AND se.npcID = 212046)
        AS guardian_respawn_timers_remaining;
