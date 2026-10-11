-- Increase each Torment Screaming Sphere avatar from 15% to 45%.
-- Redistribute placeholder weights proportionally (rounded to integers),
-- keeping each group at 100%. Respawn intervals and guaranteed orb drops stay
-- unchanged. Back up spawnentry rows before applying; refresh spawn-group
-- caches in affected zones afterward.
CREATE TEMPORARY TABLE torment_key_spawn_weights (
    group_id INT NOT NULL,
    npc_id INT NOT NULL,
    old_chance INT NOT NULL,
    new_chance INT NOT NULL,
    PRIMARY KEY (group_id, npc_id)
);
INSERT INTO torment_key_spawn_weights VALUES
    (225595,207313,15,45), -- Avatar of Agony
    (225595,207009,42,27),
    (225595,207282,43,28),
    (225594,207314,15,45), -- Avatar of Anguish
    (225594,207288,42,27),
    (225594,207043,43,28),
    (207041,207315,15,45), -- Avatar of Pain
    (207041,207041,42,27),
    (207041,207286,43,28),
    (225596,207316,15,45), -- Avatar of Suffering
    (225596,207218,22,14),
    (225596,207290,23,15),
    (225596,207294,40,26);

-- Fixed targets and known-value guards make reapplication idempotent.
UPDATE spawnentry AS se
JOIN torment_key_spawn_weights AS w
  ON w.group_id = se.spawngroupID AND w.npc_id = se.npcID
SET se.chance = w.new_chance
WHERE se.chance IN (w.old_chance, w.new_chance);

SELECT se.spawngroupID, se.npcID, n.name, se.chance
FROM spawnentry AS se
JOIN npc_types AS n ON n.id = se.npcID
WHERE se.spawngroupID IN (225595,225594,207041,225596)
ORDER BY se.spawngroupID,se.npcID;
SELECT spawngroupID,SUM(chance) AS total_chance
FROM spawnentry
WHERE spawngroupID IN (225595,225594,207041,225596)
GROUP BY spawngroupID;
DROP TEMPORARY TABLE torment_key_spawn_weights;
