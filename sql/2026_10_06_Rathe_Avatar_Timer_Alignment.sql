-- Avatar is script-spawned; this removes stale 66-hour override metadata.
-- Council's seven-minute native respawns and scripted recovery remain separate.
UPDATE npc_types
SET instance_spawn_timer_override = 496800000
WHERE id = 222040;

SELECT id, name, instance_spawn_timer_override / 3600000 AS override_hours,
       loot_lockout / 3600 AS loot_lockout_hours
FROM npc_types WHERE id = 222040;
