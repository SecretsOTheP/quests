-- Lua 5.1: actual quest callbacks, simulated clock, no database/server writes.
local root=arg[1] or ".";
local checks=0;
local function check(ok,msg) assert(ok,msg); checks=checks+1; end
function string.findi(s,needle) return s:lower():find(needle:lower(),1,true); end
local files={
 [207014]="potorment/Tylis_Newleaf.lua",[207318]="potorment/#Tylis_Newleaf.lua",
 [207015]="potorment/The_Keeper_of_Sorrows.lua",[207001]="potorment/Saryrn.lua",
 [207317]="potorment/A_Planar_Projection.lua",
 [209156]="bothunder/#Askr_the_Lost.lua",[209157]="bothunder/##Askr_the_Lost.lua",
 [209158]="bothunder/A_Chaotic_Vortex.lua",[209136]="bothunder/Karana.lua",
 [900001]="bothunder/Evynd_Firestorm.lua",[900002]="bothunder/Emmerik_Skyfury.lua",
 [900003]="bothunder/Agnarr_the_Storm_Lord.lua"};
local function load(file,env)
 local f=assert(loadfile(root.."/"..file));setfenv(f,env);return f();
end
local function world()
 local w={now=1000,nextid=10,mobs={},clients={},timers={},respawns={},modules={},messages={}};
 local invalid={valid=false,GetID=function()return 0;end,GroupCount=function()return 0;end};
 function invalid:CastToClient()return self;end
 local function live(n)return n and n.valid;end
 local function list(values)
  local i=0;return {entries=function()i=i+1;return values[i];end};
 end
 local entity={};
 function entity:GetMobByNpcTypeID(typ)
  for _,n in ipairs(w.mobs) do if n.valid and n.typ==typ then return n;end end
  return invalid;
 end
 function entity:GetMobID(id)
  for _,n in ipairs(w.mobs) do if n.valid and n.id==id then return n;end end
  return invalid;
 end
 function entity:GetMob(id)return self:GetMobID(id);end
 function entity:GetClientByID(id)
  for _,n in ipairs(w.clients)do if n.valid and n.id==id then return n;end end
  return invalid;
 end
 function entity:GetClientList()return list(w.clients);end
 function entity:GetNPCList()
  local values={};for _,n in ipairs(w.mobs)do if n.valid and n.typ then values[#values+1]=n;end end
  return list(values);
 end
 function entity:RemoveFromHateLists()end
 function entity:GetSpawnByID()return {SetTimer=function()end};end
 local eq={};
 function eq.get_entity_list()return entity;end
 function eq.get_qglobals(c)return c.globals;end
 function eq.set_global(k,v)w.currentClient.globals[k]=v;end
 function eq.delete_global(k)w.currentClient.globals[k]=nil;end
 function eq.set_timer(name,ms,npc)
  npc=npc or w.currentNPC;assert(npc,"timer owner required");
  w.timers[npc.id..":"..name]={npc=npc,name=name,ms=ms,due=w.now+ms/1000};
 end
 function eq.stop_timer(name,npc)npc=npc or w.currentNPC;w.timers[npc.id..":"..name]=nil;end
 function eq.depop()w.currentNPC:Depop();end
 function eq.depop_with_timer(typ)
  local n=entity:GetMobByNpcTypeID(typ);if n.valid then n:Depop(true);end
 end
 function eq.depop_all(typ)
  for _,n in ipairs(w.mobs)do if n.typ==typ and n.valid then n:Depop();end end
 end
 function eq.spawn2(typ,grid,unused,x,y,z,h)return w:npc(typ,x,y,z,h);end
 function eq.unique_spawn(typ,...)
  local n=entity:GetMobByNpcTypeID(typ);if n.valid then return n;end
  return eq.spawn2(typ,...);
 end
 function eq.signal(typ,signal)
  local n=entity:GetMobByNpcTypeID(typ);if n.valid then w:call(n,'event_signal',{signal=signal});end
 end
 function eq.debug()end
 function eq.set_next_hp_event()end
 function eq.zone_emote()end
 function eq.clock()return w.now;end
 w.env=setmetatable({eq=eq,os={time=function()return w.now;end}},{__index=_G});
 w.env.require=function(name)
  if not w.modules[name] then w.modules[name]=load('lua_modules/'..name..'.lua',w.env);end
  return w.modules[name];
 end
 function w:loadNPC(n)
  n.env=setmetatable({},{__index=self.env});if files[n.typ]then load(files[n.typ],n.env);end
 end
 function w:npc(typ,x,y,z,h)
  self.nextid=self.nextid+1;
  local n={valid=true,id=self.nextid,typ=typ,vars={},x=x or 0,y=y or 0,z=z or 0,h=h or 0};
  function n:GetID()return self.id;end
  function n:GetNPCTypeID()return self.typ;end
  function n:GetEntityVariable(k)return self.vars[k]or'';end
  function n:SetEntityVariable(k,v)self.vars[k]=tostring(v);end
  function n:GetX()return self.x;end
  function n:GetY()return self.y;end
  function n:GetZ()return self.z;end
  function n:GetHeading()return self.h;end
  function n:SetBodyType(v)self.bodytype=v;end
  function n:Depop(timer)
   self.valid=false;if timer then w.respawns[#w.respawns+1]={npc=self,at=w.now};end
  end
  function n:Say(text)self.lastSay=text;end
  function n:Emote()end
  function n:CastSpell(spell,target)self.lastCast={spell,target};end
  function n:IsClient()return false;end
  function n:IsPet()return false;end
  -- QuestManager::spawn2 runs EVENT_SPAWN before EntityList::AddNPC registers the NPC.
  self:loadNPC(n);self:call(n,'event_spawn',{});self.mobs[#self.mobs+1]=n;return n;
 end
 function w:client(raid,group)
  self.nextid=self.nextid+1;
  local c={valid=true,id=self.nextid,raid=raid,group=group,globals={},items={}};
  function c:GetID()return self.id;end
  function c:CharacterID()return self.id;end
  function c:GetName()return 'Alt'..self.id;end
  function c:IsClient()return true;end
  function c:IsPet()return false;end
  function c:CastToClient()return self;end
  function c:GetGM()return false;end
  function c:Admin()return 0;end
  function c:GetPet()return invalid;end
  function c:HasItem(id)return self.items[id]or false;end
  function c:KeyRingCheck(id)return self.keyring==id;end
  function c:KeyRingAdd(id)self.keyring=id;end
  function c:GetItemIDAt(slot)return self.cursor or 0;end
  local function affiliation(self,key)
   local id=self[key];if not id then return invalid;end
   local obj={valid=true,GetID=function()return id;end};
   function obj:GetMember(i)
    local count=0;for _,member in ipairs(w.clients)do
     if member.valid and member[key]==id then if count==i then return member;end;count=count+1;end
    end;return invalid;
   end
   function obj:GroupCount()
    local count=0;for _,member in ipairs(w.clients)do if member.valid and member[key]==id then count=count+1;end end;return count;
   end
   return obj;
  end
  function c:GetRaid()return affiliation(self,'raid');end
  function c:GetGroup()return affiliation(self,'group');end
  function c:Message(color,text)w.messages[#w.messages+1]=text;end
  function c:MovePC(...)self.lastMove={...};end
  function c:SpellFinished()end
  self.clients[#self.clients+1]=c;self.mobs[#self.mobs+1]=c;return c;
 end
 function w:call(n,event,data)
  local oldN,oldC=self.currentNPC,self.currentClient;
  self.currentNPC=n;self.currentClient=data.other;data.self=n;
  if n.env[event]then n.env[event](data);end
  self.currentNPC,self.currentClient=oldN,oldC;
 end
 function w:say(n,c,text)self:call(n,'event_say',{other=c,message=text});end
 function w:kill(n,killer)n.valid=false;self:call(n,'event_death_complete',{killer=killer});end
 function w:advance(seconds)
  self.now=self.now+seconds;local due={};for k,t in pairs(self.timers)do if t.due<=self.now then due[#due+1]={k,t};end end
  for _,entry in ipairs(due)do local k,t=unpack(entry);if self.timers[k]==t and t.npc.valid then
   t.due=self.now+t.ms/1000;self:call(t.npc,'event_timer',{timer=t.name});
  end end
 end
 function w:get(typ)return entity:GetMobByNpcTypeID(typ);end
 function w:player()
  local env=setmetatable({},{__index=self.env});load('bothunder/player.lua',env);return env;
 end
 function w:reload(n)self.modules={};self:loadNPC(n);end
 return w;
end
-- Torment: Keeper starts a shared thirty-minute rescue window, independent of Saryrn.
local w=world();local main=w:client(10);local alt=w:client(10);local stranger=w:client(20);
local entrance=w:npc(207014,8,9,10,11);main.items[22954]=true;
w:say(entrance,alt,'i am ready');check(not entrance.lastCast,'Tylis prerequisite still required');
alt.globals.tylis='1';main.items[22954]=nil;
w:say(entrance,alt,'i am ready');check(not entrance.lastCast,'Screaming Sphere still required before Keeper dies');
main.keyring=22954;w:say(entrance,alt,'i am ready');check(entrance.lastCast[1]==1134,'raid key holder still admits qualified alt');
check(not w:get(207318).valid,'no freed Tylis before Keeper kill');
local keeperDiedAt=w.now;w:kill(w:npc(207015),main);
check(#w.respawns==1 and w.respawns[1].npc==entrance and w.respawns[1].at==keeperDiedAt,'native Tylis cooldown starts at Keeper death');
local copy=w:get(207014);local freed=w:get(207318);
local deadline=tostring(keeperDiedAt+1800);
check(copy.valid and copy~=entrance and copy.x==8 and copy.y==9 and copy.z==10 and copy.h==11 and copy.bodytype==1,'temporary entrance retains earned location and targetability');
check(copy.vars.flagging_travel_fixed_deadline==deadline and freed.vars.flagging_travel_fixed_deadline==deadline,'both Tylis copies share exactly thirty minutes from Keeper death');
check(not copy.vars.flagging_travel_final_type and not freed.vars.flagging_travel_final_type,'Tylis has no final-flagger dependency');
main.keyring=nil;
w:say(copy,alt,'i am ready');check(copy.lastCast and copy.lastCast[1]==1134,'post-Keeper entrance admits preflagged alt without any sphere holder');
w:say(copy,alt,'will assist you');check(copy.lastSay and copy.lastSay:find('Please tell me when you are ready',1,true),'post-Keeper assist dialogue waives only the sphere');
local solo=w:client();solo.globals.tylis='1';copy.lastCast=nil;
w:say(copy,solo,'we are ready');check(copy.lastCast and copy.lastCast[2]==solo.id,'solo preflagged alt needs no sphere or credited raid for entry');
local unflagged=w:client();unflagged.items[22954]=true;copy.lastCast=nil;copy.lastSay=nil;
w:say(copy,unflagged,'i am ready');check(not copy.lastCast and not unflagged.globals.tylis,'post-Keeper sphere holder without preflag is refused');
w:say(copy,unflagged,'will assist you');check(not copy.lastSay,'assist dialogue still requires personal preflag');
unflagged.items[22954]=nil;w:say(copy,unflagged,'we are ready');check(not copy.lastCast,'missing both sphere and preflag is refused');
w:reload(copy);w:say(copy,alt,'i am ready');check(copy.lastCast and copy.lastCast[2]==alt.id and copy.vars.flagging_travel_fixed_deadline==deadline,'reload preserves earned sphere waiver and original deadline');
w:advance(600);check(copy.valid and freed.valid,'both Tylis copies outlast the original ten-minute rescue window');
w:say(freed,alt,'hail');check(alt.globals.tylis=='2','rescue flag still upgrades the existing Tylis preflag');
local pending=w:client(10);w:say(freed,pending,'hail');check(pending.globals.cl_keeper=='1' and not pending.globals.tylis,'missing rescue prerequisite retains checklist behavior');
local count=freed.vars.keeper_flags;w:reload(freed);w:say(freed,alt,'hail');check(freed.vars.keeper_flags==count,'rescue count survives reload and repeat hail');
w:say(freed,alt,'ready to return');check(freed.lastCast and freed.lastCast[1]==1136,'rescued Tylis still provides return teleport');
w:kill(w:npc(207001),main);local projection=w:get(207317);
check(projection.vars.flagger_v1_expires==tostring(w.now+1800),'Saryrn has its own thirty-minute eligibility window');
check(w.timers[projection.id..':depop'].ms==1800000,'Saryrn projection timer is thirty minutes');
check(copy.vars.flagging_travel_fixed_deadline==deadline and freed.vars.flagging_travel_fixed_deadline==deadline,'Saryrn spawning does not extend either Tylis deadline');
local late=w:client(10);late.globals.tylis='1';copy.lastCast=nil;
w:say(copy,late,'i am ready');check(copy.lastCast and copy.lastCast[2]==late.id,'late alt without sphere can enter during remaining Keeper window');
copy.lastCast=nil;w:say(copy,unflagged,'i am ready');check(not copy.lastCast,'Saryrn projection does not waive Tylis preflag');
w:say(projection,alt,'hail');check(alt.globals.saryrn=='1','credited raid alt with prerequisites earns Saryrn flag');
w:say(projection,pending,'hail');check(pending.globals.cl_saryrn=='1' and not pending.globals.saryrn,'Saryrn prerequisite retains checklist behavior');
stranger.globals.tylis='2';w:say(projection,stranger,'hail');check(not stranger.globals.saryrn and not stranger.globals.cl_saryrn,'unrelated raid cannot claim Saryrn');
freed:SetEntityVariable('keeper_flags','73');local capped=w:client(10);capped.globals.tylis='1';w:reload(freed);w:say(freed,capped,'hail');check(capped.globals.tylis=='1','existing rescue allowance remains capped after reload');
w:advance(1199);w:reload(copy);w:reload(freed);copy.lastCast=nil;w:say(copy,alt,'i am ready');
check(copy.valid and freed.valid and copy.lastCast and copy.vars.flagging_travel_fixed_deadline==deadline,'both copies remain usable at Keeper plus 29m59s without extending on reload');
w:advance(1);copy.lastCast=nil;freed.lastCast=nil;w:say(copy,alt,'i am ready');w:say(freed,alt,'ready to return');
check(not copy.valid and not freed.valid and not copy.lastCast and not freed.lastCast,'both Tylis routes expire at Keeper plus thirty minutes');
check(projection.valid,'Saryrn projection remains alive after the independent Tylis window ends');
alt.items[22954]=true;w:say(copy,alt,'i am ready');check(not copy.lastCast,'sphere cannot reopen expired temporary entrance');
check(#w.respawns==1,'temporary cleanup does not restart native Tylis cooldown');
late.globals.tylis='2';w:say(projection,late,'hail');check(late.globals.saryrn=='1','Saryrn reward remains usable after Tylis depops');
w:advance(600);check(not projection.valid,'Saryrn projection ends thirty minutes after its own spawn');
-- Keeper-only attempt expires without requiring Saryrn to spawn at all.
w=world();main=w:client(10);w:npc(207014);w:kill(w:npc(207015),main);copy=w:get(207014);freed=w:get(207318);
w:advance(1799);check(copy.valid and freed.valid,'Keeper-only rescue window remains open at 29m59s');
w:advance(1);check(not copy.valid and not freed.valid,'both copies expire without Saryrn ever spawning');
-- Early projection removal and a replacement projection never change Keeper's window.
w=world();main=w:client(10);alt=w:client();alt.globals.tylis='1';w:npc(207014);w:kill(w:npc(207015),main);
copy=w:get(207014);freed=w:get(207318);deadline=copy.vars.flagging_travel_fixed_deadline;
w:advance(300);projection=w:npc(207317);projection:Depop();w:advance(10);w:say(copy,alt,'i am ready');
check(copy.valid and freed.valid and copy.lastCast,'removing Saryrn projection does not close Tylis travel');
w:npc(207317);check(copy.vars.flagging_travel_fixed_deadline==deadline and freed.vars.flagging_travel_fixed_deadline==deadline,'replacement Saryrn projection does not restart rescue window');
w.env.require('flagging_travel').StartFixed(copy,w.now+1800);
check(copy.vars.flagging_travel_fixed_deadline==deadline,'repeated setup cannot extend a fixed window');
w:advance(1490);check(not copy.valid and not freed.valid,'projection replacement and repeated setup still expire at original Keeper deadline');
-- Fresh zones require the sphere; a projection alone cannot mark Keeper defeated.
w=world();alt=w:client();alt.globals.tylis='1';entrance=w:npc(207014);
w:say(entrance,alt,'i am ready');check(not entrance.lastCast,'fresh zone does not inherit a previous Keeper sphere waiver');
w:npc(207317);w:say(entrance,alt,'i am ready');check(not entrance.lastCast,'projection alone cannot unlock entrance without Keeper death');
alt.items[22954]=true;w:say(entrance,alt,'i am ready');check(entrance.lastCast and entrance.lastCast[1]==1134,'ordinary entrance still accepts preflag plus personal sphere');
-- Rescued Tylis has a bounded fallback if spawned manually; Keeper can shorten
-- it to the exact death time, and a later spawn callback must not extend it.
w=world();freed=w:npc(207318);local travel=w.env.require('flagging_travel');
travel.StartFixed(freed,w.now+1799);deadline=freed.vars.flagging_travel_fixed_deadline;
travel.StartFixed(freed,w.now+1800);check(freed.vars.flagging_travel_fixed_deadline==deadline,'spawn fallback cannot extend Keeper-supplied shared deadline');
w:advance(1799);check(not freed.valid,'fixed fallback deadline is respected');
-- BoT: prerequisite kills still create each stage, with no transport lost at Emmerik.
w=world();main=w:client(10);alt=w:client(10);stranger=w:client(20);
check(not w:get(209156).valid and not w:get(209157).valid and not w:get(209158).valid,'tower route absent before prerequisite kills');
w:kill(w:npc(900001),main);local lower=w:get(209156);
check(lower.valid and not w:get(209157).valid,'Evynd opens only his own travel stage');
w:say(lower,alt,'transport');check(alt.lastMove[4]==1729,'lower Askr transports to Emmerik floor');
w:kill(w:npc(900002),main);local upper=w:get(209157);check(lower.valid and upper.valid,'Emmerik leaves lower Askr available');
w:say(upper,alt,'what storm');local vortex=w:get(209158);check(vortex.valid,'upper Askr still requires dialogue to create vortex');
w:advance(7200);check(lower.valid and upper.valid and vortex.valid,'tower route survives a long encounter before Karana');
w:kill(w:npc(900003),main);local karana=w:get(209136);
check(lower.valid and upper.valid and vortex.valid,'Askr and vortex must survive Karana event_spawn before entity-list registration');
check(karana.valid and lower.vars.flagging_travel_deadline==tostring(w.now+1200),'Karana starts twenty-minute travel window');
check(w.timers[karana.id..':depop'].ms==1200000,'Karana despawn matches the twenty-minute travel deadline');
alt.lastMove=nil;w:say(lower,alt,'transport');check(lower.valid and alt.lastMove and alt.lastMove[4]==1729,'late alt can use lower Askr immediately after Karana spawns');
alt.globals.karana='3';w:say(karana,alt,'follow the path of the Fallen');check(alt.globals.karana=='4','late raid alt can still earn Karana flag');
local noquest=w:client(10);w:say(karana,noquest,'follow the path of the Fallen');check(noquest.globals.cl_karana=='1' and not noquest.globals.karana,'Karana quest prerequisite preserved');
local messagesBeforeRepeat=#w.messages;
for i=1,100 do w:say(karana,noquest,'follow the path of the Fallen');end
check(#w.messages==messagesBeforeRepeat,'repeated Karana checklist requests do not grant more flags during travel window');
local nextAlt=w:client(10);nextAlt.globals.karana='3';w:say(karana,nextAlt,'follow the path of the Fallen');
check(nextAlt.globals.karana=='4','another eligible alt still flags after one character repeats Karana dialogue one hundred times');
stranger.globals.karana='3';w:say(karana,stranger,'follow the path of the Fallen');check(stranger.globals.karana=='3','unrelated raid still cannot earn Karana flag');
local player=w:player();player.event_click_door({self=alt,door={GetDoorID=function()return 51;end}});alt.lastMove=nil;
player.event_click_door({self=alt,door={GetDoorID=function()return 51;end}});check(not alt.lastMove,'tower key requirement not removed');
main.cursor=9433;player.event_click_door({self=main,door={GetDoorID=function()return 51;end}});
player.event_click_door({self=alt,door={GetDoorID=function()return 51;end}});check(alt.lastMove and alt.lastMove[4]==1270,'original keyed raid tower admission still works');
w:advance(900);vortex:Depop();w:say(upper,alt,'what storm');vortex=w:get(209158);
check(vortex.vars.flagging_travel_deadline==karana.vars.flagging_travel_deadline,'late-created vortex inherits only remaining five minutes');
player.event_click_merchant({self=alt,merchant_type_id=209158});check(alt.lastMove[4]==2251,'merchant event works with real API type ID, without e.other');
w:advance(299);w:reload(upper);w:say(upper,alt,'what storm');check(upper.valid and lower.valid and vortex.valid,'entire route available at 19m59s');
w:advance(1);alt.lastMove=nil;player.event_click_merchant({self=alt,merchant_type_id=209158});
w:say(lower,alt,'transport');w:say(upper,alt,'what storm');
check(not alt.lastMove and not lower.valid and not upper.valid and not vortex.valid and not karana.valid,'all tower transport closes with Karana');
-- Early flagger removal closes travel; a fresh zone has no earned route state.
w=world();main=w:client(10);w:kill(w:npc(900001),main);lower=w:get(209156);w:kill(w:npc(900003),main);karana=w:get(209136);
karana:Depop();w:advance(10);check(not lower.valid,'removed final flagger cleans up its route');
local fresh=world();check(not fresh:get(209156).valid,'new zone has no persistent route bypass');
check(w.env.require('flagging_travel').CanUse(nil)==false,'missing merchant is rejected safely');
print('PASS flagging travel: '..checks..' checks; actual encounter callbacks, requirements, late alts, deadlines, cleanup and reloads.');
