-- Run from the quest root: lua5.1 tests/pop_raid_willing_test.lua
-- The native policy is mocked; these tests execute actual portal scripts.
package.path = "./lua_modules/?.lua;" .. package.path;
local checks=0;
local function check(value,message) assert(value,message); checks=checks+1; end
local globals,zones,items,keyring,messages,moves,requests,writes,allowed,level;
local client={};
local native=function(_,zone) requests[#requests+1]=zone; return allowed==zone; end;
function client:HasZoneFlag(zone) return zones[zone] or false; end
function client:SetZoneFlag(zone) zones[zone]=true; writes=writes+1; end
function client:GetItemIDAt(slot) return items[slot] or 0; end
function client:KeyRingCheck(item) return keyring[item] or false; end
function client:KeyRingAdd(item) keyring[item]=true; writes=writes+1; end
function client:GetLevel() return level; end
function client:GetGM() return false; end
function client:Message(_,text) messages[#messages+1]=text; end
function client:MovePC(...) moves[#moves+1]={...}; end
local function reset()
 globals,zones,items,keyring,messages,moves,requests={},{},{},{},{},{},{};
 writes,allowed,level=0,nil,54;
 client.CanRaidWillIntoPopZone=native;
 eq={get_qglobals=function() return globals; end,
     get_data=function() return "1"; end,
     set_global=function(k,v) globals[k]=v; writes=writes+1; end,
     delete_global=function(k) globals[k]=nil; writes=writes+1; end,
     get_entity_list=function() return {IsMobSpawnedByNpcTypeID=function()return false;end}; end};
end
local function click(file,id)
 local env=setmetatable({},{__index=_G});
 local f=assert(loadfile(file));setfenv(f,env);f();
 env.event_click_door({self=client,door={GetDoorID=function()return id;end}});
end
local portals={
 {"potranquility/player.lua",16,210},{"potranquility/player.lua",21,208},
 {"potranquility/player.lua",12,200},{"potranquility/player.lua",93,207},
 {"potranquility/player.lua",48,209},{"potranquility/player.lua",23,211},
 {"potranquility/player.lua",24,214},{"potranquility/player.lua",22,212},
 {"potranquility/player.lua",82,217},{"potranquility/player.lua",81,215},
 {"potranquility/player.lua",83,218},{"potranquility/player.lua",84,216},
 {"potranquility/player.lua",18,219},
 {"poeartha/player.lua",9,222},{"poeartha/player.lua",10,222},{"poeartha/player.lua",11,222},
 {"hohonora/player.lua",19,220},{"hohonora/player.lua",20,220},
 {"ponightmare/player.lua",59,221},{"povalor/player.lua",3,211},{"postorms/player.lua",4,209}
};
for _,p in ipairs(portals) do
 for _,state in ipairs({"eligible","denied","wrong_destination","old_binary"}) do
  reset();if p[3]==219 then level=65;end;globals.time_instance="55001";globals.time_instance_generation="55001:1234";
  if state=="eligible" then allowed=p[3];
  elseif state=="wrong_destination" then allowed=999;
  elseif state=="old_binary" then client.CanRaidWillIntoPopZone=nil; end
  click(p[1],p[2]);
  check(writes==0,p[1].." borrowed entry wrote a permanent flag");
  check(globals.time_instance=="55001" and globals.time_instance_generation=="55001:1234","lockouts changed");
  if state~="old_binary" then check(#requests==1 and requests[1]==p[3],"wrong destination sent to native policy");end
  local success=state=="eligible";
  local time=p[3]==219;
  check(#messages==(success and (time and 1 or 0) or 1),p[1].." wrong admission message");
  if p[3]==222 then
   check(#moves==(success and 1 or 0),"Earth B movement did not follow native policy");
   if success then check(moves[1][1]==222 and moves[1][2]==-764 and moves[1][3]==333,"Earth B destination changed");end
  end
 end
end
-- Earning the normal prerequisite still grants its permanent zone flag. A
-- qualifying raid must not short-circuit these paths and lose earned credit.
local earned={
 {"potranquility/player.lua",16,210,{mavuin="3"}},
 {"potranquility/player.lua",93,207,{fuirstel="5",thelin="4"}},
 {"potranquility/player.lua",48,209,{karana="3"}},
 {"potranquility/player.lua",24,214,{zeks="2"}},
 {"potranquility/player.lua",22,212,{cipher="1",zeks="6"}},
 {"potranquility/player.lua",81,215,{zebuxoruk="2"}},
 {"poeartha/player.lua",9,222,{earthb_key="1"}},
 {"hohonora/player.lua",19,220,{hohtrials="111"}},
 {"ponightmare/player.lua",59,221,{thelin="2"}},
 {"povalor/player.lua",3,211,{aerindar="1",cl_aerindar="1"}},
 {"postorms/player.lua",4,209,{karana="2",mavuin="3"}}
};
for _,p in ipairs(earned) do
 reset();globals=p[4];allowed=p[3];click(p[1],p[2]);
 check(zones[p[3]],p[1].." failed to award earned zone access");
 check(#requests==0,"borrowed access displaced a normal flag award");
end
-- Alternate key quests and their first-use keyring paths still work.
for _,p in ipairs({{12,200,9294},{93,207,29213},{23,211,29214},{24,214,29215}}) do
 reset();items[0]=p[3];click("potranquility/player.lua",p[1]);
 check(zones[p[2]] and keyring[p[3]],"alternate key path changed");
end
reset();zones[222]=true;click("poeartha/player.lua",9);
check(#moves==1 and writes==0 and #requests==0,"existing Earth B flag not honored");
reset();allowed=219;level=64;click("potranquility/player.lua",18);
check(#messages==1 and messages[1]:find("lack the will",1,true) and writes==0,"Time level gate bypassed");
reset();level=65;globals.time="1";zones[219]=true;click("potranquility/player.lua",18);
check(#messages==1 and messages[1]:find("ages begin",1,true) and #requests==0,"permanent Time access changed");
for _,file in ipairs({"potranquility/player.lua","poeartha/player.lua","hohonora/player.lua","ponightmare/player.lua","povalor/player.lua","postorms/player.lua"}) do
 reset();allowed=222;click(file,999);
 check(writes==0 and #requests==0 and #moves==0 and #messages==0,"unrelated door changed");
end
print("PASS raid willing: "..checks.." checks across 21 portal routes; destination-specific borrowing, normal earned flags, old-server fallback and level/lockout preservation");
