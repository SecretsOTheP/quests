-- Call once per confirmed objective. Completion belongs to the successful
-- phase transition, so small waves never announce 90% and 100% together.
local M = {};

function M.announce(count, total, halfway, nearlyDone)
    if count >= total then return; end
    if count == math.ceil(total * 0.5) then
        eq.zone_emote(13, halfway);
    elseif nearlyDone and count == math.ceil(total * 0.9) then
        eq.zone_emote(13, nearlyDone);
    end
end

return M;
