-- From the repository root: lua5.1 tests/rallos_recovery_test.lua
-- Isolated mocks only; no database or game server access.
local path=arg[1] or 'potactics/encounters/Rallos.lua'
local file=assert(io.open(path)); local source=file:read('*a');file:close()
local B,G,T,V,R,W,U=214056,214057,214313,214320,214311,214312,214052
local BI,GI,UI=361190,361200,361379
-- Model luabind's non-owning iterator: collection of a temporary list
-- invalidates iteration even when the iterator function itself survives.
local function guardedList(list)
 local weak=setmetatable({list},{__mode="v"});local nextEntry=list.entries
 list.entries=function(...)
  collectgarbage("collect")
  assert(weak[1],"entity-list owner was collected during iteration")
  return nextEntry(...)
 end
 return list
end
local function world(guild)
 local w={now=100000,guild=guild or 66,entities={},spawns={},timers={},buckets={},logs={},saved={},fail={},nextid=100,signals={},clientMessages={}}
 local NPC={}
 function NPC:GetID() return self.dead and 0 or self.id end
 function NPC:GetNPCTypeID() return self.t end
 function NPC:IsCorpse() return self.dead or false end
 function NPC:GetName() return tostring(self.t) end
 function NPC:GetCleanName() return ({[T]="Tallon Zek",[V]="Vallon Zek",[R]="Rallos Zek",[W]="Rallos Zek the Warlord"})[self.t] or tostring(self.t) end
 function NPC:GetX() return self.x end
 function NPC:GetY() return self.y end
 function NPC:GetZ() return self.z end
 function NPC:GetHeading() return self.h end
 function NPC:GetSpawnPointID() return self.spawn or 0 end
 function NPC:GetSpawnPointX() return self.home[1] end
 function NPC:GetSpawnPointY() return self.home[2] end
 function NPC:GetSpawnPointZ() return self.home[3] end
 function NPC:GetSpawnPointH() return self.home[4] end
 function NPC:IsEngaged() return self.engaged or false end
 function NPC:GetHPRatio() return self.hp end
 function NPC:GetHP() return self.hp end
 function NPC:GetMaxHP() return 100 end
 function NPC:CastToNPC() return self end
 function NPC:CastToClient() return self end
 function NPC:SetEntityVariable(k,v) self.vars=self.vars or {};self.vars[k]=v end
 function NPC:GetEntityVariable(k) return self.vars and self.vars[k] or '' end
 function NPC:GetGuildName() return 'Test' end
 function NPC:SetWalkspeed() end
 function NPC:SetRunspeed() end
 function NPC:SetRunning() end
 function NPC:SetCastRateDetrimental() end
 function NPC:SetSpecialAbility(a,v) self.abilities[a]=v end
 function NPC:SetBaseHP() end
 function NPC:Heal() self.hp=100 end
 function NPC:InterruptSpell() self.interrupted=true end
 function NPC:CastSpell(id,target) self.spell=id;self.spelltarget=target;return true end
 function NPC:SpellOnTarget(id,target)
  assert(target==self,'leash spell must target only self');self.spell=id;self.spelltarget=target.id;self.directSpell=true
  if not self.keepDebuffs then self.buffs={} end
  return not self.failDirectSpell
 end
 function NPC:FindBuff(id) return self.buffs and self.buffs[id] or false end
 function NPC:BuffFadeAll() self.fadeAllCalled=true;if not self.failFadeAll then self.buffs={} end end
 function NPC:WipeHateList()
  local engaged=self.engaged;self.engaged=false
  if engaged then w:dispatch('combat',self,{joined=false}) end
 end
 function NPC:GMMove(x,y,z,h) self.x,self.y,self.z,self.h=x,y,z,h end
 function NPC:MoveTo() end
 function NPC:UpdateWaypoint() end
 function NPC:GetTarget() return nil end
 function NPC:GetHateRandomClient() return nil end
 function NPC:AddToHateList() self.engaged=true end
 function NPC:Depop() self.valid=false;w.entities[self.id]=nil;if self.spawn and w.spawns[self.spawn] then w.spawns[self.spawn].npc=nil end end
 function w:newnpc(t,x,y,z,h,spawn)
  if self.fail[t] then return {valid=false} end
  self.nextid=self.nextid+1
  local n=setmetatable({valid=true,id=self.nextid,t=t,x=x or 320,y=y or 0,z=z or 181,h=h or 0,spawn=spawn,home={x or 320,y or 0,z or 181,h or 0},abilities={},hp=100},{__index=NPC})
  self.entities[n.id]=n;if spawn then self.spawns[spawn].npc=n end
  self:dispatch('spawn',n,{})
  return n
 end
 function w:mob(t) for _,n in pairs(self.entities) do if n.valid and not n.dead and n.t==t then return n end end end
 function w:dispatch(kind,n,args)
  if not self.handlers then return end
  local cb=self.handlers[n.t] and self.handlers[n.t][kind]
  if not cb then return end
  local previous=self.owner;self.owner=n;args.self=n;cb(args);self.owner=previous
 end
 function w:eventtimer(name)
  local previous=self.owner;self.owner=self.encounter;self.env.event_timer({timer=name});self.owner=previous
 end
 function w:kill(t)
  local n=assert(self:mob(t),'missing kill target '..t);n.dead=true
  local killer={valid=true,GetName=function()return 'Tester'end,GetID=function()return 1 end}
  self:dispatch('death_complete',n,{killer=killer});n:Depop()
 end
 function w:combat(t,joined)
  local n=assert(self:mob(t));n.engaged=joined;self:dispatch('combat',n,{joined=joined})
 end
 function w:npctimer(t,name) local n=assert(self:mob(t));self:dispatch('timer',n,{timer=name}) end
 function w:waypoint(t,wp)
  local n=assert(self:mob(t));if wp==3 then n.y=t==T and -85 or 110;n.x=319;n.z=181.6 end
  self:dispatch('waypoint_arrive',n,{wp=wp})
 end
 function w:count(t)local total=0;for _,n in pairs(self.entities)do if n.t==t then total=total+1 end end;return total end
 function w:flush()
  while #self.signals>0 do local s=table.remove(self.signals,1);for _,n in pairs(self.entities)do if n.t==s[1] then self:dispatch('signal',n,{signal=s[2]}) end end end
 end
 function w:errors()for _,l in ipairs(self.logs)do assert(not l:find('Lua callback failed',1,true),l) end end
 local Spawn={}
 function Spawn:Enable()self.enabled=true end
 function Spawn:Disable()self.enabled=false;if self.npc then self.npc:Depop()end end
 function Spawn:Enabled()return self.enabled end
 function Spawn:SetTimer(ms)self.timer=ms end
 function Spawn:GetNPC()return self.npc or {valid=false} end
 function Spawn:NPCPointerValid()return self.npc~=nil end
 for id=361100,361400 do w.spawns[id]=setmetatable({valid=true,id=id,enabled=true},{__index=Spawn}) end
 w:newnpc(U,500,20,194,64,UI);w:newnpc(B,320,301,168,1,BI);w:newnpc(G,320,-286,168,129,GI)
 local el={}
 function el:GetMobByNpcTypeID(t)return w:mob(t) or {valid=false} end
 function el:IsMobSpawnedByNpcTypeID(t)return w:mob(t)~=nil end
 function el:GetSpawnByID(id)return w.spawns[id] or {valid=false} end
 function el:GetMobID(id)return w.entities[id] or {valid=false} end
 function el:GetNPCList()
  local list={};for _,n in pairs(w.entities)do list[#list+1]=n end
  local i=0;return guardedList({entries=function()i=i+1;return list[i]end})
 end
 function el:GetClientList()
  local list={};for _,isGM in ipairs({true,false})do
   local gm=isGM;list[#list+1]={valid=true,GetGM=function()return gm end,Message=function(_,color,msg)w.clientMessages[#w.clientMessages+1]={gm=gm,color=color,text=msg}end}
  end
  local i=0;return guardedList({entries=function()i=i+1;return list[i]end})
 end
 function el:MessageClose()end
 function w:load(deferInitialization)
  self.handlers={};self.encounter={id=-100};self.owner=self.encounter
  local env=setmetatable({Event={timer='timer',spawn='spawn',combat='combat',death_complete='death_complete',waypoint_arrive='waypoint_arrive',hp='hp',signal='signal'},os={time=function()return self.now end}},{__index=_G})
  self.env=env
  env.eq={
   get_zone_guild_id=function()return self.guild end,get_entity_list=function()return el end,
   get_data=function(k)return self.buckets[k] or ''end,set_data=function(k,v)self.buckets[k]=v end,
   zone_emote=function(color,msg)self.logs[#self.logs+1]=msg;self.emotes=self.emotes or {};self.emotes[#self.emotes+1]={color=color,text=msg}end,debug=function(msg)self.logs[#self.logs+1]=msg end,
   set_timer=function(name,ms,owner)owner=owner or self.owner;assert(owner,'timer owner');self.timers[owner.id..':'..name]=ms end,
   stop_timer=function(name,owner)owner=owner or self.owner;self.timers[owner.id..':'..name]=nil end,
   stop_all_timers=function(owner)owner=owner or self.owner;for k in pairs(self.timers)do if k:sub(1,#tostring(owner.id)+1)==owner.id..':' then self.timers[k]=nil end end end,
   pause_timer=function()end,resume_timer=function()end,
   set_next_hp_event=function(hp)assert(self.owner~=self.encounter,'HP threshold requires NPC owner');self.owner.nextHP=hp end,
   unique_spawn=function(t,_,__,x,y,z,h)return self:mob(t) or self:newnpc(t,x,y,z,h)end,
   spawn2=function(t,_,__,x,y,z,h)return self:newnpc(t,x,y,z,h)end,
   spawn_from_spawn2=function(id)return self:newnpc(U,500,20,194,64,id)end,
   depop_with_timer=function(t)assert(self.owner~=self.encounter,'depop_with_timer requires NPC callback owner');local n=t and self:mob(t) or self.owner;if n then n:Depop()end end,
   depop=function()self.owner:Depop()end,
   depop_all=function(t)local list={};for _,n in pairs(self.entities)do if n.t==t then list[#list+1]=n end end;for _,n in ipairs(list)do n:Depop()end end,
   update_spawn_timer=function(id,ms)self.saved[id]={at=self.now,ms=ms}end,
   signal=function(t,s)self.signals[#self.signals+1]={t,s}end,
   register_npc_event=function(_,kind,t,cb)self.handlers[t]=self.handlers[t] or {};self.handlers[t][kind]=cb end
  }
  local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();env.event_encounter_load({encounter=self.encounter})
  if not deferInitialization then self:eventtimer('initialize');self:flush();self:errors() end
 end
 function w:start()
  self:load();self:kill(B);self:kill(G);self:eventtimer('doors');assert(self:mob(T)and self:mob(V));self:errors()
 end
 function w:upstairs()self:kill(T);self:kill(V);self:eventtimer('brothers_killed');assert(self:mob(R));self:errors()end
 function w:pit()
  self:upstairs();local n=self:mob(R);n.hp=75;self:dispatch('hp',n,{hp_event=75});n.hp=50;self:dispatch('hp',n,{hp_event=50});assert(self:mob(W));self:errors()
 end
 return w
end
local tests={}
local function test(name,fn)tests[#tests+1]={name,fn}end
local function reset(w)
 assert(w.spawns[BI].enabled and w.spawns[GI].enabled)
 local retry=600000
 assert(w.saved[BI].ms==retry and w.saved[GI].ms==retry)
 assert(not w:mob(T)and not w:mob(V)and not w:mob(R)and not w:mob(W));w:errors()
end
test('two confirmed kills advance, timeout restored to 150 minutes',function()
 local w=world();w:start();assert(w.timers[w:mob(T).id..':depop']==9000000);w:upstairs();assert(not w.spawns[BI].enabled)
end)
test('kill VZ, timeout TZ resets once',function()
 local w=world();w:start();w:waypoint(T,3);w:waypoint(V,3);w:kill(V);w:eventtimer('brothers_killed');w.now=w.now+9001;w:npctimer(T,'depop');reset(w)
 local at=w.saved[BI].at;w.now=w.now+20;w.env.FailEncounter('duplicate');assert(w.saved[BI].at==at)
end)
test('timeout first prevents subsequent kill advancement',function()
 local w=world();w:start();local oldV=w:mob(V);w.now=w.now+9001;w:npctimer(T,'depop');w:dispatch('death_complete',oldV,{killer={valid=false}});w:eventtimer('brothers_killed');reset(w)
end)
test('queued success cannot beat timeout failure',function()
 local w=world();w:start();w:kill(V);w.now=w.now+9001;w:npctimer(T,'depop');w:eventtimer('brothers_killed');reset(w)
end)
test('missing brother recovered without controller signals',function()
 local w=world();w:start();w:waypoint(T,3);w:waypoint(V,3);w:kill(V);w:mob(T):Depop();w:eventtimer('watchdog');w.now=w.now+10;w:eventtimer('watchdog');reset(w)
end)
test('failed brother spawn rolls back',function()
 local w=world();w.fail[V]=true;w:load();w:kill(B);w:kill(G);w:eventtimer('doors');reset(w)
end)
test('failed upstairs spawn rolls back',function()
 local w=world();w:start();w.fail[R]=true;w:kill(T);w:kill(V);w:eventtimer('brothers_killed');reset(w)
end)
test('failed Warlord spawn rolls back arena',function()
 local w=world();w:start();w:upstairs();w.fail[W]=true;local n=w:mob(R);w:dispatch('hp',n,{hp_event=75});w:dispatch('hp',n,{hp_event=50});reset(w);assert(w.spawns[361141].enabled)
end)
test('zero-based waypoint 2 is hallway, waypoint 3 spawns adds only once',function()
 local w=world(1);w:start();w:waypoint(T,2);assert(w:count(214086)==0 and w:mob(T).abilities[35]==1);w:waypoint(T,3);w:waypoint(T,3);assert(w:count(214086)==4 and w:mob(T).abilities[35]==0);w:errors()
end)
test('brother hallway leash clears aggro, heals and self casts 3230',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);w:combat(T,true);n.y=400;n.hp=50;w:npctimer(T,'bounds');assert(not n.engaged and n.hp==100 and n.y==-85 and n.spell==3230 and n.spelltarget==n.id);w:errors()
end)
test('upstairs reengage below 98 stops idle timer and leashes',function()
 local w=world();w:start();w:upstairs();local n=w:mob(R);n.hp=80;w:combat(R,true);w:combat(R,false);w:combat(R,true);assert(not w.timers[n.id..':depop']);n.y=400;w:npctimer(R,'bounds');assert(n.y==20 and n.hp==100 and n.spell==3230);w:errors()
end)
test('reload preserves killed brother and remaining idle budget',function()
 local w=world();w:start();w:waypoint(T,3);w:waypoint(V,3);w.now=w.now+60;w:kill(V);w:load();assert(w:mob(T)and not w:mob(V));assert(w.timers[w:mob(T).id..':depop']==8940000);w:kill(T);w:eventtimer('brothers_killed');assert(w:mob(R));w:errors()
end)
test('reload while engaged does not consume paused budget',function()
 local w=world();w:start();w:waypoint(T,3);w:waypoint(V,3);w.now=w.now+60;w:combat(T,true);w.now=w.now+300;w:load();assert(not w.timers[w:mob(T).id..':depop']);w:combat(T,false);assert(w.timers[w:mob(T).id..':depop']==8940000);w:errors()
end)
test('success preserves 66h cooldown through stale events and reload',function()
 local w=world();w:start();w:pit();w:kill(W);assert(w.saved[BI].ms==237600000);w.env.FailEncounter('stale failure');w:eventtimer('brothers_killed');w.now=w.now+120;w:load();assert(w.saved[BI].ms==237480000);w:errors()
end)
test('retry reenable does not restart ten minute cooldown',function()
 local w=world();w:start();w.env.FailEncounter('test');w.now=w.now+120;w.spawns[BI].enabled=false;w:eventtimer('watchdog');assert(w.saved[BI].ms==480000);w:errors()
end)
test('arena preserves preexisting disabled spawnpoints',function()
 local w=world();w:start();w.spawns[361141].enabled=false;w:pit();w.env.FailEncounter('test');assert(not w.spawns[361141].enabled and w.spawns[361347].enabled);w:errors()
end)
test('pending pit wave canceled on disengage',function()
 local w=world();w:start();w:pit();w:combat(W,true);w:npctimer(W,'twitch');w:combat(W,false);w:eventtimer('wraiths');assert(w:count(214287)==0);w:errors()
end)
test('pit movement timer slows even when engaged',function()
 local w=world();w:start();w:pit();w:combat(W,true);w:npctimer(W,'twitch');w:eventtimer('wraiths');local n=w:mob(214287);n.engaged=true;w:npctimer(214287,'move');assert(w.timers[n.id..':move']==6000);w:errors()
end)
test('runtime callback error emits zone error and recovers',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.y=400;n.GMMove=function()error('injected movement failure')end;w:npctimer(T,'bounds');assert(w.spawns[BI].enabled);local found=false;for _,l in ipairs(w.logs)do if l:find('injected movement failure',1,true)then found=true end end;assert(found)
end)
test('disabled orphan guards recovered on initialization',function()
 local w=world();w.spawns[BI]:Disable();w.spawns[GI]:Disable();w:load();reset(w)
end)
test('retry completes after deadline without retaining kill flags',function()
 local w=world();w:start();w.env.FailEncounter('test');w.now=w.now+600;w:eventtimer('watchdog');assert(w.spawns[BI].timer==1);w:newnpc(B,320,301,168,1,BI);w:newnpc(G,320,-286,168,129,GI);w:eventtimer('watchdog');w:kill(B);w:eventtimer('doors');assert(not w:mob(T));w:kill(G);w:eventtimer('doors');assert(w:mob(T)and w:mob(V));w:errors()
end)
test('missing guard spawnpoint logged and retried without restarting deadline',function()
 local w=world();w:start();local spawn=w.spawns[BI];w.spawns[BI]=nil;w.env.FailEncounter('test');assert(w.spawns[GI].enabled);w.now=w.now+120;w.spawns[BI]=spawn;spawn.enabled=false;w:eventtimer('watchdog');assert(w.saved[BI].ms==480000);w:errors()
end)
test('success arena restore after 30 minutes does not shorten guard cooldown',function()
 local w=world();w:start();w:pit();w:kill(W);local at=w.saved[BI].at;w.now=w.now+1800;w:eventtimer('watchdog');assert(w.spawns[361141].enabled and w.saved[BI].at==at);w:errors()
end)
test('hallway samples leash; all four supplied balcony corners remain safe',function()
 local w=world();w:start();w:upstairs();local n=w:mob(R)
 for _,yx in ipairs({{-89.21,539.46},{110.97,538.88},{56.86,462.25},{-40.26,462.23}})do
  n.y,n.x,n.z=yx[1],yx[2],169.75;n.spell=nil;w:npctimer(R,'bounds');assert(not n.spell)
 end
 for _,yx in ipairs({{-526.25,1021.02},{542.79,861.77}})do n.y,n.x,n.z=yx[1],yx[2],137.73;w:npctimer(R,'bounds');assert(n.x==500 and n.y==20 and n.spell==3230)end
 w:errors()
end)
test('engaging a traveling brother outside the room resets it home',function()
 local w=world();w:start();local n=w:mob(T);w:combat(T,true);w:npctimer(T,'bounds');assert(n.x==319 and n.y==-85 and n.spell==3230 and not n.engaged);assert(w:count(214086)==4);w:errors()
end)
test('Vallon copies use council room leash and are removed at pit transition',function()
 local w=world();w:start();w:waypoint(V,3);local n=w:mob(V);w:dispatch('hp',n,{hp_event=50});local copy=assert(w:mob(214319));copy.y=500;w:npctimer(214319,'bounds');assert(copy.y==110 and copy.spell==3230);w:pit();assert(w:count(214319)==0);w:errors()
end)
test('repop after initialization rearms watchdog through guard spawns',function()
 local w=world();w:load();w.timers={};w:mob(B):Depop();w:mob(G):Depop()
 w:newnpc(B,320,301,168,1,BI);w:newnpc(G,320,-286,168,129,GI)
 assert(w.timers[w.encounter.id..':watchdog']==5000)
 w:kill(B);w:kill(G);w:eventtimer('doors');w:kill(T);w:mob(V):Depop()
 w:eventtimer('watchdog');w.now=w.now+10;w:eventtimer('watchdog');reset(w)
end)
test('repop before initialization restores both initialization and watchdog',function()
 local w=world();w:load(true);w.timers={};w:mob(B):Depop();w:mob(G):Depop()
 w:newnpc(B,320,301,168,1,BI);w:newnpc(G,320,-286,168,129,GI)
 assert(w.timers[w.encounter.id..':initialize']==1000 and w.timers[w.encounter.id..':watchdog']==5000)
 w:eventtimer('initialize');w:kill(B);w:kill(G);w:eventtimer('doors');w:kill(T);w:mob(V):Depop()
 w:eventtimer('watchdog');w.now=w.now+10;w:eventtimer('watchdog');reset(w)
end)
test('guard deaths restore watchdog after timers were externally cleared',function()
 local w=world();w:load();w.timers={};w:kill(B);w:kill(G);w:eventtimer('doors')
 assert(w.timers[w.encounter.id..':watchdog']==5000)
 w:kill(T);w:mob(V):Depop();w:eventtimer('watchdog');w.now=w.now+10;w:eventtimer('watchdog');reset(w)
end)
test('guild 66 natural idle expiry uses 150 minutes and ten minute guard recovery',function()
 local w=world(66);w:start();assert(w.timers[w:mob(V).id..':depop']==9000000)
 w:kill(T);w.now=w.now+8999;w:npctimer(V,'depop');assert(w:mob(V) and w.timers[w:mob(V).id..':depop']==1000)
 w.now=w.now+1;w:npctimer(V,'depop');reset(w)
end)
test('guild 2 normal idle budget pauses throughout combat',function()
 local w=world(2);w:start();w.now=w.now+30;w:combat(V,true);w.now=w.now+300;w:combat(V,false)
 assert(w.timers[w:mob(V).id..':depop']==8970000);w:errors()
end)
test('leash applies 3230 directly to self instead of NPC group cast routing',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.buffs={[676]=true,[2885]=true};n.y=500
 n.CastSpell=function()error('leash must bypass group cast routing')end
 w:npctimer(T,'bounds');assert(n.directSpell and n.spell==3230 and n.spelltarget==n.id);w:errors()
end)
test('leash reports known debuffs remaining if explicit cleanup fails',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.buffs={[676]=true,[2885]=true};n.keepDebuffs=true;n.failFadeAll=true;n.y=500
 w:npctimer(T,'bounds');local found=0
 for _,l in ipairs(w.logs)do if l:find('still has',1,true)then found=found+1 end end
 assert(found==2);w:errors()
end)
test('leash reports rejected direct 3230 application',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.failDirectSpell=true;n.y=500;w:npctimer(T,'bounds')
 local found=false;for _,l in ipairs(w.logs)do if l:find('rejected Balance of the Nameless',1,true)then found=true end end
 assert(found);w:errors()
end)
test('pit Warlord leash uses full reset and direct self spell 3230',function()
 local w=world();w:start();w:pit();local n=w:mob(W);w:combat(W,true);n.hp=40;n.x=1000;n.buffs={[676]=true,[2885]=true}
 w:npctimer(W,'bounds');assert(n.x==705 and n.y==0 and n.z==-290 and n.hp==100 and not n.engaged)
 assert(n.directSpell and n.spell==3230 and n.spelltarget==n.id);assert(w.timers[n.id..':depop']);w:errors()
end)
test('pit Warlord stays in place inside arena boundary',function()
 local w=world();w:start();w:pit();local n=w:mob(W);n.x=705;n.y=0;n.z=-290;n.hp=40
 w:npctimer(W,'bounds');assert(n.hp==40 and not n.directSpell);w:errors()
end)
test('leash clears buffs and debuffs even when 3230 leaves them intact',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.buffs={[676]=true,[2885]=true,[369]=true};n.keepDebuffs=true;n.y=500;n.hp=40
 w:npctimer(T,'bounds');assert(n.fadeAllCalled and not next(n.buffs) and n.hp==100 and not n.engaged);w:errors()
end)
test('leash clears effects even if 3230 application is rejected',function()
 local w=world();w:start();w:waypoint(V,3);local n=w:mob(V);n.buffs={[676]=true,[2885]=true};n.keepDebuffs=true;n.failDirectSpell=true;n.y=500
 w:npctimer(V,'bounds');assert(n.fadeAllCalled and not next(n.buffs));w:errors()
end)
test('guild 2 normal retry remains ten minutes and reload does not restart it',function()
 local w=world(2);w:start();assert(w.timers[w:mob(V).id..':depop']==9000000);w.env.FailEncounter('test');reset(w)
 local key='rallos-recovery-v3-2';local fields={};for f in (w.buckets[key]..'|'):gmatch('(.-)|')do fields[#fields+1]=f end
 fields[7]=w.now+600;w.buckets[key]=table.concat(fields,'|');w:load();assert(w.saved[BI].ms==600000)
 w.now=w.now+20;w:load();assert(w.saved[BI].ms==580000);w:errors()
end)
test('upstairs transition removes untargetable Rallos from encounter timer context',function()
 local w=world();w:start();assert(w:mob(U));w:upstairs();assert(not w:mob(U));w:errors()
end)
test('placeholder cannot respawn during upstairs or pit phases and returns on failure',function()
 local w=world();w:start();w:upstairs();w:newnpc(U,500,20,194,64,UI);assert(not w:mob(U));w.env.FailEncounter('test');assert(w:mob(U));w:errors()
 local p=world();p:start();p:pit();p:newnpc(U,500,20,194,64,UI);assert(not p:mob(U));p:errors()
end)
test('reload removes an existing placeholder during an active upstairs fight',function()
 local w=world();w:start();w:upstairs();w.handlers[U].spawn=nil;w:newnpc(U,500,20,194,64,UI);assert(w:mob(U));w:load();assert(not w:mob(U));w:errors()
end)
test('encounter emotes accompany guards brothers leash pit and corpse wave',function()
 local w=world();w:start();w:waypoint(T,3);local n=w:mob(T);n.y=500;w:npctimer(T,'bounds');w:pit();w:combat(W,true);w:npctimer(W,'twitch')
 for _,phrase in ipairs({'unbothered by the death','takes notice at the death','The voice of Tallon Zek booms in your mind','Rallos Zek shouts, "Come then! Come!','fallen champions rise again'})do
  local found=false;for _,l in ipairs(w.logs)do if l:find(phrase,1,true)then found=true end end;assert(found,phrase)
 end;w:errors()
end)
test('original Drunder emotes pair with new RP and every RP line is red',function()
 local w=world();w:start();w:waypoint(T,3);w:waypoint(V,3);w:combat(T,true);w:combat(T,false);w:upstairs();w:combat(R,true);w:combat(R,false)
 local n=w:mob(R);n.hp=75;w:dispatch('hp',n,{hp_event=75});n.hp=50;w:dispatch('hp',n,{hp_event=50});w:combat(W,true);w:npctimer(W,'twitch');w:kill(W)
 local counts={};for _,e in ipairs(w.emotes)do
  if not e.text:find('[RZ ',1,true)then assert(e.color==13,'RP must be red: '..e.text);counts[e.text]=(counts[e.text]or 0)+1 end
 end
 for _,phrase in ipairs({'The air of Drunder grows strangely cold','A tremor rumbles through the halls of Drunder','The warriors of Drunder hear the clash of blades'})do
  local found=0;for text,count in pairs(counts)do if text:find(phrase,1,true)then found=found+count end end;assert(found==1,phrase)
 end;w:errors()
end)
test('failure recovery and ready milestones have red RP cues',function()
 local w=world();w:start();w.env.FailEncounter('test');w.now=w.now+600;w:eventtimer('watchdog');w:newnpc(B,320,301,168,1,BI);w:newnpc(G,320,-286,168,129,GI);w:eventtimer('watchdog')
 for _,phrase in ipairs({'His challenge is withdrawn','The War Room falls silent','The Decorins return to their posts'})do
  local found=false;for _,e in ipairs(w.emotes)do if e.text:find(phrase,1,true)then assert(e.color==13);found=true end end;assert(found,phrase)
 end;w:errors()
end)
test('technical diagnostics reach GMs and server logs but never the zone broadcast',function()
 local w=world();w:start();w:upstairs();w.env.FailEncounter('audience test');assert(#w.clientMessages>0)
 for _,m in ipairs(w.clientMessages)do assert(m.gm and m.color==15 and m.text:find('[RZ ',1,true),'diagnostics must be GM only')end
 for _,e in ipairs(w.emotes)do assert(e.color==13 and not e.text:find('[RZ ',1,true),'players must only receive RP')end
 local logged=false;for _,l in ipairs(w.logs)do if l:find('audience test',1,true)then logged=true end end;assert(logged,'server diagnostic retained');w:errors()
end)
test('a respawned guard loses its old kill while the other guard kill still counts',function()
 for _,pair in ipairs({{B,G,BI},{G,B,GI}})do
  local first,second,spawn=unpack(pair);local w=world();w:load();w:kill(first);w:newnpc(first,320,0,168,0,spawn);w:kill(second);w:eventtimer('doors')
  assert(not w:mob(T)and not w:mob(V),'an old guard kill must not start the encounter')
  w:kill(first);w:eventtimer('doors');assert(w:mob(T)and w:mob(V),'both current guard kills must start the encounter');w:errors()
 end
end)
test('guard respawn invalidates queued start and persists across quest reload',function()
 local w=world();w:load();w:kill(B);w:kill(G);w:newnpc(B,320,301,168,0,BI);w:eventtimer('doors');assert(not w:mob(T))
 local fields={};for f in (w.buckets['rallos-recovery-v3-66']..'|'):gmatch('(.-)|')do fields[#fields+1]=f end
 assert(fields[9]=='0'and fields[10]=='1','only the returning guard kill must be cleared in saved state')
 w:load();assert(not w:mob(T));w:kill(B);w:eventtimer('doors');assert(w:mob(T)and w:mob(V));w:errors()
end)
test('pit Warlord losing all aggro resets home effects and health before another wave',function()
 local w=world();w:start();w:pit();local n=w:mob(W);w:combat(W,true);w.env.SpawnPitWave();assert(w:count(214287)>0)
 n.hp=40;n.x=800;n.y=100;n.buffs={[676]=true,[2885]=true,[369]=true};n.keepDebuffs=true
 w:npctimer(W,'twitch');w:combat(W,false)
 assert(n.x==705 and n.y==0 and n.z==-290 and n.hp==100 and not n.engaged)
 assert(n.interrupted and n.fadeAllCalled and not next(n.buffs) and n.spell==3230 and n.spelltarget==n.id)
 assert(w:count(214287)==0 and w:count(214288)==0);w:eventtimer('wraiths');assert(w:count(214287)==0)
 w:combat(W,true);assert(n.hp==100 and w.timers[n.id..':twitch']==55000);w:errors()
end)
test('pit boundary reset applies Balance once despite nested combat callbacks and preserves idle budget',function()
 local w=world();w:start();w:pit();local n=w:mob(W);w.now=w.now+40;w:combat(W,true);n.hp=40;n.x=1000
 local original=n.SpellOnTarget;local casts=0;n.SpellOnTarget=function(self,id,target)casts=casts+1;return original(self,id,target)end
 w:npctimer(W,'bounds');assert(casts==1 and n.hp==100 and n.x==705 and not n.engaged)
 assert(n:GetEntityVariable('rallos_resetting')=='0'and w.timers[n.id..':depop']==8960000);w:errors()
end)
test('dying pit Warlord is not healed by the final disengage callback and still records success',function()
 local w=world();w:start();w:pit();local n=w:mob(W);w:combat(W,true);n.hp=0;w:combat(W,false)
 assert(n.hp==0 and not n.directSpell and not n.fadeAllCalled)
 w:kill(W);assert(w.saved[BI].ms==237600000);w:errors()
end)
local failures=0
for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and 'PASS ' or 'FAIL ')..t[1]..(ok and '' or ': '..tostring(err)));if not ok then failures=failures+1 end end
assert(failures==0,tostring(failures)..' failed tests')
print(tostring(#tests)..' tests passed')
