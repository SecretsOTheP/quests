-- Use the native policy: enabled toggle, configured percentage, destination flags.
-- Older binaries fail closed until the matching Server update is deployed.
local M = {};
function M.CanEnter(client, zone_id)
    return client.CanRaidWillIntoPopZone ~= nil and client:CanRaidWillIntoPopZone(zone_id);
end
return M;
