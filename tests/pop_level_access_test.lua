-- Run from quest root: lua5.1 tests/pop_level_access_test.lua
local checks=0;
local function check(ok,text) assert(ok,text);checks=checks+1;end
local levels={{16,210,55},{21,208,55},{12,200,55},{93,207,55},{24,214,60},{48,209,62},{23,211,62}};
local function portal(door,level,enabled,globals,keys,borrowed)
 local flags,messages={},{};local client={};
 function client:GetLevel() return level;end
 function client:HasZoneFlag(id) return flags[id] or false;end
 function client:SetZoneFlag(id) flags[id]=true;end
 function client:GetItemIDAt() return 0;end
 function client:KeyRingCheck(id) return keys and keys[id] or false;end
 function client:KeyRingAdd() error("level entry must not invent keyring items");end
 function client:GetGM() return false;end
 function client:CanRaidWillIntoPopZone(id) return borrowed==id;end
 function client:Message(_,text) messages[#messages+1]=text;end
 local env=setmetatable({eq={get_qglobals=function() return globals or {};end,get_data=function() return enabled and "1" or "0";end}}, {__index=_G});
 env.require=function(name) return setfenv(assert(loadfile("lua_modules/"..name..".lua")),env)();end
 setfenv(assert(loadfile("potranquility/player.lua")),env)();
 env.event_click_door({self=client,door={GetDoorID=function()return door;end}});
 return flags,messages;
end
for _,row in ipairs(levels) do
 for _,enabled in ipairs({false,true}) do
  for level=1,65 do
   local flags,messages=portal(row[1],level,enabled);
   local admitted=enabled and level>=row[3];
   check((flags[row[2]] or false)==admitted,"level/toggle boundary for zone "..row[2].." level "..level);
   check(#messages==(admitted and 0 or 1),"level admission feedback");
  end
 end
end
for _,row in ipairs({{22,212},{81,215},{82,217},{83,218},{84,216},{18,219}}) do
 local flags,messages=portal(row[1],65,true);
 check(not next(flags) and #messages==1,"level alone cannot open higher planes/Time");
end
for _,row in ipairs({{12,200,9294},{93,207,29213},{23,211,29214},{24,214,29215}}) do
 local flags=portal(row[1],46,true,nil,{[row[3]]=true});check(flags[row[2]],"quest key works below level bypass threshold");
 local disabled=portal(row[1],46,false,nil,{[row[3]]=true});check(not disabled[row[2]],"toggle still controls alternate key access");
end
local flags=portal(16,46,false,{mavuin="3"});check(flags[208] and flags[210],"normal Justice progression works while alternatives disabled");
local flags=portal(93,46,false,{fuirstel="5",thelin="4"});check(flags[207],"normal Torment progression retained");
print("PASS: "..checks.." level-access boundary and progression checks");
