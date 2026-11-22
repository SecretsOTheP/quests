-- Additional travel mobs only; ring controllers retain their own event logic.
local Spawns=require("air_trash_spawns");
local Trash=require("air_trash_retention");
local trackers,points={},{};
local TIMER="air_travel_trash";
local CONTROLLER=215419;
local function tracker(group)
    if not trackers[group] then trackers[group]=Trash.new(group); end
    return trackers[group];
end
local function pulse()
    for group,ids in pairs(points) do
        local t=tracker(group);t:Refresh();t:ReleaseExpired(ids);
        for _,id in ipairs(ids) do
            local spawn=eq.get_entity_list():GetSpawnByID(id);
            if spawn and spawn.valid then t:Suppress(spawn:GetNPC()); end
        end
    end
end
local function start(e)
    eq.set_timer(TIMER,1000,e.self);
end
local function spawned(e)
    local group=Spawns.extra[e.self:GetSpawnPointID()];
    if group then local t=tracker(group);t:Refresh();t:Suppress(e.self); end
end
local function died(e)
    local id=e.self:GetSpawnPointID();local group=Spawns.extra[id];
    -- Castellans record in their individual script before signaling their controller.
    if group and group~="castellan" then tracker(group):Record(id); end
end
function event_encounter_load(e)
    if eq.get_zone_guild_id()<=1 then return; end
    for id,group in pairs(Spawns.extra) do
        points[group]=points[group] or {};table.insert(points[group],id);
    end
    for _,id in ipairs(Spawns.npc_types) do
        eq.register_npc_event("TravelTrash",Event.spawn,id,spawned);
        eq.register_npc_event("TravelTrash",Event.death_complete,id,died);
    end
    eq.register_npc_event("TravelTrash",Event.spawn,CONTROLLER,start);
    eq.register_npc_event("TravelTrash",Event.timer,CONTROLLER,function(e)
        if e.timer==TIMER then pulse();eq.set_timer(TIMER,30000,e.self); end
    end);
    for _,id in ipairs({215411,215410}) do
        eq.register_npc_event("TravelTrash",Event.death_complete,id,function() eq.signal(CONTROLLER,5); end);
    end
    local controller=eq.get_entity_list():GetNPCByNPCTypeID(CONTROLLER);
    if controller and controller.valid then start({self=controller}); end
end
