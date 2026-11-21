-- Lua 5.1: lua tests/air_travel_trash_test.lua /path/to/Quests
local root=arg[1] or ".";
local checks=0;
local function check(ok,why) assert(ok,why);checks=checks+1;end
local function read(f) local h=assert(io.open(root.."/"..f));local s=h:read("*a");h:close();return s;end
local fixture=assert(loadfile(root.."/tests/fixtures/air_spawn_audit.lua"))();
local map=assert(loadfile(root.."/lua_modules/air_trash_spawns.lua"))();
local Event={spawn=1,timer=2,death_complete=3};
local function world(guild)
 local w={guild=guild or 72,now=1800000000,points={},npcs={},registry={},buckets={},timers={},next_id=1,reads=0,writes=0,consumes=0,roll=0};
 function w:find(id)
  for _,n in ipairs(self.npcs) do if n.valid and n.hp>0 and n.kind==id then return n;end;end
  return {valid=false};
 end
 function w:dispatch(event,n,e)
  e=e or {};e.self=n;e.killer={GetID=function() return 900;end};
  self.current=n;
  local names={[215000]="A_Castellan_of_Air",[215419]="POACastellanController",
   [215383]="#Constable_Alranderisan",[215384]="#Constable_Belecohen",[215385]="#Constable_Ferabalen",[215411]="#Chamberlain_Escalardian"};
  local script=names[n.kind] and self.scripts[names[n.kind]];
  local handler=({[1]="event_spawn",[2]="event_timer",[3]="event_death_complete"})[event];
  if script and script[handler] then script[handler](e);end
  local cb=self.registry[n.kind..":"..event];if cb then cb(e);end
  self.current=nil;
 end
 function w:new_npc(kind,pid,emit)
  local n={valid=true,hp=100,kind=kind,pid=pid or 0,id=self.next_id};self.next_id=self.next_id+1;self.npcs[#self.npcs+1]=n;
  function n:GetID() return self.id;end
  function n:GetHP() return self.hp;end
  function n:IsCorpse() return self.hp<=0;end
  function n:GetSpawnPointID() return self.pid;end
  function n:GetNPCTypeID() return self.kind;end
  function n:Depop() self.valid=false;end
  function n:GetX() return 0;end;function n:GetY() return 0;end;function n:GetZ() return 0;end
  function n:GetCleanName() return tostring(self.kind);end
  function n:AddToHateList() end
  if pid then self.points[pid].npc=n;end
  if emit then self:dispatch(Event.spawn,n);end
  return n;
 end
 for id,row in pairs(fixture) do
  local p={valid=true,id=id,kind=row[2][1]};w.points[id]=p;
  function p:RespawnTimer() return 1080;end
  function p:GetNPC() return self.npc and self.npc.valid and self.npc or {valid=false};end
  function p:Repop() if self.npc then self.npc.valid=false;end;w:new_npc(self.kind,self.id,true);end
 end
 function w:load(unload)
  self.registry={};self.scripts={};
  if unload then for _,n in ipairs(self.npcs) do n.valid=false;end;end
  local elist={};
  function elist:GetSpawnByID(id) return w.points[id] or {valid=false};end
  function elist:GetNPCByNPCTypeID(id) return w:find(id);end
  function elist:IsMobSpawnedByNpcTypeID(id) return w:find(id).valid;end
  function elist:GetClientByID() return {valid=false};end
  local eq={
   get_zone_guild_id=function() return w.guild;end,
   get_rule=function() return w.controls==false and "false" or "true";end,
   update_spawn_timer=function(id,ms) w.points[id].normal_timer=ms;w.timer_updates=(w.timer_updates or 0)+1;end,
   guild_one_raid_window_open=function() return true;end,
   get_entity_list=function() return elist;end,
   get_data=function(k) w.reads=w.reads+1;if k=="guild_instance_respawns:"..w.guild then return w.restored and "1" or "0";end;return w.buckets[k] or "";end,
   set_data=function(k,v) w.writes=w.writes+1;w.buckets[k]=v;end,
   set_timer=function(k,v) w.timers[k]=v;end,stop_timer=function(k) w.timers[k]=nil;end,
   debug=function() end,
   ChooseRandom=function(...) local args={...};w.roll=w.roll+1;return args[(w.roll-1)%#args+1];end,
   register_npc_event=function(owner,event,id,cb) w.registry[id..":"..event]=cb;end,
   signal=function(id,value)
    if id==215419 then w.scripts.POACastellanController.event_signal({signal=value});end
   end,
   depop_with_timer=function(id) w.consumes=w.consumes+1;local n=w:find(id);n.valid=false;end,
   unique_spawn=function(id) local n=w:find(id);if n.valid then return n;end;return w:new_npc(id,nil,true);end,
   spawn2=function(id) return w:new_npc(id,nil,true);end
  };
  local function env()
   local e={eq=eq,Event=Event,os={time=function() return w.now;end}};setmetatable(e,{__index=_G});
   e.require=function(name) return setfenv(assert(loadfile(root.."/lua_modules/"..name..".lua")),e)();end
   return e;
  end
  for _,name in ipairs({"A_Castellan_of_Air","POACastellanController","#Constable_Alranderisan","#Constable_Belecohen","#Constable_Ferabalen","#Chamberlain_Escalardian"}) do
   local e=env();setfenv(assert(loadfile(root.."/poair/"..name..".lua")),e)();self.scripts[name]=e;
  end
  local e=env();setfenv(assert(loadfile(root.."/poair/encounters/TravelTrash.lua")),e)();self.env=e;e.event_encounter_load({});
  if unload or #self.npcs==0 then for id,p in pairs(self.points) do self:new_npc(p.kind,id,true);end;end
 end
 function w:pulse() self:dispatch(Event.timer,self:find(215419),{timer="air_travel_trash"});end
 function w:kill(n) assert(n.valid and n.hp>0);n.hp=0;self:dispatch(Event.death_complete,n);end
 function w:timer(name) self:dispatch(Event.timer,self:find(215419),{timer=name});end
 function w:tracker(group) return self.env.require("air_trash_retention").new(group);end
 w:load(false);return w;
end
-- Audit every spawn point, not just selected NPC type IDs.
local covered={};local extra_count=0;
for group,ids in pairs(map.groups) do
 for _,id in ipairs(ids) do check(fixture[id]~=nil,"allowlisted point exists");check(not covered[id],"one timer group per point");covered[id]=group;end
end
for id,group in pairs(map.extra) do extra_count=extra_count+1;check(covered[id]==group,"extra point shares its declared group");end
check(extra_count==219,"all 204 travel points plus 15 Castellans are covered");
local xegony=read("poair/encounters/Xegony.lua"):match("local SPAWNIDS = {(.-)}");
for id in xegony:gmatch("%d+") do check(not covered[tonumber(id)],"Xegony defender/add point excluded");end
for id,row in pairs(fixture) do
 for _,npc in ipairs(row[2]) do
  if npc==215056 or npc==215375 or npc==215024 or npc==215003 or npc==215034 or npc==215011 or npc==215054 or npc==215402 then
   check(not covered[id],"boss or scripted erratic point excluded");
  end
 end
end
-- Every added travel spawn participates, and reload/normal respawn cannot undo it.
do
 local w=world();local first=w.now;
 for id,group in pairs(map.extra) do
  w:kill(w.points[id].npc);local t=w:tracker(group);
  check(t:Held(id),"qualifying travel death retained");
  w.points[id]:Repop();check(not w.points[id].npc.valid,"natural respawn suppressed");
 end
 for group in pairs(map.groups) do
  local t=w:tracker(group);check(t.deadline<=first+64800,"all groups respect 18-hour cap");
 end
 w.now=w.now+120;w:load(true);w:pulse();
 for id in pairs(map.extra) do check(not w.points[id]:GetNPC().valid,"all cleared travel stays absent after full zone load");end
 check(w:find(215056).valid and w:find(215375).valid,"Xegony and Sigismond remain present");
 check(w.consumes==0,"travel clear never consumes a boss loot marker");
end
-- Additive time, group isolation, duplicate rejection, expiry and corpse safety.
do
 local w=world();local ids=map.groups.lower_west;local first=w.now;
 w:kill(w.points[ids[1]].npc);local t=w:tracker("lower_west");check(t.deadline==first+6300,"first kill earns 1h45m");
 local dead=w.points[ids[1]].npc;w:pulse();check(dead.valid,"corpse is not depopped");
 w.now=w.now+300;w:kill(w.points[ids[2]].npc);t=w:tracker("lower_west");check(t.deadline==first+9000,"second kill adds 45m, not now plus 45m");
 local deadline=t.deadline;w:dispatch(Event.death_complete,dead);check(w:tracker("lower_west").deadline==deadline,"duplicate death grants no time");
 check(w:tracker("upper_west").deadline==0,"other island not extended");
 w.points[ids[1]]:Repop();w.now=deadline-1;w:pulse();check(not w.points[ids[1]]:GetNPC().valid,"protected to exact boundary");
 w.now=deadline;w:pulse();check(w.points[ids[1]]:GetNPC().valid,"expired suppressed point respawns");
 local n=w.points[ids[1]].npc;w:pulse();check(w.points[ids[1]].npc==n,"expiry repop occurs once");
 w:kill(n);check(w:tracker("lower_west").deadline==w.now+6300,"new clear starts after expiry");
 local other=world(73);other.buckets=w.buckets;check(other:tracker("lower_west").deadline==0,"guilds isolated");
end
do
 local w=world();local ids=map.groups.lower_west;
 w:kill(w.points[ids[1]].npc);w.points[ids[1]]:Repop();
 w.now=w:tracker("lower_west").deadline;
 w:kill(w.points[ids[2]].npc);
 check(w.points[ids[1]]:GetNPC().valid,"new kill releases old expired suppression before replacing saved deaths");
 check(w:tracker("lower_west").deadline==w.now+6300,"late kill begins a fresh capped clear");
end
-- Ring-side extras use the same timer bucket without counting as ring kills.
do
 local w=world();local t=w:tracker("wind");local first=w.now;
 t:Record(map.groups.wind[1]);
 for id,group in pairs(map.extra) do if group=="wind" then w:kill(w.points[id].npc);break;end;end
 t:Refresh();check(t.deadline==first+9000,"ring and nearby travel share additive deadline");
end
-- Castellan milestones and loot markers survive trash retention/reloads.
do
 local w=world();local ids=map.groups.castellan;
 for i=1,5 do w:kill(w.points[ids[i]].npc);end
 check(w:find(215383).valid,"fifth Castellan earns first constable");
 w:kill(w:find(215383));
 local deadline=w:tracker("castellan").deadline;
 w:timer("castellan_repop");check(w.points[ids[1]].npc.hp==0,"old 18m timer cannot repop retained Castellan");
 w:load(true);w:pulse();w:timer("castellan_restore");
 check(not w:find(215383).valid,"defeated constable never recreated on reload");
 for i=6,10 do w:kill(w.points[ids[i]].npc);end
 check(w:find(215384).valid,"partial clear resumes at second constable");
 w:load(true);w:pulse();w:timer("castellan_restore");
 check(w:find(215384).valid,"earned undefeated constable restored");w:kill(w:find(215384));
 for i=11,15 do w:kill(w.points[ids[i]].npc);end
 check(w:find(215385).valid,"fifteenth Castellan earns third constable");w:kill(w:find(215385));
 check(w:find(215411).valid,"three constables earn Chamberlain");
 check(w.consumes==0,"trash and constables leave armor marker unchanged");
 w:load(true);w:pulse();w:timer("castellan_restore");check(w:find(215411).valid,"undefeated final NPC survives unload");
 w:kill(w:find(215411));check(w.consumes==1,"only actual boss death consumes original marker");
 w:load(true);w:pulse();w:timer("castellan_restore");check(not w:find(215411).valid,"defeated Chamberlain never restored");
end
for _,guild in ipairs({0,1}) do
 local w=world(guild);local before=w.writes;local id=map.groups.castellan[1];w:kill(w.points[id].npc);
 check(w.reads==0 and w.writes==before,"public/Guild 1 perform no trash persistence writes");
 w.points[id]:Repop();check(w.points[id].npc.valid,"public/Guild 1 trash unaffected");
end
-- Restored mode never starts a retention cycle, including all travel/Castellan points.
do
 local w=world();w.restored=true;w:load(false);
 for id,group in pairs(map.extra) do
  w:kill(w.points[id].npc);local t=w:tracker(group);
  check(not t.active and not t:Held(id) and t.deadline==0,"restored travel has no extended hold");
  w.points[id]:Repop();check(w.points[id].npc.valid,"restored travel uses native respawn");
 end
 check((w.timer_updates or 0)==0,"normal kills do not rewrite native timers");
end
-- Restore releases only held dead trash once and survives a second mode change/unload.
do
 local w=world();local ids=map.groups.lower_west;local corpse=w.points[ids[1]].npc;
 w:kill(corpse);w:kill(w.points[ids[2]].npc);
 w.now=w.now+60;local reset=w.now;
 w.restored=true;w.env.require("air_trash_retention").restore_guild(w.guild);
 w:pulse();local updates=w.timer_updates;
 check(updates==2,"only previously held dead spawns get normal countdowns");
 check(w.points[ids[1]].normal_timer==1080000,"normal interval begins at restoration");
 check(corpse.valid and corpse.hp==0,"restoration preserves corpses");
 check(not w:tracker("lower_west"):Held(ids[1]),"restoration removes saved hold");
 w:pulse();w:load(false);w:pulse();check(w.timer_updates==updates,"pulse/reload do not restart restored timers");
 w.restored=false;w:pulse();check(w:tracker("lower_west").deadline==0,"slowing again cannot revive old clear");
 w:kill(w.points[ids[3]].npc);check(w:tracker("lower_west").deadline==w.now+6300,"new slowed death starts a fresh clear");
 -- No Air pulse between restore and slow: persistent revision still invalidates it.
 w.restored=true;w.env.require("air_trash_retention").restore_guild(w.guild);w.restored=false;
 w.now=w.now+120;w:load(false);w:pulse();
 check(w:tracker("lower_west").deadline==0,"offline restore/slow invalidates old saved clear");
 check(w.points[ids[3]].normal_timer==960000,"offline time is deducted from normal countdown");
 check(w:find(215056).valid and w:find(215375).valid,"mode changes leave bosses present");
 check(w.consumes==0,"mode changes never consume loot markers");
end
-- Legacy saves and missing points are released safely, even without a Timekeeper revision.
do
 local w=world();local id=map.groups.upper_west[1];local key="poair-ring-v1-upper_west-"..w.guild.."-trash";
 w:kill(w.points[id].npc);w.buckets[key]="1|"..w.now.."|"..(w.now+64800).."|"..id;
 w.restored=true;w.points[id].valid=false;w:pulse();check((w.timer_updates or 0)==0,"missing spawn cleanup remains pending");
 w.points[id].valid=true;w.now=w.now+60;w:pulse();
 check(w.points[id].normal_timer==1020000,"pending cleanup retains its original restoration timestamp");
 local writes=w.timer_updates;w:pulse();check(w.timer_updates==writes,"legacy hold cleared once");
 w.controls=false;check(w:tracker("upper_west").active,"admin-disabled controls match forced slowed server mode");
end
-- Timekeeper hook runs only after a successful restore, never a rejected change.
do
 local w=world();local revision="poair-trash-reset-"..w.guild;local succeed=false;
 local client={GuildID=function() return w.guild;end,GuildRank=function() return 2;end,Message=function() end,
 GetGuildInstanceRespawnsEnabled=function() return false;end,SetGuildInstanceRespawnsEnabled=function() return succeed;end};
 local e=setmetatable({}, {__index=w.env});
 setfenv(assert(loadfile(root.."/potranquility/Timekeeper_of_Druzzil_Ro.lua")),e)();
 local message={findi=function(_,v) return v=="restore";end};
 e.event_say({message=message,other=client});check(not w.buckets[revision],"rejected restore leaves Air state intact");
 succeed=true;e.event_say({message=message,other=client});check(w.buckets[revision]=="1|"..w.now,"successful restore records revision");
 e.event_say({message=message,other=client});check(w.buckets[revision]=="2|"..w.now,"same-second changes have distinct revisions");
end
-- Restoring during Castellan progression leaves living named NPCs alone.
do
 local w=world();local ids=map.groups.castellan;
 for i=1,5 do w:kill(w.points[ids[i]].npc);end
 local constable=w:find(215383);check(constable.valid,"constable baseline before mode switch");
 w.restored=true;w.env.require("air_trash_retention").restore_guild(w.guild);w:timer("castellan_mode");w:pulse();
 check(w.timers.castellan_repop==1080000,"Castellan extended timer replaced with normal 18 minutes");
 check(w:find(215383)==constable and constable.valid,"restoring does not replace or remove earned constable");
 local writes=w.timer_updates;w:timer("castellan_mode");check(w.timer_updates==writes,"mode polling does not restart countdown");
 check(w.consumes==0,"Castellan restore does not touch armor loot marker");
end
print("PASS: "..checks.." travel trash and Castellan checks");
