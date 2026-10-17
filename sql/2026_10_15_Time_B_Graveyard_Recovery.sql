-- Plane of Time B: normal corpse recovery after 30 minutes.
-- Requires the existing Time B graveyard; does not create or repoint it.
-- This shared zone setting applies to public and guild copies of Time B.
-- Guild 1 retains its separate PVPInstanceGraveyardTime rule (default 30).
UPDATE zone AS z
JOIN graveyard AS g ON g.id = z.graveyard_id AND g.zone_id = 223
SET z.graveyard_time = 30
WHERE z.zoneidnumber = 223 AND z.short_name = 'potimeb';
