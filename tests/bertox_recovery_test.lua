-- From the repository root: lua5.1 tests/bertox_recovery_test.lua
-- Isolated mocks only; no database or game server access.
local path=arg[1] or 'codecay/encounters/Bertox.lua'
local file=assert(io.open(path));local source=file:read('*a');file:close()
local S,C,U,B,P=200016,200195,200260,200226,200269
local SI=360643
local first={200234,200240,200265,200246,200257,200263,200266,200223}
local final={200250,200256,200255,200227}
local trashids={};for i=369228,369264 do if i~=369241 and i~=369244 and i~=369255 and i~=369257 and i~=369260 then trashids[#trashids+1]=i end end
local function world(guild)
 local w={now=100000,guild=guild or 2,entities={},spawns={},timers={},buckets={},logs={},emotes={},messages={},saved={},fail={},signals={},nextid=100}
 local N={}
 function N:GetID()return self.dead and 0 or self.id end
 function N:GetNPCTypeID()return self.t end
 function N:GetSpawnPointID()return self.spawn or 0 end
 function N:GetHP()return self.hp end
 function N:IsCorpse()return self.dead or false end
 function N:GetCleanName()return 'NPC '..self.t end
 function N:GetName()return self:GetCleanName()end
 function N:GetX()return self.x end
 function N:GetY()return self.y end
 function N:GetZ()return self.z end
 function N:SetEntityVariable(k,v)self.vars[k]=v end
 function N:GetEntityVariable(k)return self.vars[k]or''end
 function N:ResumeWandering()end
 function N:RemoveWaypoints()end
 function N:SaveGuardSpot()end
 function N:GetGrid()return 0 end
 function N:GetMaxWp()return 2 end
 function N:Depop()self.valid=false;w.entities[self.id]=nil;if self.spawn and w.spawns[self.spawn]then w.spawns[self.spawn].npc=nil end end
 function w:invoke(kind,n,args)
  local fn=self.handlers and self.handlers[n.t]and self.handlers[n.t][kind];if not fn then return end
  local previous=self.owner;self.owner=n;args.self=n;fn(args);self.owner=previous
 end
 function w:newnpc(t,spawn,x,y,z)
  if self.fail[t]then return{valid=false}end
  self.nextid=self.nextid+1
  local n=setmetatable({t=t,id=self.nextid,spawn=spawn,x=x or 0,y=y or 0,z=z or -250,hp=100,valid=true,vars={}},{__index=N})
  self.entities[n.id]=n;if spawn then self.spawns[spawn].npc=n end;self:invoke('spawn',n,{});return n
 end
 function w:mob(t)for _,n in pairs(self.entities)do if n.valid and not n.dead and n.t==t then return n end end end
 function w:count(t)local count=0;for _,n in pairs(self.entities)do if n.valid and not n.dead and n.t==t then count=count+1 end end;return count end
 function w:kill(t)
  local n=assert(self:mob(t),'missing kill target '..t);n.dead=true;n.hp=0;if n.spawn then self.spawns[n.spawn].npc=nil end
  self:invoke('death',n,{killer={valid=true,GetCleanName=function()return'Tester'end,GetID=function()return 9000 end}});n:Depop();return n
 end
 function w:trash(n)for i=1,n do self:newnpc(200247,trashids[(i-1)%#trashids+1]);self:kill(200247)end end
 function w:eventtimer(name)local previous=self.owner;self.owner=self.encounter;self.env.event_timer({timer=name});self.owner=previous end
 function w:check()self:eventtimer('watchdog')end
 function w:phase()return tonumber((self.buckets['bertox-recovery-v1-'..self.guild]or''):match('^(%d+)'))end
 function w:trashcount()return tonumber((self.buckets['bertox-recovery-v1-'..self.guild]or''):match('^%d+|%d+|(%d+)'))end
 function w:errors()for _,l in ipairs(self.logs)do assert(not l:find('Lua callback failed',1,true),l)end end
 local Spawn={}
 function Spawn:Disable()self.enabled=false;if self.npc then self.npc:Depop()end end
 function Spawn:Enable()self.enabled=true end
 function Spawn:Enabled()return self.enabled end
 function Spawn:GetNPC()return self.npc or{valid=false}end
 function Spawn:NPCPointerValid()return self.npc~=nil end
 function Spawn:SetTimer(ms)self.timer=ms;self.scriptTimer=true end
 function Spawn:SetRespawnTimer(seconds)self.respawn=seconds;self.scriptRespawn=true end
 function Spawn:SetVariance(v)self.variance=v end
 w.spawns[SI]=setmetatable({valid=true,id=SI,enabled=true},{__index=Spawn})
 for _,id in ipairs(trashids)do w.spawns[id]=setmetatable({valid=true,id=id,enabled=true},{__index=Spawn})end
 w:newnpc(S,SI);w:newnpc(C)
 local el={}
 function el:GetSpawnByID(id)return w.spawns[id]or{valid=false}end
 function el:GetMobByNpcTypeID(t)return w:mob(t)or{valid=false}end
 function el:GetNPCList()local list={};for _,n in pairs(w.entities)do list[#list+1]=n end;local i=0;return{entries=function()i=i+1;return list[i]end}end
 function el:GetClientList()
  local list={};for _,value in ipairs({true,false})do local gm=value;list[#list+1]={valid=true,GetGM=function()return gm end,Message=function(_,color,text)w.messages[#w.messages+1]={gm=gm,color=color,text=text}end}end
  local i=0;return{entries=function()i=i+1;return list[i]end}
 end
 function w:load()
  self.handlers={};self.encounter={id=-100};self.owner=self.encounter
  local env=setmetatable({os={time=function()return self.now end},Event={spawn='spawn',death_complete='death',timer='timer',signal='signal',combat='combat',waypoint_arrive='waypoint'}},{__index=_G});self.env=env
  env.eq={get_zone_guild_id=function()return self.guild end,get_entity_list=function()return el end,
   get_data=function(k)return self.buckets[k]or''end,set_data=function(k,v)self.buckets[k]=v end,
   zone_emote=function(color,text)self.emotes[#self.emotes+1]={color=color,text=text}end,debug=function(text)self.logs[#self.logs+1]=text end,
   set_timer=function(name,ms,owner)owner=owner or self.owner;self.timers[owner.id..':'..name]=ms end,
   stop_timer=function(name,owner)owner=owner or self.owner;self.timers[owner.id..':'..name]=nil end,
   stop_all_timers=function(owner)owner=owner or self.owner;local prefix=owner.id..':';for k in pairs(self.timers)do if k:sub(1,#prefix)==prefix then self.timers[k]=nil end end end,
   pause_timer=function()end,resume_timer=function()end,
   spawn2=function(t,grid,a,x,y,z,h)return self:newnpc(t,nil,x,y,z)end,
   update_spawn_timer=function(id,ms)self.saved[id]={at=self.now,ms=ms}end,
   signal=function(t,s)self.signals[#self.signals+1]={t=t,value=s}end,
   register_npc_event=function(_,kind,t,callback)self.handlers[t]=self.handlers[t]or{};self.handlers[t][kind]=callback end}
  local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();env.event_encounter_load({encounter=self.encounter});self:eventtimer('initialize')
 end
 function w:prepare()self:load();self:kill(S);assert(self:phase()==1 and self:count(U)==5);self.start=self.now;self:errors()end
 function w:begin()self:prepare();self.now=self.now+350;self:eventtimer('prepare');assert(self:phase()==2);self:errors()end
 function w:kings()self:trash(96);for _,t in ipairs(first)do self:kill(t)end;assert(self:phase()==3);for _,t in ipairs(final)do self:kill(t)end;assert(self:phase()==4 and self:mob(B));self:errors()end
 return w
end
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
local function reset(w)
 assert(w:phase()==5 and w.saved[SI].ms==300000 and w.spawns[SI].enabled)
 for _,t in ipairs(first)do assert(not w:mob(t))end;for _,t in ipairs(final)do assert(not w:mob(t))end;assert(not w:mob(U)and not w:mob(B))
 for _,id in ipairs(trashids)do if w.spawns[id]then assert(not w.spawns[id].enabled)end end;w:errors()
end
test('fresh load disables boot-enabled event trash without starting the encounter',function()
 local w=world();w:load();assert(w:phase()==0 and w:mob(S));for _,id in ipairs(trashids)do assert(not w.spawns[id].enabled)end;w:errors()
end)
test('preparation stays closed for 350 seconds and restores its remaining delay on reload',function()
 local w=world();w:prepare();w.now=w.now+175;w:load();assert(w.timers['-100:prepare']==175000);w:eventtimer('prepare');assert(w:phase()==1);w.now=w.now+175;w:eventtimer('prepare');assert(w:phase()==2);w:errors()
end)
test('all event trash uses the explicit 350-second respawn in guild instances',function()
 local w=world();w:begin();for _,id in ipairs(trashids)do local s=w.spawns[id];assert(s.enabled and s.respawn==350 and s.scriptRespawn and s.variance==0)end;w:errors()
end)
test('idle and foreign trash kills cannot advance counters',function()
 local w=world();w:load();for i=1,44 do local n=w:newnpc(200247);n.dead=true;n.hp=0;w:invoke('death',n,{})end;assert(w:trashcount()==0 and not w:mob(first[1]))
 w:kill(S);w.now=w.now+350;w:eventtimer('prepare');local n=w:newnpc(200247);n.dead=true;n.hp=0;w:invoke('death',n,{});assert(w:trashcount()==0);w:errors()
end)
test('trash death is credited only once even when the callback repeats',function()
 local w=world();w:begin();local n=w:newnpc(200247,trashids[1]);n.dead=true;n.hp=0;w:invoke('death',n,{});w:invoke('death',n,{});assert(w:trashcount()==1);w:errors()
end)
test('kill thresholds summon each of the first eight kings once',function()
 local w=world();w:begin();w:trash(43);assert(not w:mob(first[1]));w:trash(1);assert(w:count(first[1])==1);w:trash(52)
 for _,t in ipairs(first)do assert(w:count(t)==1)end;assert(not w:mob(final[1]));w:errors()
end)
test('final four require all eight distinct tracked kings and Bertox requires all twelve',function()
 local w=world();w:begin();w:trash(96);for i=1,7 do w:kill(first[i])end;assert(w:phase()==2 and not w:mob(final[1]))
 w:kill(first[8]);assert(w:phase()==3);for _,t in ipairs(final)do assert(w:count(t)==1)end
 for i=1,3 do w:kill(final[i])end;assert(not w:mob(B));w:kill(final[4]);assert(w:phase()==4 and w:count(B)==1);w:errors()
end)
test('duplicate and old-attempt king deaths do not replace distinct kills',function()
 local w=world();w:begin();w:trash(96);local dead=w:kill(first[1]);dead.valid=true;w:invoke('death',dead,{});assert(w:phase()==2 and not w:mob(final[1]))
 local ghost=w:newnpc(first[2]);ghost.valid=true;ghost.dead=true;ghost.hp=0;ghost:SetEntityVariable('bertox_attempt','0');ghost:SetEntityVariable('bertox_entity',tostring(ghost.id));w:invoke('death',ghost,{})
 for i=2,7 do w:kill(first[i])end;assert(not w:mob(final[1]));w:kill(first[8]);assert(w:phase()==3);w:errors()
end)
test('failure removes all kings and prevents the reported eight-Adan overlap on retry',function()
 local w=world();w:begin();w:trash(56);w.env.Fail=nil;w:mob(first[1]):Depop();w:check();w.now=w.now+10;w:check();reset(w)
 w.now=w.now+300;w:newnpc(S,SI);assert(w:phase()==0);w:kill(S);w.now=w.now+350;w:eventtimer('prepare');w:trash(96)
 for _,t in ipairs(first)do assert(w:count(t)==1)end;for _,t in ipairs(first)do w:kill(t)end
 for _,t in ipairs(first)do assert(not w:mob(t))end;for _,t in ipairs(final)do assert(w:count(t)==1)end;w:errors()
end)
test('reload preserves trash milestones, king deaths, and expected live bosses',function()
 local w=world();w:begin();w:trash(43);w:load();w:trash(1);assert(w:count(first[1])==1);w:trash(52);for i=1,4 do w:kill(first[i])end;w:load()
 for i=1,4 do assert(not w:mob(first[i]))end;for i=5,8 do w:kill(first[i])end;assert(w:phase()==3);w:load();for _,t in ipairs(final)do w:kill(t)end;assert(w:phase()==4);w:errors()
end)
test('missing controller cannot strand timers or progression',function()
 local w=world();w:begin();w:mob(C):Depop();assert(w.timers['-100:watchdog']);w:kings();assert(w:phase()==4);w:errors()
end)
test('missing boss or summoner triggers five-minute recovery instead of progress',function()
 local w=world();w:begin();w:trash(44);w:mob(first[1]):Depop();w:check();w.now=w.now+10;w:check();reset(w)
 local s=world();s:begin();s:mob(U):Depop();s:check();s.now=s.now+10;s:check();reset(s)
end)
test('spawn failures roll back instead of silently losing a milestone',function()
 local w=world();w:begin();w.fail[first[1]]=true;w:trash(44);reset(w)
 local f=world();f:begin();f:trash(96);f.fail[final[1]]=true;for _,t in ipairs(first)do f:kill(t)end;reset(f)
end)
test('Bertox spawn failure cleans the final kings and starts recovery',function()
 local w=world();w:begin();w:trash(96);for _,t in ipairs(first)do w:kill(t)end;w.fail[B]=true;for _,t in ipairs(final)do w:kill(t)end;reset(w)
end)
test('repeated Spectre deaths and old controller signals cannot restart an active attempt',function()
 local w=world();w:begin();w:trash(44);local state=w.buckets['bertox-recovery-v1-2'];local ghost=w:newnpc(S,SI);ghost.valid=true;ghost.dead=true;ghost.hp=0;w:invoke('death',ghost,{})
 w:invoke('signal',w:mob(C),{signal=1});w:invoke('timer',w:mob(C),{timer='start'});assert(w.buckets['bertox-recovery-v1-2']==state and w:count(first[1])==1);w:errors()
end)
test('warning occurs once and the absolute 123-minute deadline wins over a late kill',function()
 local w=world();w:begin();w:kings();w.now=w.start+7080;w:check();w:check();local count=0;for _,e in ipairs(w.emotes)do if e.text:find('Dark voices',1,true)then count=count+1 end end;assert(count==1)
 w.now=w.start+7380;w:kill(B);reset(w);assert(not w:mob(P))
end)
test('success awards the projection and preserves the 66-hour cooldown on reload',function()
 local w=world();w:begin();w:kings();w:kill(B);assert(w:phase()==6 and w.saved[SI].ms==237600000 and w:mob(P));assert(w.signals[#w.signals].t==P and w.signals[#w.signals].value==9000)
 w.now=w.now+120;w:load();assert(w:phase()==6 and w.saved[SI].ms==237480000);w:errors()
end)
test('projection failure cannot turn success into a short retry',function()
 local w=world();w:begin();w:kings();w.fail[P]=true;w:kill(B);assert(w:phase()==6 and w.saved[SI].ms==237600000);w:errors()
end)
test('early Spectre spawns preserve the original retry deadline and elapsed death can start immediately',function()
 local w=world();w:begin();w:trash(44);w:mob(first[1]):Depop();w:check();w.now=w.now+10;w:check();reset(w)
 w.now=w.now+100;w:newnpc(S,SI);assert(not w:mob(S)and w.saved[SI].ms==200000);w:load();assert(w.saved[SI].ms==200000)
 w.now=w.now+200;w:newnpc(S,SI);assert(w:phase()==0);w:kill(S);assert(w:phase()==1);w:errors()
end)
test('zone restart without the saved NPCs recovers instead of adopting an unverified run',function()
 local w=world();w:begin();w:trash(44);local r=world();r.buckets=w.buckets;r.now=w.now;r:load();reset(r)
end)
test('old orphan kings are cleared without shortening an unknown Spectre cooldown',function()
 local w=world();w:newnpc(first[1]);w.spawns[SI].timer=237600000;w:load();assert(w:phase()==0 and not w:mob(first[1])and w.spawns[SI].timer==237600000 and not w.saved[SI]);w:errors()
end)
test('repop clearing timers is repaired by spawned controller activity',function()
 local w=world();w:begin();w:trash(44);local snapshot={};for _,n in pairs(w.entities)do snapshot[#snapshot+1]=n end;for _,n in ipairs(snapshot)do n:Depop()end;w.timers={}
 w:newnpc(C);w:newnpc(S,SI);assert(w.timers['-100:watchdog']);w:check();w.now=w.now+10;w:check();reset(w)
end)
test('missing trash spawnpoints produce recovery rather than partial waves',function()
 local w=world();w:prepare();w.spawns[trashids[1]]=nil;w.now=w.now+350;w:eventtimer('prepare');reset(w)
end)
test('RP stays red and technical diagnostics remain GM-only and in server logs',function()
 local w=world();w:begin();w:kings();w:kill(B);assert(#w.messages>0 and #w.logs>0 and #w.emotes>0)
 for _,e in ipairs(w.emotes)do assert(e.color==13 and not e.text:find('[Bertox ',1,true))end
 for _,m in ipairs(w.messages)do assert(m.gm and m.color==15 and m.text:find('[Bertox ',1,true))end;w:errors()
end)
test('untracked old active encounters recover with all Adans removed',function()
 local w=world();w:newnpc(first[1]);w:newnpc(U);w:load();reset(w)
end)
test('a replacement with a recycled entity ID cannot impersonate a tracked king',function()
 local w=world();w:begin();w:trash(44);local old=w:mob(first[1]);old:Depop();w.nextid=old.id-1;local replacement=w:newnpc(first[1]);assert(not replacement.valid)
 w:check();w.now=w.now+10;w:check();reset(w)
end)
test('a Spectre killed after cooldown expiry starts even before the spawn ready callback',function()
 local w=world();w:begin();w:trash(44);w:mob(first[1]):Depop();w:check();w.now=w.now+10;w:check();reset(w)
 w.now=w.now+300;w.handlers[S].spawn=nil;w:newnpc(S,SI);w:kill(S);assert(w:phase()==1 and w:count(U)==5);w:errors()
end)
test('Guild 1 native Spectre repops supersede Lua success cooldown while other guilds retain it',function()
 local w=world(1);w:begin();w:kings();w:kill(B);assert(w:phase()==6);w:newnpc(S,SI);assert(w:phase()==0 and w:mob(S));w:errors()
 local g=world(2);g:begin();g:kings();g:kill(B);g:newnpc(S,SI);assert(g:phase()==6 and not g:mob(S));g:errors()
end)
test('Guild 1 quake/fresh-zone trigger interrupts old progress without stranding the trigger',function()
 local w=world(1);w:begin();w:trash(44);w:newnpc(S,SI);assert(w:phase()==0 and w:mob(S)and not w:mob(first[1])and not w:mob(U))
 w:kill(S);assert(w:phase()==1 and w:count(U)==5);w:errors()
 local g=world(1);g:begin();g:kings();g:kill(B);g.handlers[S].spawn=nil;g:newnpc(S,SI);g:load();assert(g:phase()==0 and g:mob(S));g:errors()
end)
test('runtime callback errors are logged and recover active attempts',function()
 local w=world();w:prepare();w.spawns[trashids[1]].SetRespawnTimer=function()error('injected configuration failure')end
 w.now=w.now+350;w:eventtimer('prepare');assert(w:phase()==5 and w.saved[SI].ms==300000)
 local found=false;for _,l in ipairs(w.logs)do if l:find('injected configuration failure',1,true)then found=true end end;assert(found)
end)
local failures=0;for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and'PASS 'or'FAIL ')..t[1]..(ok and''or': '..tostring(err)));if not ok then failures=failures+1 end end
assert(failures==0,failures..' failed Bertox checks');print(#tests..' Bertox recovery checks passed')
