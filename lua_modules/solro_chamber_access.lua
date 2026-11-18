-- Internal chamber access uses mini/Rallos flags, not the tower's zone flag.
local M = {};

function M.HasFlags(qglobals)
    return qglobals.sol_room == "11111" and qglobals.zeks == "7";
end

function M.CanRaidWill(client)
    if eq.get_data("pop_alt_access_enabled") ~= "1" then return false; end
    local raid = client:GetRaid();
    if not raid or not raid.valid or not raid:IsRaidMember(client:GetName()) then
        return false;
    end

    -- Match the native percentage setting (atoi parsing, default 85).
    local configured = eq.get_data("pop_raid_flagged_percent") or "";
    local percent = tonumber(configured:match("^%s*([+-]?%d+)")) or 0;
    if percent < 1 or percent > 100 then percent = 85; end

    -- Count the entire roster in the denominator. Lua only exposes clients in
    -- this zone: absent members cannot supply flags or shrink the denominator.
    local total = raid:RaidCount();
    if total <= 0 then return false; end
    local qualified = 0;
    for i = 0, 71 do
        local member = raid:GetMember(i);
        if member and member.valid and M.HasFlags(eq.get_qglobals(member)) then
            qualified = qualified + 1;
        end
    end
    return qualified * 100 >= total * percent;
end

return M;
