-- Run from the quests root: lua5.1 tests/quintessence_progression_test.lua
package.path = "./lua_modules/?.lua;" .. package.path;
function string.findi(s, text) return s:lower():find(text:lower(), 1, true); end
local Q = require("quintessence_progression");
local globals, slots, zones, writes, deletes, messages, moves, spawns;
local client = {};
function client:GetItemIDAt(slot) return slots[slot] or 0; end
function client:HasZoneFlag(zone) return zones[zone] or false; end
function client:SetZoneFlag(zone) zones[zone] = true; writes = writes + 1; end
function client:Message(_, text) messages[#messages + 1] = text; end
function client:HasItem(item)
    for _, id in pairs(slots) do if id == item then return true; end end
    return false;
end
function client:MovePC(...) moves[#moves + 1] = {...}; end
local npc = {};
function npc:Say(_) end
function npc:Emote(_) end
local function reset()
    globals, slots, zones, messages, moves, spawns = {}, {}, {}, {}, {}, {};
    writes, deletes = 0, 0;
    eq = {
        get_qglobals = function() local copy = {}; for k,v in pairs(globals) do copy[k]=v; end; return copy; end,
        set_global = function(k,v,options,duration)
            assert(options == 5 and duration == "F"); globals[k]=v; writes=writes+1;
        end,
        delete_global = function(k) globals[k]=nil; deletes=deletes+1; end,
        unique_spawn = function(...) spawns[#spawns+1]={...}; end
    };
end
local expected = {
    mavuin="3", fuirstel="5", thelin="4", poi_door="1", zeks="7", aerindar="2",
    tylis="2", hohtrials="111", cipher="1", grummus="1", sol_room="11111",
    zebuxoruk="2", pofire="2", bertox_key="1", earthb_key="1"
};
local function complete()
    for k,v in pairs(expected) do assert(globals[k]==v, k.." incomplete"); end
    for _,z in ipairs({200,207,208,209,210,211,212,214,215,216,217,218,220,221,222}) do
        assert(zones[z], "missing zone "..z);
    end
end
local function no_time()
    assert(not globals.time and not zones[219] and not zones[223], "Time granted before machine");
end
local function load_say(path, phrase)
    assert(loadfile(path))(); event_say({self=npc,other=client,message=phrase});
end
local function click(id)
    assert(loadfile("poinnovation/player.lua"))();
    event_click_door({self=client,door={GetDoorID=function() return id; end}});
end

-- No item, bank-only item, and uncombined components cannot grant anything.
for _,inv in ipairs({{}, {[2000]=29165}, {[2030]=29165},
    {[22]=29146,[23]=29147,[24]=29163,[25]=29164}}) do
    reset(); slots=inv;
    assert(not Q.Complete(client));
    load_say("poknowledge/Grand_Librarian_Maelin.lua", "hail");
    load_say("poinnovation/#Chronographer_Muon.lua", "yes");
    click(145);
    assert(writes==0 and deletes==0 and #moves==0 and #spawns==0);
end

-- Inventory, cursor, normal bags and cursor bags qualify; no item consumption.
for _,slot in ipairs({22,30,250,339}) do
    reset(); slots[slot]=29165;
    assert(Q.Complete(client)); complete(); no_time(); assert(slots[slot]==29165);
    local before=writes; assert(Q.Complete(client)); assert(writes==before and #messages==1);
end

-- Incomplete/obsolete progression is reconciled without touching unrelated data.
reset(); slots[22]=29165;
globals={aerindar="1",zeks="3",sol_room="01000",hohtrials="101",mmarr="1",saryrn="1",
    mmarr_book="1",karana="4",cl_grummus="1",cl_maze="1",cl_behemoth="1",cl_aerindar="1",
    cl_terris="1",cl_bertox="1",cl_keeper="1",cl_saryrn="1",cl_vallon="1",cl_tallon="1",
    cl_rallos="1",cl_karana="1",cl_mmarr="1",cl_mmarr_book="1",cl_solusek="1",
    seventh="1",time="1",time_instance="55001",time_instance_generation="55001:1234",
    custom_quest="untouched"};
zones[219]=true; zones[223]=true;
Q.Complete(client); complete(); assert(deletes==19);
assert(globals.time=="1" and globals.time_instance=="55001" and globals.time_instance_generation=="55001:1234");
assert(globals.custom_quest=="untouched" and globals.seventh=="1" and zones[219] and zones[223]);
local before=writes; local removed=deletes; Q.Complete(client); assert(before==writes and removed==deletes);

-- Both supported NPC entry points see fresh globals in the same callback.
reset(); slots[22]=29165;
load_say("poknowledge/Grand_Librarian_Maelin.lua", "hail"); complete(); no_time();
assert(messages[#messages]:find("Chronographer Muon",1,true));
reset(); slots[30]=29165;
load_say("poinnovation/#Chronographer_Muon.lua", "hail"); complete(); no_time();
assert(messages[#messages]:find("Acquisition of power completed",1,true));
load_say("poinnovation/#Chronographer_Muon.lua", "yes");
assert(#moves==1 and moves[1][1]==206 and #spawns==1);

-- Machine click can repair missing progression itself and grants Time normally.
reset(); slots[22]=29165; click(145); complete();
assert(globals.time=="1" and zones[219] and zones[223]);
assert(#moves==1 and moves[1][1]==219 and slots[22]==29165);
reset(); slots[22]=29165; click(999); assert(writes==0 and #moves==0);

-- Normal progression/dialogue without the item continues to work.
reset(); globals.mmarr="1"; globals.saryrn="1";
load_say("poknowledge/Grand_Librarian_Maelin.lua", "hail");
assert(globals.cipher=="1" and not globals.mmarr and not globals.saryrn and not globals.zebuxoruk);
reset(); globals.zebuxoruk="2"; slots[22]=29165;
load_say("poinnovation/#Chronographer_Muon.lua", "yes"); assert(#moves==1);

-- Exercise consumers of the completed flags, not just the helper's flag list.
local level, raid, signals, guild, raid_window, timeline;
function client:GetGM() return false; end
function client:GetLevel() return level or 65; end
function client:GetPet() return {valid=false}; end
function client:KeyRingCheck() return false; end
function client:CharacterID() return 123; end
function client:GetRaid() return raid or {valid=false}; end
local function travel_setup()
    level, raid, signals, guild, raid_window, timeline = 65, nil, {}, 42, true, {};
    eq.get_data = function() return "0"; end -- alternate access disabled after attunement
    eq.get_entity_list = function() return {
        IsMobSpawnedByNpcTypeID=function() return false; end,
        RemoveFromHateLists=function() end
    }; end
    eq.get_zone_guild_id = function() return guild; end
    eq.guild_one_raid_window_open = function() return raid_window; end
    eq.signal = function(...) signals[#signals+1]={...}; end
    local original=eq.get_qglobals;
    eq.get_qglobals=function(who,...)
        if type(who)=="number" then return timeline; end
        return original(who,...);
    end;
end
local function door(file,id)
    assert(loadfile(file))();
    event_click_door({self=client,door={GetDoorID=function() return id; end}});
end
reset(); travel_setup(); slots[22]=29165;
load_say("poknowledge/Grand_Librarian_Maelin.lua","hail");
slots={}; -- flags persist without the item and without a raid/85-15 allowance
for _,id in ipairs({16,21,12,93,48,23,24,22,82,81,83,84}) do
    messages={}; door("potranquility/player.lua",id);
    assert(#messages==0,"completed character denied Tranquility door "..id);
end
messages={}; door("potranquility/player.lua",18);
assert(messages[1]:find("lack the will",1,true),"Maelin alone must not grant Time");
messages={};
for _,spec in ipairs({{"povalor/player.lua",3},{"hohonora/player.lua",19},
    {"ponightmare/player.lua",59},{"codecay/player.lua",7},{"solrotower/player.lua",44},
    {"poeartha/player.lua",9}}) do
    door(spec[1],spec[2]);
end
assert(#messages==0,"earlier internal progression gate still blocked");
assert(moves[#moves][1]==222,"Earth B access missing");
local before=writes;
assert(loadfile("poknowledge/Seer_Mal_Nae-Shi.lua"))();
GuidedMeditation(client); UnlockMemories(client);
assert(writes==before and deletes==0,"Seer changed completed flags"); complete(); no_time();

-- Muon -> machine -> permanent Time entry, still enforcing level/raid/locks.
slots[22]=29165;
load_say("poinnovation/#Chronographer_Muon.lua","yes");
assert(moves[#moves][1]==206);
click(145); slots={};
messages={}; door("potranquility/player.lua",18);
assert(messages[1]:find("ages begin",1,true),"permanent Time A admission failed");
assert(globals.time=="1" and zones[219] and zones[223]);
level=64; messages={}; door("potranquility/player.lua",18);
assert(messages[1]:find("lack the will",1,true),"Time A level gate bypassed");
level=65; messages={}; door("potimea/player.lua",8);
assert(#signals==0 and messages[1]:find("sufficient power",1,true),"Time B raid gate bypassed");
raid={valid=true,RaidCount=function() return 7; end,GetID=function() return 456; end};
door("potimea/player.lua",8); assert(#signals==1,"normal Time B request blocked");
local count=#signals; level=64; door("potimea/player.lua",8);
assert(#signals==count,"Time B level gate bypassed"); level=65;
guild=1; raid_window=false; door("potimea/player.lua",8);
assert(#signals==count,"Guild 1 quake window bypassed"); guild=42; raid_window=true;
globals.time_instance="55001"; globals.time_instance_guild="99";
local future=tostring(math.ceil(os.time()/100)+1000);
timeline.time_timers_55001=table.concat({future,"0","0","0","0","0","0","0","0","0","0","0"},";");
timeline.time_kills_55001="11111;11111;00000000000000000000;0000;0000;0";
messages={}; door("potimea/player.lua",8);
assert(#signals==count and messages[#messages]:find("bound to another guild",1,true),"foreign loot lock bypassed");

-- Every combination of partial HoH/Sol Ro bits and Zek progression normalizes
-- cleanly, including pending memories that otherwise could reapply old states.
local function bits(n,width)
    local out="";
    for _=1,width do out=tostring(n%2)..out; n=math.floor(n/2); end
    return out;
end
local cases=0;
for z=0,7 do for h=0,7 do for sol=0,31 do
    reset(); slots[22]=29165;
    globals.zeks=tostring(z); globals.hohtrials=bits(h,3); globals.sol_room=bits(sol,5);
    globals.cl_tallon="1"; globals.cl_vallon="1"; globals.cl_mmarr="1";
    globals.cl_mmarr_book="1"; globals.cl_solusek="1";
    globals.time_instance="55001"; globals.time_instance_generation="55001:1234";
    Q.Complete(client); complete(); no_time();
    assert(loadfile("poknowledge/Seer_Mal_Nae-Shi.lua"))();
    local writesBefore=writes; local deletesBefore=deletes;
    GuidedMeditation(client); UnlockMemories(client); Q.Complete(client);
    assert(writes==writesBefore and deletes==deletesBefore,"normalization was not stable");
    assert(globals.time_instance=="55001" and globals.time_instance_generation=="55001:1234");
    cases=cases+1;
end end end
print("PASS Quintessence: actual prior-zone portals, Seer, Muon/machine/Time entry, level/raid/quake/foreign-lock guards; "..cases.." partial-state combinations; carried/banked/absent-item checks");
