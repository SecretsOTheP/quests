-- Quintessence completes the progression leading to Time, not Time admission
-- itself. The Innovation machine still grants time/219/223 through its normal path.
local M = {};
local QUINTESSENCE = 29165;
local FLAGS = {
    { "mavuin", "3" }, { "fuirstel", "5" }, { "thelin", "4" },
    { "poi_door", "1" }, { "zeks", "7" }, { "aerindar", "2" },
    { "tylis", "2" }, { "hohtrials", "111" }, { "cipher", "1" },
    { "grummus", "1" }, { "sol_room", "11111" }, { "zebuxoruk", "2" },
    { "pofire", "2" }, { "bertox_key", "1" }, { "earthb_key", "1" }
};
-- Cipher and Zebuxoruk are the completed forms of these intermediate flags.
local OBSOLETE = {
    "mmarr", "saryrn", "mmarr_book", "karana",
    "cl_grummus", "cl_maze", "cl_behemoth", "cl_aerindar", "cl_terris",
    "cl_bertox", "cl_keeper", "cl_saryrn", "cl_vallon", "cl_tallon",
    "cl_rallos", "cl_karana", "cl_mmarr", "cl_mmarr_book", "cl_solusek"
};
-- Earlier progression zones, including HoH B, Nightmare B and Earth B.
local ZONES = { 200, 207, 208, 209, 210, 211, 212, 214, 215, 216, 217, 218, 220, 221, 222 };

function M.HasQuintessence(client)
    -- Match Muon's existing carried-item check: worn/main inventory, cursor,
    -- and their bags. A banked item or four uncombined components do not qualify.
    for slot = 0, 30 do
        if client:GetItemIDAt(slot) == QUINTESSENCE then return true; end
    end
    for slot = 250, 339 do
        if client:GetItemIDAt(slot) == QUINTESSENCE then return true; end
    end
    return false;
end

function M.Complete(client, qglobals)
    if not M.HasQuintessence(client) then return false; end
    qglobals = qglobals or eq.get_qglobals(client);
    local changed = false;
    for _, flag in ipairs(FLAGS) do
        if qglobals[flag[1]] ~= flag[2] then
            eq.set_global(flag[1], flag[2], 5, "F");
            qglobals[flag[1]] = flag[2];
            changed = true;
        end
    end
    for _, name in ipairs(OBSOLETE) do
        if qglobals[name] then
            eq.delete_global(name);
            qglobals[name] = nil;
            changed = true;
        end
    end
    for _, zone in ipairs(ZONES) do
        if not client:HasZoneFlag(zone) then
            client:SetZoneFlag(zone);
            changed = true;
        end
    end
    if changed then
        client:Message(15, "The Quintessence of Elements completes your earlier planar progression. Activate the machine in the Plane of Innovation to attune yourself to the Plane of Time.");
    end
    return true;
end

return M;
