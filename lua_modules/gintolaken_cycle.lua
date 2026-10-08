-- Reuse for the three chieftain groups and Gintolaken. This module writes
-- timers only after new kills; loading it does not change existing cooldowns.
local M = {};
local REUSE_MS = 237600000; -- 66 hours
local GROUPS = {
    [222037] = { boss = 369492, marker = 369489, points = {369438,369439,369440,369441} }, -- Awisano
    [222035] = { boss = 369493, marker = 369487, points = {369442,369443,369444,369445} }, -- Birak
    [222036] = { boss = 369494, marker = 369488, points = {369446,369447,369448,369449} }, -- Galronar
};

local function ResetGroup(group)
    -- Set every member: an earlier individual respawn would wake the whole group.
    for _, id in ipairs(group.points) do
        eq.update_spawn_timer(id, REUSE_MS);
    end
end

function M.GroupCleared(boss_type)
    ResetGroup(assert(GROUPS[boss_type]));
end

function M.ChieftainKilled(boss_type)
    local group = assert(GROUPS[boss_type]);
    local point = eq.get_entity_list():GetSpawnByID(group.marker);
    if point and point.valid then
        local npc = point:GetNPC();
        if npc and npc.valid then npc:Depop(true);end
    end
    -- Persist the marker's explicit timer as well as the four prerequisite
    -- timers, starting from the same kill that awards the boss loot lockout.
    eq.update_spawn_timer(group.marker, REUSE_MS);
    ResetGroup(group);
end

function M.GintolakenKilled()
    for _, group in pairs(GROUPS) do
        ResetGroup(group);
        eq.update_spawn_timer(group.marker, REUSE_MS);
        -- All chieftains were killed before Gintolaken. Rearm the ordinary
        -- chain from this final kill to begin one shared 66-hour reuse period.
        -- Guild 1 raid spawnpoints keep their native earthquake state.
        if eq.get_zone_guild_id() ~= 1 then
            eq.update_spawn_timer(group.boss, REUSE_MS);
        end
    end
    -- Spawnpoint 369490 is the separate 84-hour Council access window.
end

return M;
