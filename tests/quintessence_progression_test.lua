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
print("PASS: carried Quintessence completes prior progression; absent/banked/uncombined items rejected; NPC/machine flow, repeat safety and unrelated lockouts preserved");
