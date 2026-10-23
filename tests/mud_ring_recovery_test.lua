-- Lua 5.1: lua tests/mud_ring_recovery_test.lua /path/to/Quests
local root=arg[1] or ".";
local f=assert(io.open(root.."/poeartha/encounters/MudRing.lua"));local source=f:read("*a");f:close();
local checks=0;
local function check(ok,msg) assert(ok,msg);checks=checks+1;end
local BLUE,RED,RUNNER,LURKER,CONTROL=218317,218418,218419,218357,218394;
local function world()
 local w={now=1000000,nextid=1,npcs={},timers={},writes={},points={},logs={},handlers={},signals={}};
 local env,owner;
 local function live(n)return n and n.valid and n.hp>0 and not n.corpse;end
 function w:list(typ)local r={};for _,n in pairs(self.npcs)do if live(n)and n.typ==typ then r[#r+1]=n;end end;return r;end
 function w:one(typ)return self:list(typ)[1];end
 function w:dispatch(event,n,extra)
  local cb=self.handlers[event..":"..n.typ];if cb then
   local prev=owner;owner=n;local e=extra or{};e.self=n;cb(e);owner=prev;
  end
 end
 function w:spawn(typ,x,y,z)
  if self.throw==typ then error("injected spawn exception");end
  if self.fail==typ then return{valid=false};end
  local n={id=self.nextid,typ=typ,valid=true,hp=100,vars={},abilities={},body=11,x=x or 340,y=y or 90,z=z or 71};self.nextid=self.nextid+1;self.npcs[n.id]=n;
  function n:GetID()return self.corpse and 0 or self.id;end
  function n:GetNPCTypeID()return self.typ;end
  function n:GetHP()return self.hp;end
  function n:GetMaxHP()return 100;end
  function n:IsCorpse()return self.corpse or false;end
  function n:GetX()return self.x;end;function n:GetY()return self.y;end;function n:GetZ()return self.z;end
  function n:SetHP(hp)self.hp=hp;end
  function n:SetEntityVariable(k,v)self.vars[k]=v;end;function n:GetEntityVariable(k)return self.vars[k]or"";end
  function n:SetSpecialAbility(k,v)self.abilities[k]=v;end;function n:SetBodyType(v)self.body=v;end
  function n:SetRunning(v)self.running=v;end;function n:MoveTo(x,y,z)self.destination={x,y,z};end
  function n:CastToNPC()return self;end
  function n:Depop()self.valid=false;end
  self:dispatch("spawn",n);return n;
 end
 function w:kill(n)n.hp=0;n.corpse=true;self:dispatch("death",n);end
 local el={};
 function el:GetMob(id)return w.npcs[id]or{valid=false};end
 function el:GetNPCByNPCTypeID(typ)return w:one(typ)or{valid=false};end
 function el:GetMobByNpcTypeID(typ)return self:GetNPCByNPCTypeID(typ);end
 function el:IsMobSpawnedByNpcTypeID(typ)return w:one(typ)~=nil;end
 function el:MessageClose()end
 function el:GetSpawnByID(id)
  if not w.points[id]then
   local p={valid=true,enabled=true};function p:Enable()self.enabled=true;end;function p:Disable()self.enabled=false;end;function p:SetTimer(ms)self.timer=ms;end
   w.points[id]=p;
  end
  return w.points[id];
 end
 local eq={
  get_entity_list=function()return el;end,
  register_npc_event=function(group,event,typ,cb)check(group=="MudRing","registrations remain MudRing-owned");w.handlers[event..":"..typ]=cb;end,
  spawn2=function(typ,_,__,x,y,z)return w:spawn(typ,x,y,z);end,
  set_timer=function(name,ms,n)n=n or owner or w.encounter;w.timers[tostring(n)..name]={name=name,at=w.now+ms/1000,ms=ms,owner=n};end,
  stop_timer=function(name,n)w.timers[tostring(n or owner or w.encounter)..name]=nil;end,
  pause_timer=function(name)local t=w.timers[tostring(owner)..name];if t then t.paused=true;end end,
  resume_timer=function(name)local t=w.timers[tostring(owner)..name];if t then t.paused=false;t.at=w.now+t.ms/1000;end end,
  set_next_hp_event=function()end,
  depop_all=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  depop=function()if owner and owner.Depop then owner:Depop();end end,
  depop_with_timer=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  update_spawn_timer=function(id,ms)w.writes[#w.writes+1]={id=id,ms=ms};end,
  debug=function(msg)w.logs[#w.logs+1]=msg;end,
  zone_emote=function()end,
  signal=function(typ,value)w.signals[#w.signals+1]={typ,value};end
 };
 function w:load()
  self.handlers={};self.timers={};self.encounter={};
  env=setmetatable({eq=eq,os={time=function()return w.now;end},Event={spawn="spawn",death_complete="death",combat="combat",timer="timer",waypoint_arrive="arrive",signal="signal",hp="hp"}},{__index=_G});
  setfenv(assert(loadstring(source)),env)();self.env=env;env.event_encounter_load({encounter=self.encounter});
 end
 function w:tick(seconds)
  self.now=self.now+seconds;
  local due={};for _,t in pairs(self.timers)do if not t.paused and t.owner~=self.encounter and t.at<=self.now and live(t.owner)then due[#due+1]=t;end end
  for _,t in ipairs(due)do if live(t.owner)then self:dispatch("timer",t.owner,{timer=t.name});end end
  if env.event_timer then env.event_timer({timer="mud_watchdog"});end
 end
 function w:start()
  local blue={};for i=1,16 do blue[i]=self:spawn(BLUE);end
  for _,n in ipairs(blue)do if live(n)then self:kill(n);end end
  return self:one(LURKER);
 end
 function w:reds()local red=self:list(RED);for _,n in ipairs(red)do self:kill(n);end;return red;end
 function w:arrive()for _,n in ipairs(self:list(RUNNER))do self:dispatch("arrive",n);end end
 function w:cooldown(ms)
  local seen={};for _,r in ipairs(self.writes)do check(r.ms==ms,"cooldown duration unchanged");seen[r.id]=true;end
  local count=0;for id in pairs(seen)do count=count+1;check(self.points[id].enabled,"trigger re-enabled");end
  check(count==16,"exactly sixteen trigger spawnpoints updated");
 end
 w:load();w:tick(0);return w;
end

local w=world();local boss=w:start();check(boss and boss.body==11,"Lurker initially protected");
local reds=w:reds();check(#reds==16 and #w:list(RUNNER)==64,"sixteen red kills create normal64-runner animation");
w:arrive();check(boss.body==24 and boss.abilities[35]==0,"normal arrivals unlock immediately");
check(#w.signals==0,"activation does not depend on queued signal");check(#w:list(RUNNER)==0,"runners cleaned after activation");

for _,failure in ipairs({"absent","stuck","throw"})do
 w=world();boss=w:start();if failure=="absent"then w.fail=RUNNER;elseif failure=="throw"then w.throw=RUNNER;end
 w:reds();w:tick(29);check(boss.body==11,"no early fallback before grace");w:tick(1);
 check(boss.body==24 and #w:list(RUNNER)==0,"missing/stuck runner fallback unlocks and cleans animation");
 check(#w.writes==0,"fallback does not award loot cooldown or clear event");
end
w=world();boss=w:start();reds=w:list(RED);for i=1,15 do w:kill(reds[i]);end
local runner=w:one(RUNNER);for i=1,70 do w:dispatch("arrive",runner);end
w:tick(31);check(boss.body==11,"duplicate arrivals cannot bypass living sixteenth red");
w:dispatch("death",reds[1]);w:tick(31);check(boss.body==11,"duplicate red deaths cannot forge completion");
w:kill(reds[16]);w:tick(30);check(boss.body==24,"last genuine kill allows fallback");

w=world();boss=w:start();reds=w:list(RED);reds[1]:Depop();for i=2,16 do w:kill(reds[i]);end
w:tick(1);w:tick(30);check(not boss.valid and #w:list(RUNNER)==0,"missing required red fails instead of unlocking");w:cooldown(900000);
local writes=#w.writes;w:tick(60);check(#w.writes==writes,"failure is idempotent and never extends cooldown");
local old=reds[1];w.writes={};boss=w:start();w:dispatch("death",old);w:tick(31);check(boss.body==11 and #w:list(RED)==16,"old generation cannot advance retry");w:reds();w:arrive();check(boss.body==24,"new attempt starts with clean counters");

for _,fault in ipairs({"fail","throw"})do for _,typ in ipairs({RED,CONTROL,LURKER})do
 w=world();w[fault]=typ;w:start();check(not w:one(LURKER)and #w:list(RED)==0,"failed required spawn cleans attempt");w:cooldown(900000);
end end
w=world();boss=w:start();w:one(CONTROL):Depop();w:tick(1);w:tick(30);check(not boss.valid,"missing timeout controller cannot leave a permanent event");w:cooldown(900000);
w=world();boss=w:start();w:tick(5880);check(not boss.valid,"original98-minute timeout cleans event");w:cooldown(900000);
w=world();boss=w:start();w:reds();w:load();w:tick(0);check(not boss.valid and #w:list(RUNNER)==0,"reload of active event safely retries instead of granting progress");w:cooldown(900000);

-- Exercise the normal fight through its four split waves and final boss.
w=world();boss=w:start();w:reds();w:arrive();
for i=1,4 do
 w:dispatch("hp",boss);check(#w:list(218358)==10,"Lurker split still produces10 mudlets");
 for _,n in ipairs(w:list(218358))do w:kill(n);end
 boss=w:one(LURKER);check(boss and boss.hp==100-i*20,"Lurker returns at next HP stage");
end
w:kill(boss);check(#w:list(218359)==4,"Lurker death still produces4 gorgers");
w:spawn(218390);for _,n in ipairs(w:list(218359))do w:kill(n);end
local final=w:one(218360);check(final~=nil,"normal loot boss still requires gorger kills");
w:spawn(218361);w:kill(final);w:cooldown(237600000);
check(#w:list(CONTROL)==0 and #w:list(218361)==0,"success cleans controller and leftover adds");
writes=#w.writes;w:dispatch("death",final);check(#w.writes==writes,"duplicate final death cannot extend success cooldown");
check(#w.signals==1 and w.signals[1][1]==218393 and w.signals[1][2]==2,"only normal victory signals Arbitor");
w=world();local blue=w:spawn(BLUE);w:kill(blue);w:dispatch("death",blue);check(#w:list(RED)==1 and not w:one(LURKER),"duplicate blue death cannot create another required red");
print("PASS: "..checks.." Mud Ring recovery checks");
