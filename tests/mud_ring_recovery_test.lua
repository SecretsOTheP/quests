-- Lua 5.1: lua tests/mud_ring_recovery_test.lua /path/to/Quests
local root=arg[1] or ".";
local f=assert(io.open(root.."/poeartha/encounters/MudRing.lua"));local source=f:read("*a");f:close();
local checks=0;
local function check(ok,msg) assert(ok,msg);checks=checks+1;end
local BLUE,RED,RUNNER,LURKER,CONTROL=218317,218418,218419,218357,218394;
local BLUE_POINTS={365291,365399,365409,365587,365808,366045,366470,366646,366691,366737,366743,366840,366891,366929,367013,367097};
local function world()
 local w={now=1000000,nextid=1,npcs={},timers={},writes={},points={},logs={},handlers={},signals={},rp={},checkpoints={}};
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
  local n={id=self.nextid,typ=typ,valid=true,hp=100,vars={},abilities={},body=11,x=x or 340,y=y or 90,z=z or 71};self.nextid=self.nextid+1;if not self.deferSpawnInsert then self.npcs[n.id]=n;end
  if typ==BLUE then self.blueSpawns=(self.blueSpawns or 0)+1;n.spawnid=BLUE_POINTS[(self.blueSpawns-1)%16+1];end
  function n:GetID()return self.corpse and 0 or self.id;end
  function n:GetSpawnPointID()return self.spawnid or 0;end
  function n:GetNPCTypeID()return self.typ;end
  function n:GetHP()return self.hp;end
  function n:GetMaxHP()return 100;end
  function n:IsCorpse()return self.corpse or false;end
  function n:GetX()return self.x;end;function n:GetY()return self.y;end;function n:GetZ()return self.z;end
  function n:SetHP(hp)self.hp=hp;end
  function n:SetEntityVariable(k,v)self.vars[k]=v;end;function n:GetEntityVariable(k)return self.vars[k]or"";end
  function n:SetSpecialAbility(k,v)self.abilities[k]=v;end;function n:SetBodyType(v)self.body=v;end
  function n:SetRunning(v)self.running=v;end;function n:MoveTo(x,y,z)if w.throwMove==self.typ then w.throwMove=nil;error("injected movement exception");end;self.destination={x,y,z};end
  function n:CastToNPC()return self;end
  function n:Depop()if w.deferDepop then self.pending_depop=true;else self.valid=false;end end
  self:dispatch("spawn",n);if self.deferSpawnInsert then self.npcs[n.id]=n;end;return n;
 end
 function w:kill(n)n.hp=0;n.corpse=true;self:dispatch("death",n);end
 function w:flushDepops()
  for _,n in pairs(self.npcs)do if n.pending_depop then
   n.valid=false;
   for key,t in pairs(self.timers)do if t.owner==n then self.timers[key]=nil;end end
  end end
 end
 local el={};
 function el:GetMob(id)return w.npcs[id]or{valid=false};end
 function el:GetNPCByNPCTypeID(typ)return w:one(typ)or{valid=false};end
 function el:GetMobByNpcTypeID(typ)return self:GetNPCByNPCTypeID(typ);end
 function el:IsMobSpawnedByNpcTypeID(typ)return w:one(typ)~=nil;end
 function el:GetNPCList()
  local values={};for _,n in pairs(w.npcs)do if live(n)then values[#values+1]=n;end end;local i=0;
  return{entries=function()i=i+1;return values[i];end};
 end
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
  set_timer=function(name,ms,n)if w.throwTimer==name then w.throwTimer=nil;error("injected timer exception");end;n=n or owner or w.encounter;w.timers[tostring(n)..name]={name=name,at=w.now+ms/1000,ms=ms,owner=n};end,
  stop_timer=function(name,n)w.timers[tostring(n or owner or w.encounter)..name]=nil;end,
  pause_timer=function(name)local t=w.timers[tostring(owner)..name];if t then t.paused=true;end end,
  resume_timer=function(name)local t=w.timers[tostring(owner)..name];if t then t.paused=false;t.at=w.now+t.ms/1000;end end,
  set_next_hp_event=function()end,
  depop_all=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  depop=function()if owner and owner.Depop then owner:Depop();end end,
  depop_with_timer=function(typ)for _,n in ipairs(w:list(typ))do n:Depop();end end,
  update_spawn_timer=function(id,ms)w.writes[#w.writes+1]={id=id,ms=ms};end,
  debug=function(msg)w.logs[#w.logs+1]=msg;end,
  zone_emote=function(color,message)assert(color==13,"ring RP must be red");if not message:find("Ring has reset;",1,true) then w.rp[#w.rp+1]={text=message,writes=#w.writes,signals=#w.signals};end end,
  signal=function(typ,value)w.signals[#w.signals+1]={typ,value};end
 };
 function w:load()
  self.handlers={};self.timers={};self.encounter={};
  env=setmetatable({eq=eq,os={time=function()return w.now;end},Event={spawn="spawn",death_complete="death",combat="combat",timer="timer",waypoint_arrive="arrive",signal="signal",hp="hp"}},{__index=_G});
  env.require=function(name)
   assert(name=="earth_ring_progress");
   local module=setfenv(assert(loadfile(root.."/lua_modules/"..name..".lua")),env)();local announce=module.announce;
   module.announce=function(count,total,halfText,nearText)
    local before=#w.rp;announce(count,total,halfText,nearText);
    if #w.rp>before then w.checkpoints[#w.checkpoints+1]={count=count,total=total};end
   end;
   return module;
  end;
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
 function w:checkpointCount(count,total)
  local found=0;for _,p in ipairs(self.checkpoints)do if p.count==count and p.total==total then found=found+1;end end;return found;
 end
 function w:rpCount(text)
  local found=0;for _,message in ipairs(self.rp)do if message.text:find(text,1,true)then found=found+1;end end;return found;
 end
 w:load();w:tick(0);return w;
end

local w=world();local boss=w:start();check(boss and boss.body==11,"Lurker initially protected");
check(w:checkpointCount(8,16)==1 and w:checkpointCount(15,16)==1,"opening blue wave announces its midpoint and near-completion once");
local reds=w:reds();check(#reds==16 and #w:list(RUNNER)==64,"sixteen red kills create normal64-runner animation");
check(w:checkpointCount(8,16)==2 and w:checkpointCount(15,16)==2,"red wave has independent midpoint and near-completion checkpoints");
check(w:rpCount("The Sludge Lurker heaves free")==0,"red completion RP waits for actual Lurker activation");
w:arrive();check(boss.body==24 and boss.abilities[35]==0,"normal arrivals unlock immediately");
check(w:rpCount("The Sludge Lurker heaves free")==1,"normal arrivals announce Lurker activation once");
for _,n in ipairs(reds)do w:dispatch("death",n);end;w:arrive();
check(w:checkpointCount(8,16)==2 and w:checkpointCount(15,16)==2 and w:rpCount("The Sludge Lurker heaves free")==1,"duplicate red deaths and runner arrivals do not repeat progress RP");
check(#w.signals==0,"activation does not depend on queued signal");check(#w:list(RUNNER)==0,"runners cleaned after activation");

for _,failure in ipairs({"absent","stuck","throw"})do
 w=world();boss=w:start();if failure=="absent"then w.fail=RUNNER;elseif failure=="throw"then w.throw=RUNNER;end
 w:reds();w:tick(29);check(boss.body==11,"no early fallback before grace");w:tick(1);
 check(boss.body==24 and #w:list(RUNNER)==0,"missing/stuck runner fallback unlocks and cleans animation");
 check(#w.writes==0,"fallback does not award loot cooldown or clear event");
 check(w:rpCount("The Sludge Lurker heaves free")==1,"runner recovery announces the actual phase advance without reset RP");
end
w=world();boss=w:start();reds=w:list(RED);for i=1,15 do w:kill(reds[i]);end
local runner=w:one(RUNNER);for i=1,70 do w:dispatch("arrive",runner);end
w:tick(31);check(boss.body==11,"duplicate arrivals cannot bypass living sixteenth red");
w:dispatch("death",reds[1]);w:tick(31);check(boss.body==11,"duplicate red deaths cannot forge completion");
w:kill(reds[16]);w:tick(30);check(boss.body==24,"last genuine kill allows fallback");

w=world();boss=w:start();reds=w:list(RED);reds[1]:Depop();for i=2,16 do w:kill(reds[i]);end
w:tick(1);w:tick(30);check(not boss.valid and #w:list(RUNNER)==0,"missing required red fails instead of unlocking");w:cooldown(900000);
check(w:rpCount("The Sludge Lurker heaves free")==0,"missing red never announces a completed red wave");
local writes=#w.writes;w:tick(60);check(#w.writes==writes,"failure is idempotent and never extends cooldown");
local old=reds[1];w.writes={};boss=w:start();w:dispatch("death",old);w:tick(31);check(boss.body==11 and #w:list(RED)==16,"old generation cannot advance retry");w:reds();w:arrive();check(boss.body==24,"new attempt starts with clean counters");

for _,fault in ipairs({"fail","throw"})do for _,typ in ipairs({RED,CONTROL,LURKER})do
 w=world();w[fault]=typ;w:start();check(not w:one(LURKER)and #w:list(RED)==0,"failed required spawn cleans attempt");w:cooldown(900000);
 check(w:rpCount("a great mound of sludge swells")==0,"failed required opening spawn cannot announce a completed transition");
end end
w=world();boss=w:start();w:one(CONTROL):Depop();w:tick(1);w:tick(30);check(not boss.valid,"missing timeout controller cannot leave a permanent event");w:cooldown(900000);
w=world();boss=w:start();w:tick(5880);check(not boss.valid,"original98-minute timeout cleans event");w:cooldown(900000);
w=world();boss=w:start();w:reds();w:load();w:tick(0);check(not boss.valid and #w:list(RUNNER)==0,"reload of active event safely retries instead of granting progress");w:cooldown(900000);

-- Exercise the normal fight through its four split waves and final boss.
w=world();boss=w:start();w:reds();w:arrive();
for i=1,4 do
 w:dispatch("hp",boss);check(#w:list(218358)==10,"Lurker split still produces10 mudlets");
 for _,n in ipairs(w:list(218358))do w:kill(n);w:dispatch("death",n);end
 boss=w:one(LURKER);check(boss and boss.hp==100-i*20,"Lurker returns at next HP stage");
 check(w:checkpointCount(5,10)==i and w:checkpointCount(9,10)==i,"each fresh mudlet wave announces both milestones once despite duplicate deaths");
 check(w:rpCount("The final mudlet splatters across the ground.")==i,"each completed mudlet wave announces its actual return once");
end
w:kill(boss);check(#w:list(218359)==4,"Lurker death still produces4 gorgers");
w:spawn(218390);for _,n in ipairs(w:list(218359))do w:kill(n);end
local final=w:one(218360);check(final~=nil,"normal loot boss still requires gorger kills");
check(w:checkpointCount(2,4)==1 and w:checkpointCount(4,4)==0,"four-gorger wave announces midpoint without a duplicate 90-percent completion message");
w:spawn(218361);w:kill(final);w:cooldown(237600000);
check(#w:list(CONTROL)==0 and #w:list(218361)==0,"success cleans controller and leftover adds");
writes=#w.writes;w:dispatch("death",final);check(#w.writes==writes,"duplicate final death cannot extend success cooldown");
check(#w.signals==1 and w.signals[1][1]==218393 and w.signals[1][2]==2,"only normal victory signals Arbitor");
local victory=w.rp[#w.rp];check(victory.text:find("trial of the Mud Ring is complete",1,true) and victory.writes==16 and victory.signals==1,"victory RP follows saved success cooldown and Arbitor credit");
check(w:rpCount("trial of the Mud Ring is complete")==1,"duplicate final death cannot repeat victory RP");
w=world();local blue=w:spawn(BLUE);w:kill(blue);w:dispatch("death",blue);check(#w:list(RED)==1 and not w:one(LURKER),"duplicate blue death cannot create another required red");

-- Later phases require every tracked kill; disappearance is never completion.
local function unlocked()
 local w=world();local boss=w:start();w:reds();w:arrive();return w,boss;
end
local function split(w,boss)
 w:dispatch("hp",boss);return w:list(218358);
end
local function gorgers()
 local w,boss=unlocked();
 for i=1,4 do for _,n in ipairs(split(w,boss))do w:kill(n);end;boss=w:one(LURKER);end
 w:kill(boss);return w,w:list(218359);
end
local function missing_retry(w)
 w:tick(1);w:tick(30);w:cooldown(900000);
 check(not w:one(CONTROL) and not w:one(LURKER),"missing required mob cleans encounter");
 check(#w.signals==0,"failure never awards Arbitor progression");
end
w,boss=unlocked();boss:Depop();missing_retry(w);
w,boss=unlocked();local mudlets=split(w,boss);mudlets[1]:Depop();
for i=2,10 do w:kill(mudlets[i]);end
check(not w:one(LURKER),"nine kills plus missing mudlet cannot advance");missing_retry(w);
check(w:checkpointCount(5,10)==1 and w:checkpointCount(9,10)==1 and w:rpCount("The final mudlet splatters across the ground.")==0,"missing mudlet preserves genuine kill milestones but never emits completion");
w,boss=unlocked();mudlets=split(w,boss);for _,n in ipairs(mudlets)do w:kill(n);end
check(#w:list(LURKER)==1,"all ten confirmed kills produce one lurker");
w:dispatch("death",mudlets[10]);check(#w:list(LURKER)==1,"duplicate mudlet death cannot duplicate lurker");
-- Old HP callbacks cannot split a subsequent phase.
w:dispatch("hp",boss);check(#w:list(218358)==0,"stale lurker HP event ignored");
w,boss=unlocked();mudlets=split(w,boss);w:dispatch("combat",mudlets[1],{joined=true});
local paused=false;for _,t in pairs(w.timers)do if t.owner==mudlets[1] and t.name=="depop"then paused=t.paused;end end
check(paused,"mudlet combat handler is registered and pauses its idle timer");
w:dispatch("timer",mudlets[2],{timer="depop"});w:cooldown(900000);
check(not w:one(218358),"expired required mudlet cleans entire wave for retry");
for _,fault in ipairs({"fail","throw"})do
 w,boss=unlocked();w[fault]=218358;w:dispatch("hp",boss);w:cooldown(900000);
 check(not w:one(LURKER) and not w:one(218358),"failed mudlet spawn cleanly retries");
 w,boss=unlocked();mudlets=split(w,boss);w[fault]=LURKER;
 for _,n in ipairs(mudlets)do w:kill(n);end;w:cooldown(900000);
 check(not w:one(LURKER),"failed reformed lurker cleanly retries");
 check(w:rpCount("The final mudlet splatters across the ground.")==0,"failed reformed Lurker never announces successful phase completion");
end
w,mudlets=gorgers();mudlets[1]:Depop();for i=2,4 do w:kill(mudlets[i]);end
check(not w:one(218365),"three kills plus missing gorger cannot advance");missing_retry(w);
w,mudlets=gorgers();for _,n in ipairs(mudlets)do w:kill(n);end
check(#w:list(218365)==1,"four confirmed gorgers produce one final boss");
w:dispatch("death",mudlets[4]);check(#w:list(218365)==1,"duplicate gorger death cannot duplicate final boss");
w:one(218365):Depop();missing_retry(w);
for _,fault in ipairs({"fail","throw"})do
 w,boss=unlocked();for i=1,4 do for _,n in ipairs(split(w,boss))do w:kill(n);end;boss=w:one(LURKER);end
 w[fault]=218359;w:kill(boss);w:cooldown(900000);
 check(not w:one(218359),"failed gorger spawn cleanly retries");
 w,mudlets=gorgers();w[fault]=218365;for _,n in ipairs(mudlets)do w:kill(n);end;w:cooldown(900000);
 check(not w:one(218365),"failed final spawn cleanly retries");
 check(w:rpCount("The last filth gorger bursts,")==0,"failed final spawn never announces successful gorger transition");
end
w,boss=unlocked();w:kill(boss);w:cooldown(900000);
check(not w:one(218359),"premature lurker death cannot bypass split waves");
-- A foreign same-type final boss cannot award this attempt's success.
w,boss=unlocked();local foreign=w:spawn(218360);w:kill(foreign);
check(#w.writes==0 and #w.signals==0,"untracked final death cannot award progression");

-- Opening native mudwalkers are required even before the red-wave controller exists.
local function opening(count)
 local w=world();local blues={};for i=1,(count or 16)do blues[i]=w:spawn(BLUE);end
 return w,blues;
end
w=world();w:tick(6000);check(#w.writes==0,"idle zone does not start a retry or shorten a saved lockout");
w,blues=opening(15);w:kill(blues[1]);w:tick(1);check(#w.writes==0,"incomplete opening wave gets disappearance grace");
for i=2,15 do w:kill(blues[i]);end
check(not w:one(LURKER),"fifteen native kills cannot start Lurker");w:tick(30);w:cooldown(900000);
check(#w.signals==0,"incomplete opening wave grants no completion");
w,blues=opening();w:kill(blues[1]);blues[2]:Depop();
for i=3,16 do w:kill(blues[i]);end
check(not w:one(CONTROL),"missing native blue never starts encounter controller");missing_retry(w);
w,blues=opening();w:kill(blues[1]);local oldBlue=blues[2];oldBlue:Depop();
local replacement=w:spawn(BLUE);replacement.spawnid=oldBlue.spawnid;w:kill(replacement);
for i=3,16 do w:kill(blues[i]);end
check(not w:one(LURKER),"replacement at same spawn point cannot substitute for missing kill");missing_retry(w);
local saved=#w.writes;w:dispatch("death",oldBlue);w:tick(60);
check(#w.writes==saved and not w:one(RED),"late cleaned blue callback cannot restart or extend retry");
w,blues=opening(15);local foreign=w:spawn(BLUE);foreign.spawnid=0;
w:kill(foreign);check(#w:list(RED)==0,"foreign blue cannot start the ring");w:kill(blues[1]);missing_retry(w);
w,blues=opening();w:kill(blues[1]);w:one(RED):Depop();missing_retry(w);
w,blues=opening();w:kill(blues[1]);w:tick(7200);w:cooldown(900000);
check(#w:list(RED)==0 and #w:list(BLUE)==0,"partial opening red expiry cleans the whole attempt");
w,blues=opening();w:kill(blues[1]);w:load();w:tick(0);w:cooldown(900000);
check(not w:one(RED),"reload of partial opening retries cleanly");
w,blues=opening();w:kill(blues[1]);w:one(RED):Depop();w:load();w:tick(0);w:cooldown(900000);
check(#w:list(BLUE)==0,"reload recovers tagged opening blues even when every red is already gone");
w,blues=opening();w:kill(blues[1]);w:tick(5800);
check(#w.writes==0 and not w:one(CONTROL),"opening phase does not start the 98-minute red-wave deadline early");
for i=2,16 do w:kill(blues[i]);end
local controller=w:one(CONTROL);check(controller~=nil,"sixteen native kills still start normal encounter");
w:tick(5879);check(#w.writes==0,"full 98-minute event budget starts after opening wave");
w:tick(1);w:cooldown(900000);
check(w.logs[#w.logs]:find("Blue kills: 16/16",1,true),"failure debug retains completed blue-wave credit");

-- NPC::Depop only marks the NPC until the next entity processing pass.
-- A controller failure and the final boss's adds timer can both be due in
-- one QuestManager::Process pass. Cleanup must remain final even if the
-- marked boss still receives combat/timer/death callbacks during that pass.
for _,finalType in ipairs({218360,218365})do
 w,mudlets=gorgers();
 if finalType==218360 then w:spawn(218390);end
 for _,n in ipairs(mudlets)do w:kill(n);end
 final=w:one(finalType);check(final~=nil,"deferred cleanup test reaches either final boss");
 w:dispatch("combat",final,{joined=true});
 local add=w:spawn(218361);
 w.deferDepop=true;
 w:dispatch("timer",w:one(CONTROL),{timer="depop"});
 check(final.valid and final.pending_depop and add.pending_depop,"failure marks final and existing adds for deferred removal");
 local afterFailure=w.nextid;local failureWrites=#w.writes;local failureRp=#w.rp;
 local dropTimer=w.timers[tostring(final).."drophate"];
 w:dispatch("combat",final,{joined=true});
 check(w.timers[tostring(final).."drophate"]==dropTimer,"late combat cannot restart final boss timers after cleanup");
 w:dispatch("timer",final,{timer="adds"});
 w:dispatch("timer",final,{timer="drophate"});
 -- Replay old death/HP/arrival notifications while their wrappers still exist.
 for _,n in pairs(w.npcs)do
  w:dispatch("death",n);w:dispatch("hp",n);w:dispatch("arrive",n);
 end
 check(w.nextid==afterFailure,"late callbacks cannot spawn any mobs after failure cleanup");
 check(#w.writes==failureWrites and #w.signals==0 and #w.rp==failureRp,"late callbacks cannot extend retry, award credit, or announce progress");
 w:flushDepops();
 for _,typ in ipairs({BLUE,RED,RUNNER,LURKER,CONTROL,218358,218359,218360,218361,218365})do
  check(#w:list(typ)==0,"failed Mud trial leaves no live ring mobs after deferred removal");
 end
 w:tick(120);
 check(#w:list(218361)==0 and #w.writes==failureWrites,"idle watchdog cannot recreate adds or extend retry");
 w:cooldown(900000);
end

-- A registered spawn callback runs inside eq.spawn2. If that callback fails,
-- the outer spawn loop must not accept its pending-depop return or keep spawning.
w,blues=opening();w.deferDepop=true;w.throwTimer="depop";
local beforeSpawn=w.nextid;w:kill(blues[1]);
check(w.nextid==beforeSpawn+1,"opening red spawn failure cannot create later trial mobs");
w:flushDepops();
check(#w:list(BLUE)==0 and #w:list(RED)==0,"nested opening spawn failure washes out both waves");
w:cooldown(900000);
w,boss=unlocked();w.deferDepop=true;w.throwTimer="depop";
beforeSpawn=w.nextid;w:dispatch("hp",boss);
check(w.nextid==beforeSpawn+1,"nested mudlet spawn failure stops the ten-mob loop immediately");
w:flushDepops();
check(#w:list(218358)==0 and not w:one(LURKER) and not w:one(CONTROL),"nested mudlet failure leaves no trial mobs");
check(#w.signals==0 and w:rpCount("The Sludge Lurker ruptures in a heavy splash,")==0,"nested spawn failure grants no progress or transition RP");
w:cooldown(900000);

-- Native AddNPC dispatches spawn before inserting the NPC into npc_list.
-- Cleanup cannot see a runner whose own MoveTo callback triggers failure.
w=world();w:start();w.deferDepop=true;w.deferSpawnInsert=true;w.throwMove=RUNNER;
beforeSpawn=w.nextid;w:kill(w:one(RED));
check(w.nextid==beforeSpawn+1,"runner callback failure stops the four-runner spawn loop immediately");
local failedRunner=w:one(RUNNER);
check(failedRunner and failedRunner.pending_depop,"runner missed by nested cleanup is explicitly marked for removal");
w:flushDepops();
for _,typ in ipairs({BLUE,RED,RUNNER,LURKER,CONTROL})do
 check(#w:list(typ)==0,"runner callback failure washes out every live trial mob");
end
check(#w.signals==0 and w:rpCount("The Sludge Lurker heaves free")==0,"failed runner callback grants no phase advance or progression");
w:cooldown(900000);

print("PASS: "..checks.." Mud Ring recovery checks");
