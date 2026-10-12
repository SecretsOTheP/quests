-- Library landing teleports. Replies are private, like the Timekeeper's.
local function tell(client, text)
    client:Message(0, 'Mork says, "' .. text .. '"');
end

local function nearby(e)
    local dx = e.other:GetX() - e.self:GetX();
    local dy = e.other:GetY() - e.self:GetY();
    local dz = e.other:GetZ() - e.self:GetZ();
    return dx * dx + dy * dy + dz * dz <= 10000;
end

function event_say(e)
    if not nearby(e) then return; end
    local message = e.message:lower():match("^%s*(.-)%s*$");

    if message == "down" then
        tell(e.other, "Mind yer head. I'm movin' the downstairs. Don't slip on the puddle down there. Last test got the soup downstairs before the bowl. Still waitin' on the bowl.");
        e.other:MovePC(202, 949, 17, 3.4, 157);
    elseif message == "hail" or message:match("^hail[%s,]") then
        tell(e.other, "Gork does theoretical physics. That means he thinks of things for me to stand next to when they explode. I do applied physics. That means I build 'em, fix 'em, an' explain the scorch marks.");
        tell(e.other, "People kept pressin' the lift buttons while other people were still inside. I calculated the safest solution: stop givin' people buttons.");
        tell(e.other, "Say [DOWN] an' I'll fold the lower landing under yer boots. No buttons. No waitin'. Ask about [physics] or our [plans] if you want the details.");
    elseif message == "physics" then
        tell(e.other, "Space is mostly empty. Wasteful. Fold the empty bit away an' you're already there. Like closin' a book, except you're the bookmark. The librarians asked for proof. I sent 'em downstairs.");
    elseif message == "plans" then
        tell(e.other, "Gork wants every shelf within arm's reach. I'm buildin' a little version first. Gnomish gears, a mana crystal, an' two cupboards. Put lunch in one, fetch it from the other. If the sandwich arrives before I make it, we're onto somethin'.");
        tell(e.other, "First test is a rat from Oggok. Count the legs before, count 'em after. Same number? Success! Different number? Write it down an' don't let Gork call it an improvement. Librarians said no rats. Apparently givin' one a research title doesn't change that.");
    elseif message == "up" then
        tell(e.other, "You're already upstairs. Further up is the roof. Say [DOWN] unless you plan to become architecture.");
    end
end

function event_trade(e)
    if require("items").return_items(e.self, e.other, e.trade, false) then
        tell(e.other, "Keep yer bits an' coins. This ain't a shop. Say [DOWN] an' let a professional bend space.");
    end
end
