local module = {}

local PROTECTED_ITEMS = {
    [29112] = true, -- Ethereal Parchment
    [29131] = true, -- Spectral Parchment
    [29132] = true  -- Glyphed Rune Word
}

-- Clean NPC names from the existing PoK spell turn-in scripts.
local SPELL_VENDORS = {
    ["Cavalier Waut"] = true,
    ["Channeler Olaemos"] = true,
    ["Elementalist Somat"] = true,
    ["Heretic Drahur"] = true,
    ["Illusionist Jerup"] = true,
    ["Minstrel Eoweril"] = true,
    ["Mystic Abomin"] = true,
    ["Pathfinder Viliken"] = true,
    ["Primalist Saosith"] = true,
    ["Reaver Nydlil"] = true,
    ["Vicar Ceraen"] = true,
    ["Wanderer Astobin"] = true
}

-- Call first in an NPC's event_trade, before consuming or returning items:
-- require("knowledge_protection_trade").ReturnProtectedItems(e)
-- Continue the existing trade handler afterward for unrelated items and coins.
-- This module does not register an event handler by itself.
function module.ReturnProtectedItems(e)
    if eq.get_zone_short_name() ~= "poknowledge" then
        return false;
    end

    if SPELL_VENDORS[e.self:GetCleanName()] then
        return false;
    end

    local returned = false;
    for slot = 1, 4 do
        local field = "item" .. slot;
        local item = e.trade[field];
        if item and item.valid and PROTECTED_ITEMS[item:GetID()] then
            -- Force the original quantity when returning a stack to the quest cursor.
            e.other:SummonItem(item:GetID(), item:GetCharges(), 9999, true);
            -- Existing quest/return handlers must not process this item again.
            e.trade[field] = nil;
            returned = true;
        end
    end

    if returned then
        e.other:Message(13, "What am I supposed to do with this? Take it to someone who knows about such things.");
    end

    return returned;
end

return module
