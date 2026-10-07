-- Lua 5.1: lua tests/projection_eligibility_test.lua /path/to/Quests
-- Pure mocks: no database writes, server reloads or gameplay clients.
local root=arg[1]or".";
local checks=0;
local function check(ok,text)assert(ok,text);checks=checks+1;end
local function read(path)local f=assert(io.open(root.."/"..path));local s=f:read("*a");f:close();return s;end
local helper=read("lua_modules/projection_eligibility.lua");
local function world()
 local w={now=1000,clients={},mobs={},nextid=9000,timers={},logs={},messages={},spawnCalls=0};
 local invalid={valid=false};
 local function affiliation(id)return id and {valid=true,GetID=function()return id;end}or invalid;end
 function w:client(id,raid,group,gm)
  local c={valid=true,id=id,character=id,raid=raid,group=group,gm=gm,globals={},items={}};
  function c:GetID()return self.id;end
  function c:CharacterID()return self.character;end
  function c:IsClient()return true;end
  function c:IsPet()return false;end
  function c:CastToClient()return self;end
  function c:GetRaid()return affiliation(self.raid);end
  function c:GetGroup()return affiliation(self.group);end
  function c:GetGM()return self.gm or false;end
  function c:GetName()return"Character"..self.character;end
  function c:Message(color,text)w.messages[#w.messages+1]={gm=self:GetGM(),color=color,text=text};end
  function c:HasItem(id)return self.items[id]or false;end
  function c:SummonCursorItem(id)self.items[id]=true;end
  w.clients[#w.clients+1]=c;w.mobs[c.id]=c;return c;
 end
 function w:npc(typ)
  w.nextid=w.nextid+1;
  local n={valid=true,id=w.nextid,typ=typ,vars={}};
  function n:GetID()return self.id;end
  function n:GetNPCTypeID()return self.typ;end
  function n:GetEntityVariable(key)return self.vars[key]or"";end
  function n:SetEntityVariable(key,value)self.vars[key]=tostring(value);end
  function n:Depop()self.valid=false;self.depopped=true;end
  function n:Say()end
  w.mobs[n.id]=n;return n;
 end
 local listOwnerChecks=0;
 local entity={};
 function entity:GetClientList()
  local list={};local weak=setmetatable({list},{__mode="v"});local i=0;
  list.entries=function()
   collectgarbage("collect");assert(weak[1],"temporary client list lost its owner");listOwnerChecks=listOwnerChecks+1;
   i=i+1;return w.clients[i];
  end
  return list;
 end
 function entity:GetClientByID(id)local c=w.mobs[id];return c and c.valid and c:IsClient()and c or invalid;end
 function entity:GetMob(id)return w.mobs[id]or invalid;end
 local eq={};
 function eq.get_entity_list()return entity;end
 function eq.debug(text)w.logs[#w.logs+1]=text;end
 function eq.spawn2(typ,...)
  w.spawnCalls=w.spawnCalls+1;if w.onSpawn then w.onSpawn();end
  if w.failSpawn then return invalid;end
  return w:npc(typ);
 end
 function eq.set_timer(name,ms,npc)w.timers[(npc or w.currentNPC).id..":"..name]=ms;end
 function eq.pause_timer()end
 function eq.resume_timer()end
 function eq.depop()w.currentNPC:Depop();end
 function eq.get_qglobals(c)return c.globals;end
 function eq.set_global(key,value)w.currentClient.globals[key]=value;end
 function eq.delete_global(key)w.currentClient.globals[key]=nil;end
 local env=setmetatable({eq=eq,os={time=function()return w.now;end}},{__index=_G});
 w.eq=eq;w.env=env;
 function w:loadHelper()local f=assert(loadstring(helper));setfenv(f,self.env);self.module=f();return self.module;end
 w:loadHelper();
 function w:handler(file,npc)
  local scriptEnv=setmetatable({eq=eq,require=function(name)assert(name=="projection_eligibility");return w.module;end},{__index=_G});
  local f=assert(loadstring(read(file),file));setfenv(f,scriptEnv);f();
  function scriptEnv.hail(c)
   w.currentNPC=npc;w.currentClient=c;
   scriptEnv.event_say({self=npc,other=c,message={findi=function(_,needle)return needle=="hail";end}});
  end
  return scriptEnv;
 end
 return w;
end
local w=world();local killer=w:client(1,100);local earner=w:client(2,100);local stranger=w:client(3,200);local gm=w:client(4,nil,nil,true);
local n=w.module.Spawn(200269,0,0,1,2,3,0,killer);
check(w.module.CanFlag(n,killer),"kill-credit client eligible");
check(w.module.CanFlag(n,earner),"raid member snapshot eligible");
check(not w.module.CanFlag(n,stranger),"unrelated raid refused");
local late=w:client(5,100);check(w.module.CanFlag(n,late),"late alt allowed through original raid");
local guildOnly=w:client(6,nil);check(not w.module.CanFlag(n,guildOnly),"same guild alone grants no eligibility");
earner.raid=300;check(w.module.CanFlag(n,earner),"saved member allowed after changing raid");
earner.raid=nil;earner.id=222;w.mobs[222]=earner;check(w.module.CanFlag(n,earner),"camped member's new entity ID retains character eligibility");
w.module.OnSignal({self=n,signal=999999});check(w.module.CanFlag(n,late),"invalid late signal cannot erase binding");
w.module.OnSignal({self=n,signal=stranger.id});check(not w.module.CanFlag(n,stranger),"another raid's signal cannot take over initialized projection");
for _,msg in ipairs(w.messages)do check(msg.gm and msg.color==15,"diagnostics are yellow and GM-only");end
w.module.SaveCount(n,71);w.now=1100;w.timers={};w:loadHelper();
check(w.module.Count(n)==71,"flag cap counter survives helper/script reload");
check(w.module.CanFlag(n,earner),"eligibility survives script reload");
check(w.timers[n.id..":depop"]==1100000,"reload rearms only original lifetime remainder");
w.now=2200;check(not w.module.CanFlag(n,late)and n.depopped,"late alt refused at original expiration");
-- Direct handoff captures before spawning; losing the player before queued
-- signal delivery cannot strand this new projection.
w=world();killer=w:client(1,100);earner=w:client(2,100);w.onSpawn=function()killer.valid=false;w.mobs[1]=nil;end;
n=w.module.Spawn(200269,0,0,0,0,0,0,killer);check(w.module.CanFlag(n,earner),"captured context survives recipient disappearing during spawn");
-- Group and solo paths preserve late group members and reconnects.
w=world();killer=w:client(1,nil,10);earner=w:client(2,nil,10);n=w.module.Spawn(1,0,0,0,0,0,0,killer);
late=w:client(3,nil,10);check(w.module.CanFlag(n,late),"late group alt admitted");
earner.group=nil;check(w.module.CanFlag(n,earner),"saved group member retains credit after disband");
w=world();killer=w:client(1);n=w.module.Spawn(1,0,0,0,0,0,0,killer);killer.id=123;check(w.module.CanFlag(n,killer),"solo reconnect uses character ID");
stranger=w:client(11);check(not w.module.CanFlag(n,stranger),"character IDs cannot match substrings");
-- Pet-owned kill rights resolve to a player; no unrelated fallback for NPC kills.
w=world();killer=w:client(1,100);local pet={valid=true,GetID=function()return 90;end,IsClient=function()return false;end,IsPet=function()return true;end,GetOwner=function()return killer;end};
n=w.module.Spawn(1,0,0,0,0,0,0,pet);check(w.module.CanFlag(n,killer),"pet kill rights resolve owner");
local npcKiller={valid=true,GetID=function()return 99;end,IsClient=function()return false;end,IsPet=function()return false;end};
n=w.module.Spawn(1,0,0,0,0,0,0,npcKiller);check(not w.module.CanFlag(n,killer),"NPC kill recipient fails closed");
local old=w:npc(2);w.module.OnSpawn(old,1200);w.module.OnSignal({self=old,signal=killer.id});check(w.module.CanFlag(old,killer),"legacy signal initializes new handler");
local other=w:client(2,200);local second=w.module.Spawn(2,0,0,0,0,0,0,other);
check(not w.module.CanFlag(second,killer)and w.module.CanFlag(old,killer),"two same-type projections keep independent ownership");
w.failSpawn=true;check(not w.module.Spawn(2,0,0,0,0,0,0,killer).valid,"failed spawn handled");
-- Existing combat pauses remain pauses, with a persisted remainder.
w=world();killer=w:client(1);n=w.module.Spawn(1,0,0,0,0,0,0,killer);w.now=1100;w.module.OnCombat(n,true);w.now=5000;
check(w.module.CanFlag(n,killer),"combat pause preserves existing essence behavior");
w:loadHelper();w.module.OnCombat(n,false);check(w.timers[n.id..":depop"]==1100000,"reload during combat resumes remaining lifetime");
w.now=6100;check(not w.module.CanFlag(n,killer),"resumed lifetime expires");
-- Exercise the actual reward scripts, including prerequisites and preserved
-- counters, through both eligibility paths. No flagging rules are replaced.
local specs={
 {"codecay/A_Planar_Projection.lua",{bertox_key="1",fuirstel="3"},"fuirstel","4",72},
 {"hohonorb/A_Planar_Projection.lua",{hohtrials="111"},"mmarr","1",144},
 {"nightmareb/A_Planar_Projection.lua",{thelin="2"},"thelin","3",72},
 {"podisease/A_Planar_Projection.lua",{fuirstel="1"},"fuirstel","2",144},
 {"poeartha/A_Planar_Projection.lua",{},"earthb_key","1",54},
 {"potorment/A_Planar_Projection.lua",{tylis="2"},"saryrn","1",72},
 {"povalor/A_Planar_Projection.lua",{mavuin="3"},"aerindar","1",72},
 {"solrotower/A_Planar_Projection.lua",{sol_room="11111",pofire="1",zeks="7"},"pofire","2",72},
 {"potactics/214322.lua",{zeks="6"},"zeks","7",72},
 {"potactics/214323.lua",{zeks="2"},"zeks","4",72},
 {"potactics/214324.lua",{zeks="2"},"zeks","3",72},
 {"poinnovation/#Giwin_Mirakon.lua",{zeks="1"},"zeks","2",72,600},
 {"pofire/Essence_of_Fire.lua",{},29147,true,72},
 {"poair/Essence_of_Air.lua",{},29164,true,72},
 {"powater/Essence_of_Water.lua",{},29163,true,72},
 {"poearthb/Essence_of_Earth.lua",{},29146,true,72},
};
local function prerequisites(c,spec)for k,v in pairs(spec[2])do c.globals[k]=v;end;end
local function rewarded(c,spec)return type(spec[3])=="number"and c.items[spec[3]]==true or c.globals[spec[3]]==spec[4];end
for _,spec in ipairs(specs)do
 w=world();killer=w:client(1,100);earner=w:client(2,100);stranger=w:client(4,200);
 n=w.module.Spawn(100,0,0,0,0,0,0,killer,spec[6]);
 late=w:client(3,100);local h=w:handler(spec[1],n);w.currentNPC=n;h.event_spawn({self=n});
 check(n.vars.flagger_v1_expires==tostring(1000+(spec[6]or 1200)),spec[1].." lifetime preserved");
 earner.raid=nil;prerequisites(earner,spec);h.hail(earner);check(rewarded(earner,spec),spec[1].." snapshot reward");
 local firstCount=w.module.Count(n);for i=1,100 do h.hail(earner);end;
 check(w.module.Count(n)==firstCount,spec[1].." 100 repeat hails consume no extra claims");
 w:loadHelper();h=w:handler(spec[1],n);prerequisites(late,spec);h.hail(late);check(rewarded(late,spec),spec[1].." late raid alt reward after reload");
 prerequisites(stranger,spec);h.hail(stranger);check(not rewarded(stranger,spec),spec[1].." unrelated character refused");
 -- Use cap+1 to preserve <= boundary checks in old scripts without silently
 -- changing their accepted maximum in this eligibility-only patch.
 w.module.SaveCount(n,spec[5]+1);w:loadHelper();h=w:handler(spec[1],n);
 local capped=w:client(5,100);prerequisites(capped,spec);h.hail(capped);
 check(not rewarded(capped,spec),spec[1].." existing reward cap cannot reset on reload");
end
w=world();killer=w:client(1,100);n=w.module.Spawn(200269,0,0,0,0,0,0,killer);local h=w:handler("codecay/A_Planar_Projection.lua",n);
killer.globals.fuirstel="3";h.hail(killer);check(killer.globals.fuirstel=="3","Bertox key still required");
killer.globals.bertox_key="1";h.hail(killer);check(killer.globals.fuirstel=="4","Bertox valid prerequisite path grants credit");
local before=w.module.Count(n);h.hail(killer);check(w.module.Count(n)==before,"duplicate Bertox hail consumes no additional credit");
-- Pending checklist flags must also be idempotent when prerequisites are missing.
local pending={
 {"codecay/A_Planar_Projection.lua",{bertox_key="1"},1},
 {"hohonorb/A_Planar_Projection.lua",{},2},
 {"nightmareb/A_Planar_Projection.lua",{},1},
 {"podisease/A_Planar_Projection.lua",{},2},
 {"potorment/A_Planar_Projection.lua",{},1},
 {"solrotower/A_Planar_Projection.lua",{sol_room="11111"},1},
 {"potactics/214322.lua",{},1},
 {"potactics/214323.lua",{},1},
 {"potactics/214324.lua",{},1},
 {"poinnovation/#Giwin_Mirakon.lua",{},1},
};
for _,spec in ipairs(pending)do
 w=world();killer=w:client(1,100);for k,v in pairs(spec[2])do killer.globals[k]=v;end;
 n=w.module.Spawn(100,0,0,0,0,0,0,killer);local h=w:handler(spec[1],n);h.hail(killer);
 check(w.module.Count(n)==spec[3],spec[1].." pending credit consumes only new flags");
 for i=1,100 do h.hail(killer);end;
 check(w.module.Count(n)==spec[3],spec[1].." 100 pending-repeat hails consume no extra claims");
 w:loadHelper();h=w:handler(spec[1],n);h.hail(killer);
 check(w.module.Count(n)==spec[3],spec[1].." pending-repeat hail after reload consumes no extra claims");
end
print("PASS projection eligibility: "..checks.." checks across 16 actual reward scripts");
