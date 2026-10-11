-- These NPCs are zone-local entities. No content SQL or player data is written.
local ENCOUNTER = "LibraryPhysicists";
local OWNER = "library_physicist_v1";
local encounter;
local warned = {};
local definitions = {
    {id=7151301, name="Gork,_Theoretical_Physicist", short="Gork", face=4, helm=0,
     x=949, y=25, z=3.4, dialogue=require("library_gork")},
    {id=7151302, name="Mork,_Applied_Physicist", short="Mork", face=0, helm=3,
     x=948, y=44, z=389.4, dialogue=require("library_mork")}
};

local function recognized(n, d)
    local name = n:GetCleanName();
    return name == d.name:gsub("_", " ") or name == d.short;
end

local function warn_once(key, text)
    if not warned[key] then
        eq.debug("LibraryPhysicists: " .. text);
        warned[key] = true;
    end
end

local function ensure_npc(d)
    local entities = eq.get_entity_list();
    local matches = {};
    for n in entities:GetNPCList().entries do
        if n.valid and n:GetNPCTypeID() == d.id then
            if not recognized(n, d) then
                warn_once(d.id, "NPC ID " .. d.id .. " belongs to another NPC; setup skipped.");
                return;
            end
            matches[#matches + 1] = n;
        end
    end

    -- Retire only the recognized prototype's loaded spawnpoint, in memory.
    -- Its SQL rows can remain: a fresh zone/repop is reconciled the same way.
    local point = entities:GetSpawnByID(d.id);
    if point.valid and point:SpawnGroupID() == d.id and point:CurrentNPCID() == d.id then
        point:Disable(false);
    end

    local keeper;
    local removed = false;
    for _, n in ipairs(matches) do
        if not keeper and n:GetEntityVariable(OWNER) == "1" then
            keeper = n;
        else
            n:Depop();
            removed = true;
        end
    end
    -- Depop removes entities on the next zone process pass. Wait for that before
    -- creating a replacement, avoiding overlapping entities and duplicate names.
    if keeper or removed then return; end

    local n = eq.create_npc_from_table({
        npc_id=d.id, name=d.name, lastname="", level=65, race=10, gender=0,
        class_=1, bodytype=1, cur_hp=10000, max_hp=10000, Mana=0,
        size=7.5, texture=1, helmtexture=d.helm, luclinface=d.face,
        chesttexture=1, armtexture=1, bracertexture=1, handtexture=1,
        legtexture=1, feettexture=1, hairstyle=255, haircolor=255,
        eyecolor1=255, eyecolor2=255, beardcolor=255, beard=255,
        npc_faction_id=1424, runspeed=0, walkspeed=0,
        special_abilities="14,1^19,1^20,1^24,1^25,1^35,1",
        loottable_id=0, merchanttype=0, npc_spells_id=0, npc_spells_effects_id=0,
        loot_lockout=0, skip_global_loot=true, raid_target=false, qglobal=false
    }, d.x, d.y, d.z, 157);
    if n and n.valid then
        n:SetEntityVariable(OWNER, "1");
    else
        warn_once("create" .. d.id, "Could not create " .. d.short .. "; will retry.");
    end
end

local function reconcile()
    for _, d in ipairs(definitions) do ensure_npc(d); end
end

function event_encounter_load(e)
    -- Do not fall back to the old, unsafe eq.create_npc implementation.
    if type(eq.create_npc_from_table) ~= "function" then
        warn_once("server", "Server update required: eq.create_npc_from_table is unavailable. No automatic NPCs created.");
        return;
    end
    encounter = e.encounter;
    for _, d in ipairs(definitions) do
        local function recognized_callback(callback)
            return function(event)
                -- Keep the recognized SQL prototype usable until reconciliation.
                if recognized(event.self, d) then
                    return callback(event);
                end
            end;
        end
        eq.register_npc_event(ENCOUNTER, Event.say, d.id, recognized_callback(d.dialogue.event_say));
        eq.register_npc_event(ENCOUNTER, Event.trade, d.id, recognized_callback(d.dialogue.event_trade));
    end
    -- Let normal database population finish before checking legacy prototypes.
    eq.set_timer("initialize", 1000, encounter);
    eq.set_timer("maintain", 5000, encounter);
end

function event_timer(e)
    if e.timer == "initialize" then
        eq.stop_timer("initialize", encounter);
        reconcile();
    elseif e.timer == "maintain" then
        reconcile();
    end
end
