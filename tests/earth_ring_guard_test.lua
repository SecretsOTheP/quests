-- Lua 5.1: lua tests/earth_ring_guard_test.lua /path/to/Quests
local root=arg[1] or ".";
local checks=0;
local function check(ok,msg) assert(ok,msg);checks=checks+1;end
local function source(path)local f=assert(io.open(root.."/"..path));local s=f:read("*a");f:close();return s;end
local function world(ring)
 local w={now=1000000,nextid=1,npcs={},writes={},points={},handlers={},signals={},logs={},timers={},announcements={}};
 local env,owner;
 local function live(n)return n and n.valid and n.hp>0 and not n.corpse;end
 function w:list(typ)local r={};for _,n in pairs(self.npcs)do if live(n)and n.typ==typ then r[#r+1]=n;end end;return r;end
 function w:one(typ)return self:list(typ)[1];end
 function w:dispatch(event,n,extra)
  local cb=self.handlers[event..":"..n.typ];if cb then local prev=owner;owner=n;local e=extra or{};e.self=n;cb(e);owner=prev;end
 end
 function w:spawn(typ,x,y,z)
  if self.throw==typ then error("injected spawn exception");end
  if self.fail==typ then return{valid=false};end
  local n={id=self.nextid,typ=typ,valid=true,hp=100,vars={},abilities={},body=11,x=x or 0,y=y or 0,z=z or 0};self.nextid=self.nextid+1;self.npcs[n.id]=n;
  function n:GetID()return self.corpse and 0 or self.id;end
  function n:GetNPCTypeID()return self.typ;end
  function n:GetHP()return self.hp;end;function n:GetMaxHP()return 100;end
  function n:IsCorpse()return self.corpse or false;end
  function n:GetX()return self.x;end;function n:GetY()return self.y;end;function n:GetZ()return self.z;end
  function n:SetHP(hp)self.hp=hp;end;function n:Heal()self.hp=100;end
  function n:SetEntityVariable(k,v)self.vars[k]=v;end;function n:GetEntityVariable(k)return self.vars[k]or"";end
  function n:SetSpecialAbility(k,v)self.abilities[k]=v;end;function n:GetSpecialAbility(k)return self.abilities[k]or 0;end
  function n:SetBodyType(v)self.body=v;end;function n:BuffFadeAll()end;function n:WipeHateList()self.engaged=false;end
  function n:IsEngaged()return self.engaged or false;end
  function n:SetRunning(v)self.running=v;end;function n:MoveTo(x,y,z)self.destination={x,y,z};end
  function n:CastToNPC()return self;end;function n:SetAppearance()end
  function n:Depop()self.valid=false;end
  self:dispatch("spawn",n);return n;
 end
 function w:kill(n)assert(n,"missing test NPC");n.hp=0;n.corpse=true;self:dispatch("death",n);return n;end
 function w:killAll(typ)for _,n in ipairs(self:list(typ))do self:kill(n);end end
 local el={};
 function el:GetMob(id)return w.npcs[id]or{valid=false};end
 function el:GetMobByNpcTypeID(typ)return w:one(typ)or{valid=false};end
 function el:IsMobSpawnedByNpcTypeID(typ)return w:one(typ)~=nil;end
 function el:MessageClose()end
 function el:GetNPCList()
  local values={};for _,n in pairs(w.npcs)do if live(n)then values[#values+1]=n;end end;local i=0;
  return{entries=function()i=i+1;return values[i];end};
 end
 function el:GetSpawnByID(id)
  if not w.points[id]then local p={valid=true,enabled=true};function p:Enable()self.enabled=true;end;function p:Disable()self.enabled=false;end;w.points[id]=p;end
  return w.points[id];
 end
 local eq={get_entity_list=function()return el;end,
  register_npc_event=function(group,event,typ,cb)assert(group==ring.."Ring");w.handlers[event..":"..typ]=cb;end,
  spawn2=function(typ,_,__,x,y,z)return w:spawn(typ,x,y,z);end,
  set_timer=function(name,ms,n)w.timers[name]={ms=ms,owner=n or owner};end,
  stop_timer=function()end,pause_timer=function()end,resume_timer=function()end,set_next_hp_event=function()end,
  depop_all=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  depop=function()if owner then owner:Depop();end end,
  depop_with_timer=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  update_spawn_timer=function(id,ms)w.writes[#w.writes+1]={id=id,ms=ms};end,
  debug=function(msg)w.logs[#w.logs+1]=msg;end,zone_emote=function(color,msg)if color==15 then w.announcements[#w.announcements+1]=msg;end end,
  signal=function(typ,value)w.signals[#w.signals+1]={typ,value};end};
 function w:load()
  self.handlers={};self.timers={};self.encounter={};
  env=setmetatable({eq=eq,os={time=function()return w.now;end},Event={spawn="spawn",death_complete="death",combat="combat",timer="timer",waypoint_arrive="arrive",hp="hp"}},{__index=_G});
  env.require=function(name)assert(name=="earth_ring_guard");return setfenv(assert(loadstring(source("lua_modules/earth_ring_guard.lua"))),env)();end;
  setfenv(assert(loadstring(source("poeartha/encounters/"..ring.."Ring.lua"))),env)();self.env=env;env.event_encounter_load({encounter=self.encounter});
 end
 function w:tick(seconds)self.now=self.now+(seconds or 5);env.event_timer({timer="earth_guard"});end
 function w:begin()
  if ring=="Dust"then self:kill(self:spawn(218022));
  elseif ring=="Stone"then
   for _,typ in ipairs({218031,218030,218032,218033})do self:spawn(typ);self:spawn(typ);end
   for _,typ in ipairs({218031,218030,218032,218033})do self:killAll(typ);end
  else for i=1,30 do self:spawn(218019);end;self:killAll(218019);end
 end
 function w:failed()
  check(#self.announcements==1,"failure emits one RP message");
  check(self.announcements[1]:find("15 minutes"),"public message preserves retry duration");
  check(not self.announcements[1]:find("Phase:") and not self.announcements[1]:find("type="),"public RP excludes diagnostics");
  self:tick(30);
  check(#self.announcements==1,"later watchdog ticks do not repeat failure messages");
  check(#self.writes>0,"failure writes retry timers");
  for _,r in ipairs(self.writes)do check(r.ms==900000 and self.points[r.id].enabled,"15-minute retry saved and enabled");end
  check(#self.signals==0,"failure never grants Arbitor credit");
 end
 w:load();return w;
end

-- Dust: real deaths required, duplicate callbacks ignored, successful clear retained.
local w=world("Dust");w:spawn(218412);w:begin();check(#w:list(218366)==37 and #w:list(218367)==3,"Dust initial waves unchanged");
local d=w:kill(w:one(218366));w:dispatch("death",d);w:killAll(218366);
check(w:one(218367).body==24,"all 37 devotee deaths unlock Triumvirates");
local tri=w:kill(w:one(218367));w:dispatch("death",tri);check(not w:one(218413),"duplicate Triumvirate kill cannot advance");
w:killAll(218367);check(w:one(218413),"three real Triumvirate deaths spawn real boss");
w:spawn(218414);w:spawn(218421);local boss=w:kill(w:one(218413));w:dispatch("death",boss);
check(#w.signals==1 and w.writes[1].ms==237600000,"Dust success exactly once with 66-hour lockout");
check(not w:one(218414)and not w:one(218421)and not w:one(218397),"Dust success cleans leftover adds and controller");
w:tick(6000);check(#w.writes==1,"completed run cannot later fail");
w=world("Dust");w:begin();w:one(218366):Depop();w:killAll(218366);check(w:one(218367).body==11,"missing devotee does not count as kill");w:tick();w:tick(30);w:failed();
w=world("Dust");w:begin();w:killAll(218366);w:one(218367):Depop();w:killAll(218367);check(not w:one(218415),"missing Triumvirate cannot grant boss");w:tick();w:tick(30);w:failed();

-- Vine: all 30 tainted and all 10 bloodthirsty kills remain required.
w=world("Vine");w:spawn(218392);w:begin();check(#w:list(218362)==10 and w:one(218362).body==25,"Vine spawns and unlocks ten Bloodthirsties");
d=w:kill(w:one(218362));w:dispatch("death",d);w:killAll(218362);check(w:one(218363),"ten confirmed kills spawn Derugoak");
w:spawn(218420);boss=w:kill(w:one(218363));w:dispatch("death",boss);check(#w.signals==1 and #w.writes==30,"Vine success occurs once");
for _,r in ipairs(w.writes)do check(r.ms==237600000,"Vine success remains 66 hours");end
check(not w:one(218420)and not w:one(218396),"Vine success cleans adds and controller");
w=world("Vine");w:begin();w:one(218362):Depop();w:killAll(218362);check(not w:one(218364),"missing Bloodthirsty cannot count as kill");w:tick();w:tick(30);w:failed();
w=world("Vine");for i=1,30 do w:spawn(218019);end;for i=1,3 do d=w:kill(w:one(218019));w:dispatch("death",d);end
check(#w:list(218362)==1,"duplicate tainted deaths cannot spawn extra waves");w:one(218019):Depop();w:killAll(218019);check(w:one(218362).body==11,"missing native trigger cannot unlock wave");w:tick();w:tick(30);w:failed();

-- Stone: four confirmed weakenings, then allow 30 seconds for cosmetic travel.
local function rubbleWorld()
 local s=world("Stone");s:begin();check(#s:list(218369)==43,"all 43 fortifications required");
 local first=s:kill(s:one(218369));s:dispatch("death",first);s:killAll(218369);
 check(#s:list(218370)==4,"43 unique deaths spawn four rubbles");return s;
end
w=rubbleWorld();local rubbles=w:list(218370);
for i=1,3 do w:dispatch("hp",rubbles[i],{hp_event=20});end
w:tick(40);check(not w:one(218371),"three weakened rubbles never advance");
w:dispatch("hp",rubbles[4],{hp_event=20});w:dispatch("hp",rubbles[4],{hp_event=20});
for _,n in ipairs(rubbles)do n.x=n.x+100;n.y=n.y+100;end
w:tick(29);check(not w:one(218371),"return path gets full grace");w:tick(1);check(#w:list(218371)==1 and #w:list(218370)==0,"stuck returns recover after all four weakenings");
w:dispatch("arrive",rubbles[4]);w:tick();check(#w:list(218371)==1,"late arrivals cannot duplicate Monstrosity");
w:killAll(218371);check(#w:list(218372)==4,"Monstrosity death starts heaps");
for i=1,6 do local heaps=w:list(218372);for _,n in ipairs(heaps)do w:kill(n);w:dispatch("death",n);end end
check(w:one(218373) and not w:one(218374),"24 unique heap deaths replace placeholder with nonloot boss when marker absent");
boss=w:kill(w:one(218373));w:dispatch("death",boss);check(#w.signals==1 and #w.writes==9,"Stone success saved once for all native points");
for _,r in ipairs(w.writes)do check(r.ms==237600000,"Stone success remains 66 hours");end
w=rubbleWorld();rubbles=w:list(218370);for i=1,4 do w:dispatch("hp",rubbles[i],{hp_event=20});end
w:dispatch("arrive",rubbles[1]);check(w:one(218371),"normal home arrival advances immediately");
w=rubbleWorld();rubbles=w:list(218370);for i=1,3 do w:dispatch("hp",rubbles[i],{hp_event=20});end;rubbles[4]:Depop();w:tick();w:tick(30);w:failed();
w=rubbleWorld();rubbles=w:list(218370);for i=1,4 do w:dispatch("hp",rubbles[i],{hp_event=20});rubbles[i]:Depop();end;w:tick(30);check(w:one(218371),"disappeared cosmetic rubble after four weakenings cannot stall transition");

-- Independent missing-controller recovery, failed spawns, reloads, no false credit.
for _,cfg in ipairs({{"Dust",218397,218366},{"Stone",218395,218369},{"Vine",218396,218362}})do
 local ring,controller,required=unpack(cfg);
 w=world(ring);w:begin();w:one(controller):Depop();w:tick();check(#w.writes==0,"missing controller gets grace");w:tick(30);w:failed();
 local writes=#w.writes;w:tick(6000);check(#w.writes==writes,"failure is idempotent");
 w=world(ring);w:begin();w:tick(5880);w:failed();
 w=world(ring);w.fail=required;w:begin();w:failed();
 w=world(ring);w.throw=required;w:begin();w:failed();
 w=world(ring);w:begin();w:load();w:tick();w:failed();
 w=world(ring);w:begin();local lost=w:one(required);local id=lost.id;lost:Depop();local replacement=w:spawn(required);w.npcs[id]=replacement;w:tick();w:tick(30);w:failed();
 -- A new attempt must work after cleanup; old callbacks cannot affect it.
 w=world(ring);w:begin();local oldController=w:one(controller);local oldRequired=w:one(required);
 w:tick(5880);w:failed();w.writes={};w:begin();w:dispatch("death",oldRequired);w:dispatch("timer",oldController,{timer="depop"});w:tick();
 check(#w.writes==0 and w:one(controller),"new attempt ignores stale controller/death callbacks");
end
print("PASS: "..checks.." Earth ring recovery checks");
