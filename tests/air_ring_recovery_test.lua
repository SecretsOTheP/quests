-- Lua 5.1: lua tests/air_ring_recovery_test.lua /path/to/Quests
local root=arg[1] or ".";
local checks=0;
local function check(ok,why) assert(ok,why); checks=checks+1; end
local Event={spawn=1,timer=2,signal=3,death=4,death_complete=5,combat=6};
local config={
 Wind={controller=215420,marker=215414,boss=215390,avatar=215391,native=215013,first="priest"},
 Smoke={controller=215421,marker=215415,boss=215396,avatar=215392,native=215012,first="champions"},
 Mist={controller=215423,marker=215416,boss=215399,avatar=215393,native=215026,first="fire"},
 Dust={controller=215422,marker=215417,boss=215375,avatar=215394,native=215043,first="arch1"}
};
local function read(path) local f=assert(io.open(path)); local s=f:read("*a");f:close();return s;end
local function iterator(values)
 local i=0; return function() i=i+1; return values[i]; end;
end
local function world(name,guild)
 local w={name=name,c=config[name],guild=guild or 72,now=1800000000,next_id=1,npcs={},points={},registry={},
  buckets={},timers={},logs={},fail={},spawned={},consumes=0,reads=0,writes=0,repop_count=0};
 local tag="air_"..name:lower();w.tag=tag;
 local key="poair-ring-v1-"..name:lower().."-"..w.guild; w.key=key;
 local source=read(root.."/poair/encounters/"..name..".lua");
 w.island={}; for id in source:match("local ISLAND_SPAWNIDS = {(.-)}"):gmatch("%d+") do w.island[#w.island+1]=tonumber(id);end
 function w:dispatch(event,n,e)
  e=e or {};e.self=n;
  local cb=self.registry[n.kind..":"..event];
  if cb then return cb(e);end
 end
 function w:new_npc(kind,pid,loc,emit)
  if self.fail[kind] then return nil;end
  loc=loc or {0,0,0,0};
  local n={valid=true,id=self.next_id,kind=kind,hp=100,vars={},point=pid or 0,loc=loc,abilities={},engaged=false};
  self.next_id=self.next_id+1;self.npcs[#self.npcs+1]=n;self.spawned[kind]=(self.spawned[kind] or 0)+1;
  function n:GetID() return self.id;end
  function n:GetNPCTypeID() return self.kind;end
  function n:GetHP() return self.hp;end
  function n:IsCorpse() return self.corpse or false;end
  function n:GetHPRatio() return self.hp;end
  function n:GetMaxHP() return 100;end
  function n:SetHP(hp) self.hp=hp;end
  function n:GetSpawnPointID() return self.point;end
  function n:GetX() return self.loc[1];end
  function n:GetY() return self.loc[2];end
  function n:GetZ() return self.loc[3];end
  function n:GetSpawnPointH() return self.loc[4];end
  function n:GetEntityVariable(k) return self.vars[k] or "";end
  function n:SetEntityVariable(k,v) self.vars[k]=v;end
  function n:CastToNPC() return self;end
  function n:MoveTo(x,y,z) check(x~=nil and y~=nil and z~=nil,"movement coordinates are defined");end
  function n:SetSpecialAbility(id,v) self.abilities[id]=v;end
  function n:SetBodyType(v) self.body=v;end
  function n:ChangeSize(v) self.size=v;end
  function n:SetRunning() end
  function n:IsEngaged() return self.engaged;end
  function n:Shout() end
  function n:GetTarget() return {valid=false};end
  function n:GetHateList() return {entries=iterator({})};end
  function n:AddToHateList() self.engaged=true;end
  function n:Depop() self.valid=false;end
  if pid then self.points[pid].npc=n;end
  if emit then self:dispatch(Event.spawn,n);end
  return n;
 end
 function w:point(id,kind)
  local p={valid=true,id=id,kind=kind,enabled=true};self.points[id]=p;
  function p:GetNPC() return self.npc and self.npc.valid and self.npc or {valid=false};end
  function p:Repop()
   if self.npc then self.npc.valid=false;end
   w.repop_count=w.repop_count+1;
   self.npc=w:new_npc(self.kind,self.id,nil,true);
  end
  function p:Enable() self.enabled=true;end
  function p:Disable() self.enabled=false;end
  self:new_npc(kind,id);return p;
 end
 for _,id in ipairs(w.island) do w:point(id,w.c.native);end
 if name=="Dust" then
  w:point(366131,w.c.boss);
  for id=369505,369519 do w:point(id,215402):Disable();w.points[id].npc.valid=false;end
 end
 w:new_npc(w.c.marker);w:new_npc(w.c.controller);
 function w:find(kind)
  for _,n in ipairs(self.npcs) do if n.valid and n.hp>0 and not n.corpse and n.kind==kind then return n;end end
  return {valid=false};
 end
 function w:role(role)
  for _,n in ipairs(self.npcs) do if n.valid and n.hp>0 and not n.corpse and n.vars[tag.."_role"]==role then return n;end end
  return nil;
 end
 function w:state()
  local f={};for v in ((self.buckets[key] or "").."|"):gmatch("(.-)|") do f[#f+1]=v;end;return f;
 end
 function w:phase() return self:state()[3];end
 function w:pulse()
  local controller=self:find(self.c.controller);
  self:dispatch(Event.timer,controller,{timer="air_ring_recovery"});
 end
 function w:kill(n)
  assert(n and n.valid and n.hp>0,"expected living target");
  self:dispatch(Event.death,n);
  n.hp=0;n.corpse=true;
  self:dispatch(Event.death_complete,n);
  return n;
 end
 function w:kill_role(role) return self:kill(assert(self:role(role),"missing role "..role));end
 function w:kill_island(n)
  for i=1,n or #self.island do local p=self.points[self.island[i]];if p.npc.hp>0 then self:kill(p.npc);end end
 end
 function w:load(unload,elapsed)
  self.now=self.now+(elapsed or 0);
  if unload then
   local alive={};
   for _,n in ipairs(self.npcs) do
    if n.valid and n.hp>0 and not n.corpse and (n.point>0 or n.kind==self.c.marker or n.kind==self.c.controller) then
     alive[#alive+1]={kind=n.kind,point=n.point};
    end
    n.valid=false;
   end
   self.timers={};
   for _,v in ipairs(alive) do self:new_npc(v.kind,v.point>0 and v.point or nil);end
  end
  self.registry={};
  local elist={};
  function elist:GetNPCByNPCTypeID(id) return w:find(id);end
  function elist:GetSpawnByID(id) return w.points[id] or {valid=false};end
  function elist:GetNPCList() return {entries=iterator(w.npcs)};end
  function elist:IsMobSpawnedByNpcTypeID(id) return w:find(id).valid;end
  local eq={
   get_zone_guild_id=function() return w.guild;end,
   guild_one_raid_window_open=function() return false;end,
   get_entity_list=function() return elist;end,
   get_data=function(k) w.reads=w.reads+1;return w.buckets[k] or "";end,
   set_data=function(k,v) w.writes=w.writes+1;w.buckets[k]=v;end,
   set_timer=function(k,v,n) w.timers[k..":"..(n and n.id or 0)]=v;end,
   stop_timer=function() end,pause_timer=function() end,resume_timer=function() end,
   debug=function(v) w.logs[#w.logs+1]=v;end,
   depop_all=function(id) for _,n in ipairs(w.npcs) do if n.kind==id and n.hp>0 then n.valid=false;end end end,
   depop_with_timer=function(id) w.consumes=w.consumes+1;local n=w:find(id);n.valid=false;end,
   depop=function() end,
   unique_spawn=function(id,_,__,x,y,z,h)
    local n=w:find(id);if n.valid then return n;end;return w:new_npc(id,nil,{x,y,z,h},true);
   end,
   spawn2=function(id,_,__,x,y,z,h) return w:new_npc(id,nil,{x,y,z,h},true);end,
   register_npc_event=function(owner,event,id,cb)
    check(owner==name,"callbacks belong to the correct encounter");w.registry[id..":"..event]=cb;
   end,
   signal=function() error("legacy stage signal must not run in a guild instance");end
  };
  local env={eq=eq,Event=Event,os={time=function() return w.now;end}};
  setmetatable(env,{__index=_G});
  env.require=function(module)
   check(module=="air_ring_recovery","only recovery dependency loaded");
   return setfenv(assert(loadfile(root.."/lua_modules/"..module..".lua")),env)();
  end
  setfenv(assert(loadfile(root.."/poair/encounters/"..name..".lua")),env)();env.event_encounter_load({});w.env=env;
 end
 w:load(false);return w;
end

local function to_boss(w)
 if w.name=="Wind" then
  if w:phase()=="priest" then w:kill_role("priest");end
  if w:phase()=="traps" then
   for i=1,4 do
    local trap=w:role("trap"..i);if trap then w:dispatch(Event.combat,trap,{joined=true});end
    if w:role("sporadic"..i) then w:kill_role("sporadic"..i);end
   end
  end
 elseif w.name=="Smoke" then
  for _,i in ipairs({5,10,15,21}) do if w:role("champ"..i) then w:kill_role("champ"..i);end end
 elseif w.name=="Mist" then
  for _,p in ipairs({"fire","wind"}) do for i=1,4 do if w:role(p..i) then w:kill_role(p..i);end end end
 else
  for round=1,3 do
   if w:role("arch"..round) then w:kill_role("arch"..round);end
   for i=1,3 do if w:role("adds"..round.."_"..i) then w:kill_role("adds"..round.."_"..i);end end
  end
 end
 check(w:phase()=="boss",w.name.." reaches its boss after confirmed wave deaths");
end

for _,name in ipairs({"Wind","Smoke","Mist","Dust"}) do
 local w=world(name);w:pulse();
 w:kill_island(3);local deadline=tonumber(w:state()[4]);
 w:load(false,60);w:pulse();
 check(tonumber(w:state()[4])==deadline,name.." partial clearing deadline survives quest reload");
 check(w:state()[13]~="",name.." native kill credit survives quest reload");
 w:kill_island();
 check(w:phase()==w.c.first,name.." starts the correct first wave");
 local finish=tonumber(w:state()[4]);check(finish-w.now==237600,"66-hour window unchanged");
 w:load(false,120);w:pulse();
 check(w:phase()==w.c.first and tonumber(w:state()[4])==finish,name.." living wave and original deadline survive quest reload");
 to_boss(w);
 local boss=w:role("boss");
 w.fail[w.c.avatar]=true;
 w:kill(boss);
 check(w:phase()=="avatar" and w.consumes==0,name.." failed Avatar spawn retains the marker");
 check(w:find(w.c.marker).valid,name.." marker remains alive while spawn fails");
 w:dispatch(Event.death_complete,boss);
 check(w.consumes==0,name.." duplicate boss death does not consume marker");
 w:load(true,30);w:pulse();
 check(w:phase()=="avatar" and w.consumes==0,name.." failed handoff survives unload");
 w.fail[w.c.avatar]=nil;w:pulse();
 local avatar=w:role("avatar");check(avatar~=nil and w.consumes==1,name.." recovered Avatar consumes marker exactly once");
 local spawned=w.spawned[w.c.avatar];w:pulse();w:load(false);w:pulse();
 check(w.spawned[w.c.avatar]==spawned and w.consumes==1,name.." reload keeps a living Avatar without duplicating it");
 local remaining=tonumber(w:state()[7]);
 avatar.engaged=true;w:dispatch(Event.combat,avatar,{joined=true});w.now=w.now+300;w:pulse();
 check(tonumber(w:state()[7])==remaining,name.." Avatar combat pauses its idle budget");
 w:load(false,60);w:pulse();
 check(tonumber(w:state()[7])==remaining,name.." quest reload preserves an engaged Avatar's pause");
 avatar.engaged=false;w:dispatch(Event.combat,avatar,{joined=false});w.now=w.now+60;w:pulse();
 check(tonumber(w:state()[7])==remaining-60,name.." idle budget resumes after combat");
 w:load(true,60);w:pulse();
 check(tonumber(w:state()[7])==remaining-120,name.." unloaded time counts against idle budget");
 check(w.consumes==1,name.." restoring an earned Avatar does not restart marker cooldown");
 local dead=w:kill_role("avatar");
 check(w:phase()=="cooldown",name.." confirmed Avatar death finishes the ring");
 w:load(true,60);w:pulse();
 check(not w:role("avatar"),name.." killed Avatar is never restored");
 check(tonumber(w:state()[4])==finish,name.." completion keeps original island deadline");
 w.now=finish;w:pulse();check(w:phase()=="island",name.." original deadline permits next island cycle");
 check(tonumber(w:state()[4])==finish+1080,name.." normal clearing timer remains 18 minutes");
 for _,id in ipairs(w.island) do check(w.points[id].npc.valid and w.points[id].npc.hp>0,name.." island repopped");end
end

-- A missing stage enemy is not a kill. Only the missing slot is recreated.
for _,name in ipairs({"Mist","Smoke","Dust"}) do
 local w=world(name);w:kill_island();
 local role=name=="Mist" and "fire1" or name=="Smoke" and "champ5" or "arch1";
 local n=w:role(role);local kind=n.kind;n.valid=false;w.fail[kind]=true;w:pulse();
 check(w:phase()==w.c.first,name.." missing enemy does not advance the wave");
 w.fail[kind]=nil;w:pulse();check(w:role(role)~=nil,name.." missing enemy retries");
 local killed=w:kill_role(role);w:dispatch(Event.death_complete,killed);
 w:load(false,10);w:pulse();check(not w:role(role),name.." confirmed wave death stays dead across quest reload");
end
do
 local w=world("Dust");w:kill_island();local end_at=tonumber(w:state()[6]);local reset=tonumber(w:state()[4]);
 w:load(false,60);w:pulse();check(tonumber(w:state()[6])==end_at,"Dust one-hour timer is not restarted by quest reload");
 w.now=end_at;w:pulse();check(w:phase()=="failed" and not w:role("arch1"),"Dust expired attempt cleans up");
 for id=369505,369519 do check(not w.points[id].enabled,"Dust disables erratic spawnpoints on expiry");end
 check(tonumber(w:state()[4])==reset,"Dust cleanup preserves original 66-hour island reset");
 w:load(true,10);w:pulse();check(w:phase()=="island","unloading a failed Dust attempt permits a fresh attempt");
end
do
 local w=world("Smoke");w:kill_island(5);local n=w:role("champ5");check(n and n.abilities[24]~=0,"early champion remains locked");
 local old=w.points[w.island[1]].npc;local before=w:state()[13];
 w:dispatch(Event.death_complete,old);check(w:state()[13]==before,"duplicate native death does not add a kill");
 w:load(false,60);w:pulse();check(w:role("champ5")~=nil,"partial Smoke champion survives quest reload");
 local unrelated=w:new_npc(215012);w:kill(unrelated);check(w:phase()=="island","unrelated elemental does not count");
 w:kill_island();for _,i in ipairs({5,10,15,21}) do check(w:role("champ"..i).abilities[24]==0,"all champions unlock after island completion");end
end
do
 local w=world("Smoke");w:kill_island(20);
 local p=w.points[w.island[1]];p:Repop();
 w:kill(w.points[w.island[21]].npc);check(w:phase()=="island","respawned native prevents a premature clear");
 w:kill(p.npc);check(w:phase()=="champions","re-killing a respawned native can finish the clearing stage");
end
for _,name in ipairs({"Wind","Smoke","Mist","Dust"}) do
 local w=world(name,1);
 check(w.reads==0 and w.writes==0,"Guild 1 has no recovery bucket access");
 w.env.ControllerSignal({signal=1});check(w.reads==0 and w.writes==0,"closed Guild 1 quake window remains blocked");
 local g2=world(name);g2:kill_island();local other=world(name,73);other.buckets=g2.buckets;other:load(false);
 check(other:phase()=="island","saved progress is isolated to its guild");
end
-- Approved policy: unfinished rings reset on zone unload; completed cooldowns
-- and earned Avatar handoffs above are exempt from that fresh-attempt reset.
for _,name in ipairs({"Wind","Smoke","Mist","Dust"}) do
 local w=world(name);w:kill_island();local old_cycle=w:state()[2];
 w:load(true,60);w:pulse();
 check(w:phase()=="island" and w:state()[2]~=old_cycle,name.." unload resets the unfinished ring");
 check(w:state()[13]=="" and w:state()[14]=="",name.." fresh attempt clears old counters");
 check(tonumber(w:state()[4])==w.now+1080,name.." fresh attempt uses original 18-minute clearing timer");
 check(w:find(w.c.marker).valid and w.consumes==0,name.." reset does not consume availability");
 for _,id in ipairs(w.island) do check(w.points[id].npc.valid and w.points[id].npc.hp>0,name.." fresh native island respawns");end
 w:kill_island();to_boss(w);w:kill_role("boss");
 check(w:role("avatar")~=nil,name.." reset ring can complete normally");
end
for _,name in ipairs({"Wind","Smoke","Mist","Dust"}) do
 local w=world(name);w:kill_island();
 -- A forced repop replaces the controller within the same Lua VM.
 local controller=w:find(w.c.controller);controller.valid=false;
 local replacement=w:new_npc(w.c.controller,nil,nil,true);w:pulse();
 check(w:phase()=="island",name.." controller replacement resets the unfinished attempt");
 w:kill_island();to_boss(w);w:kill_role("boss");
 local avatar=w:role("avatar");w.now=w.now+9000;w:pulse();
 check(w:phase()=="cooldown" and not avatar.valid,name.." idle expiry depops Avatar without restoring it");
 w:load(true,1);w:pulse();check(not w:role("avatar"),name.." expired Avatar stays expired after unload");
end
print("PASS: "..checks.." Air recovery checks");
