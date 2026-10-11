local M = {};
-- Library landing teleports. Replies are private, like the Timekeeper's.
local function tell(client, text)
    client:Message(0, 'Gork says, "' .. text .. '"');
end

local function nearby(e)
    -- EVENT_SAY itself only checks horizontal distance. Do not reach floors above.
    local dx = e.other:GetX() - e.self:GetX();
    local dy = e.other:GetY() - e.self:GetY();
    local dz = e.other:GetZ() - e.self:GetZ();
    return dx * dx + dy * dy + dz * dz <= 10000;
end

function M.event_say(e)
    if not nearby(e) then return; end
    local message = e.message:lower():match("^%s*(.-)%s*$");

    if message == "up" then
        tell(e.other, "Hold still. I'm testin' a theory.");
        -- Player-supplied XYZ landing, not the moving lift platform.
        e.other:MovePC(202, 948, 36, 389.4, 157);
    elseif message == "hail" or message:match("^hail[%s,]") then
        tell(e.other, "Oi, little scholar! Too many fools kept jabbin' the lift buttons. Up, down, up, down. Now the thing's stuck arguin' with itself, with passengers still inside. Librarians call it a mechanical fault. I call it too many fingers.");
        tell(e.other, "Me an' Mork are physicists from Oggok. I think up the theories. Mork stands near 'em when we find out if they work. Very important job. That's why he gets a helmet.");
        tell(e.other, "Say [UP] an' I'll put you on the upper landing. Ask about [physics] or our [plans] if you want the clever bit.");
    elseif message == "physics" then
        tell(e.other, "The gnomes wanted to fix the lift. I asked why we needed the bit between floors at all. So now I fold space. Mork said that was impossible. Mork's upstairs. Work it out.");
    elseif message == "plans" then
        tell(e.other, "Next project: fold the whole library so every shelf's within arm's reach. No stairs. No ladders. No little librarian tellin' me I can't stand on the furniture. Might need bigger arms. Still workin' on the theory.");
        tell(e.other, "Mork wants numbers on the plans. I put MORE next to mana an' BIGGER next to the explodin' bit. Now he wants a safety review. Fine. We'll stand further back.");
    elseif message == "down" then
        tell(e.other, "You're already downstairs. That's the floor under yer boots. Say [UP] if you want the other one.");
    end
end

function M.event_trade(e)
    -- No purchases or quest hand-ins; return everything without public NPC speech.
    if require("items").return_items(e.self, e.other, e.trade, false) then
        tell(e.other, "Keep yer bits an' coins. The library pays us. Say [UP] when you're ready.");
    end
end

return M;
