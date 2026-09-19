local module = {}

local TURN_IN_ITEMS = {
    [29112] = true, -- Ethereal Parchment
    [29131] = true, -- Spectral Parchment
    [29132] = true  -- Glyphed Rune Word
}

-- Reject stacks and multiple turn-in items before the normal quest code consumes anything.
function module.RejectMultipleTurnIns(e)
    local turn_in_count = 0;

    for slot = 1, 4 do
        local item = e.trade["item" .. slot];
        if ( item and item.valid and TURN_IN_ITEMS[item:GetID()] ) then
            if ( item:GetCharges() > 1 ) then
                e.other:Message(15, "Please separate a single parchment or rune before handing it to me.");
                return true;
            end

            turn_in_count = turn_in_count + 1;
        end
    end

    if ( turn_in_count > 1 ) then
        e.other:Message(15, "Please hand me only one parchment or rune at a time.");
        return true;
    end

    return false;
end

return module
