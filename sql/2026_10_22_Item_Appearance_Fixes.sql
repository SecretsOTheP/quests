-- Correct item icons and weapon appearances.
-- Credit: Kilralpine [TRNQ].

UPDATE items
SET icon = 1288,
    idfile = 'IT10517'
WHERE id = 32605
  AND Name = 'Ossein of Limitless Time';

UPDATE items
SET icon = 1382,
    idfile = 'IT10624'
WHERE id = 23494
  AND Name = 'Obsidian Battle Sword';
