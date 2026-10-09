-- Increase view distance in Plane of Air, Plane of Fire, and both Plane of Earth zones.
-- Load fresh affected zone processes after applying; no server rebuild is required.

UPDATE zone
SET minclip      = 600,
    maxclip      = 1200,
    fog_minclip  = 600,
    fog_maxclip  = 1200,
    fog_minclip2 = 600,
    fog_maxclip2 = 1200,
    fog_minclip3 = 600,
    fog_maxclip3 = 1200,
    fog_minclip4 = 600,
    fog_maxclip4 = 1200
WHERE short_name IN ('poair', 'pofire', 'poeartha', 'poearthb');

-- Verify all four zones and each fog range.
SELECT short_name, minclip, maxclip,
       fog_minclip, fog_maxclip,
       fog_minclip2, fog_maxclip2,
       fog_minclip3, fog_maxclip3,
       fog_minclip4, fog_maxclip4
FROM zone
WHERE short_name IN ('poair', 'pofire', 'poeartha', 'poearthb')
ORDER BY short_name;
