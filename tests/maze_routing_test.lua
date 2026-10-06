-- From the repository root: lua5.1 tests/maze_routing_test.lua
-- Actual maze script with simulated clients, raids and delayed teleports. No game server/database access.
local file=assert(io.open(arg[1]or'ponightmare/encounters/Maze.lua'));local source=file:read('*a');file:close()
function string.findi(self,needle)return string.find(string.lower(self),string.lower(needle),1,true)end
local function world(count,delay)
 local w={now=100000,clients={},pending={},npcs={},moves={},messages={},logs={},timers={},delay=delay}
 local raids={}
 local R={valid=true}
 function R:GetID()return self.id end
 function R:GetGroup(name)for i,c in ipairs(w.clients)do if c.name==name and c.raid==self.id then return c.group end end;return 4294967295 end
 function R:GetMember(index)local n=0;for _,c in ipairs(w.clients)do if c.raid==self.id then if n==index then return c end;n=n+1 end end end
 raids[101]=setmetatable({valid=true,id=101},{__index=R});raids[202]=setmetatable({valid=true,id=202},{__index=R})
 local C={}
 function C:GetName()return self.name end
 function C:CharacterID()return self.cid end
 function C:GetRaid()return raids[self.raid]or{valid=false}end
 function C:GetGroup()
  local client=self;local list={};for _,m in ipairs(w.clients)do if m.raid==0 and m.group==client.group then list[#list+1]=m end end
  return{valid=#list>0,GroupCount=function()return#list end,GetMember=function(_,i)local m=list[i+1]or{valid=false};return{CastToClient=function()return m end}end}
 end
 function C:GetX()return self.x end
 function C:GetY()return self.y end
 function C:GetZ()return self.z end
 function C:GetGM()return self.gm or false end
 function C:GetPet()return self.pet or{valid=false}end
 function C:Message(color,text)w.messages[#w.messages+1]={name=self.name,gm=self:GetGM(),color=color,text=text}end
 function C:CalculateDistance(x,y,z)return math.sqrt((self.x-x)^2+(self.y-y)^2+(self.z-z)^2)end
 function C:MovePC(zone,x,y,z,h)
  self.destination=y;w.moves[#w.moves+1]={name=self.name,y=y}
  if w.delay then w.pending[#w.pending+1]={client=self,x=x,y=y,z=z}else self.x,self.y,self.z=x,y,z end
 end
 function C:QuestReward()end
 for i=1,count or 24 do w.clients[i]=setmetatable({valid=true,cid=1000+i,name='P'..i,raid=101,group=math.floor((i-1)/6),x=1668,y=282,z=213},{__index=C})end
 local N={}
 function N:GetID()return self.id end
 function N:GetNPCTypeID()return self.t end
 function N:GetSpawnPointID()return self.spawn end
 function N:GetHP()return 100 end
 function N:GetX()return self.x or -4417 end
 function N:GetY()return self.y or 5604 end
 function N:GetZ()return self.z or 5 end
 function N:IsCorpse()return false end
 function N:GetEntityVariable(k)return self.vars[k]or''end
 function N:SetEntityVariable(k,v)self.vars[k]=v end
 function N:Emote()end
 function N:Say()end
 function N:CastToNPC()return self end
 function N:SetNoQuestPause()end
 function N:SetSpecialAbility()end
 function N:SetCastRateDetrimental()end
 function N:SpellFinished()end
 function N:AssignWaypoints(grid)self.grid=grid end
 function N:Depop()self.valid=false end
 local ids={346002,346001,346000};for i,id in ipairs(ids)do w.npcs[i]=setmetatable({valid=true,id=200+i,t=204486,spawn=id,vars={}},{__index=N})end
 w.governor=setmetatable({valid=true,id=300,t=204458,spawn=0,vars={}},{__index=N})
 local el={RemoveFromHateLists=function()end,GetMobByNpcTypeID=function()return w.governor end}
 function el:GetNPCList()local i=0;return{entries=function()i=i+1;return w.npcs[i]end}end
 function el:GetClientList()local i=0;return{entries=function()i=i+1;return w.clients[i]end}end
 function el:GetCorpseList()return{entries=function()return nil end}end
 function el:GetNPCByID(id)for _,n in ipairs(w.npcs)do if n.id==id then return n end end;return{valid=false}end
 local eq={get_qglobals=function()return{thelin='1'}end,get_entity_list=function()return el end,
  spawn2=function(t,grid,a,x,y,z,h)local n=setmetatable({valid=true,id=400+#w.npcs,t=t,spawn=0,x=x,y=y,z=z,vars={}},{__index=N});w.npcs[#w.npcs+1]=n;return n end,
  set_timer=function(n,ms,owner)w.timers[(owner and owner.id or 0)..':'..n]=ms end,
  stop_timer=function()end,debug=function(text)w.logs[#w.logs+1]=text end,get_zone_guild_id=function()return 24 end,register_npc_event=function()end}
 local env=setmetatable({eq=eq,os={time=function()return w.now end},Event={timer=1,waypoint_arrive=2,trade=3,death_complete=4,say=5,spawn=6,combat=7}},{__index=_G});w.env=env
 function w:load()local f=assert(loadstring(source));setfenv(f,env);f();env.event_encounter_load({})end
 function w:ready(group)self:readyClient(self.clients[(group-1)*6+1])end
 function w:readyClient(client)env.ThelinOutsideSayEvent({self=self.npcs[1],other=client,message='ready'})end
 function w:inside(room,index)env.ThelinInsideSayEvent({self=self.npcs[room],other=self.clients[index or 1],message='ready'})end
 function w:flush()for _,p in ipairs(self.pending)do p.client.x,p.client.y,p.client.z=p.x,p.y,p.z end;self.pending={}end
 function w:check()env.GovernorTimerEvent({self=self.governor,timer='check'})end
 function w:room(i)
  local f={};for v in(self.npcs[i]:GetEntityVariable('maze_routing_v1')..'|'):gmatch('(.-)|')do f[#f+1]=v end
  local seats=0;for _ in(f[5]or''):gmatch('%d+:%d+:[01]')do seats=seats+1 end
  return{rid=tonumber(f[2])or 0,state=tonumber(f[3])or 0,seats=seats,deadline=tonumber(f[4])or 0}
 end
 w:load();return w
end
local tests={};local function test(name,f)tests[#tests+1]={name,f}end
local function maze1(w,n)for i=1,n or 24 do assert(w.clients[i].destination==5642,'client '..i..' split')end end
test('24 raid members in four groups all enter the same maze',function()
 local w=world();for g=1,4 do w:ready(g)end;maze1(w);assert(w:room(1).seats==24 and w:room(1).rid==101)
end)
test('duplicate ready calls before packet completion consume no extra seats or moves',function()
 local w=world(24,true);w:ready(1);w:ready(1);w:ready(1);assert(#w.moves==6 and w:room(1).seats==6)
 w:flush();for g=2,4 do w:ready(g);w:flush()end;maze1(w);assert(w:room(1).seats==24)
end)
test('first group starting early cannot redirect the other 18 raid members',function()
 local w=world();w:ready(1);w:inside(1);for g=2,4 do w:ready(g)end
 assert(w:room(1).state==2 and #w.moves==6);for i=7,24 do assert(not w.clients[i].destination)end
end)
test('group leaders cannot start while admitted companions are still arriving',function()
 local w=world(24,true);w:ready(1);local p=w.pending[1];p.client.x,p.client.y,p.client.z=p.x,p.y,p.z
 w:inside(1);assert(w:room(1).state==1);w:flush();w:inside(1);assert(w:room(1).state==2)
end)
test('a governor check before arrival retains the raid reservation',function()
 local w=world(24,true);w:ready(1);w.now=w.now+10;w:check();assert(w:room(1).state==1 and w:room(1).seats==6)
 w:flush();for g=2,4 do w:ready(g);w:flush()end;maze1(w)
end)
test('uncompleted requests expire without permanently reserving an empty maze',function()
 local w=world(24,true);w:ready(1);w.pending={};w.now=w.now+61;w:check();assert(w:room(1).state==0 and w:room(1).seats==0)
 w:ready(2);assert(w.clients[7].destination==5642)
end)
test('reload restores reservations while members are in transit',function()
 local w=world(24,true);w:ready(1);w:load();w:ready(1);assert(#w.moves==6 and w:room(1).seats==6);w:check();w:flush()
 for g=2,4 do w:ready(g);w:flush()end;maze1(w)
end)
test('reload after first group arrives does not send later groups to another maze',function()
 local w=world();w:ready(1);w:load();for g=2,4 do w:ready(g)end;maze1(w)
end)
test('reload preserves sealed state and denies late entry',function()
 local w=world();w:ready(1);w:inside(1);w:load();w:ready(2);assert(w:room(1).state==2 and #w.moves==6)
end)
test('48 and 72 member raids can still fill separate 24-player mazes',function()
 for _,count in ipairs({48,72})do
  local w=world(count);for g=1,count/6 do w:ready(g);if g%4==0 then local room=g/4;w:inside(room,(room-1)*24+1)end end
  for i=1,count do local expected=5642-math.floor((i-1)/24)*1000;assert(w.clients[i].destination==expected)end
 end
end)
test('separate raids do not share ownership',function()
 local w=world();for i=7,24 do w.clients[i].raid=202 end;w:ready(1);w:ready(2)
 assert(w.clients[1].destination==5642 and w.clients[7].destination==4642)
end)
test('non-raid groups may share a staging maze without double counting',function()
 local w=world();for _,c in ipairs(w.clients)do c.raid=0 end;for g=1,4 do w:ready(g)end;maze1(w);assert(w:room(1).seats==24)
end)
test('ungrouped raid members port individually rather than all ungrouped members',function()
 local w=world();for _,c in ipairs(w.clients)do c.group=4294967295 end;w:readyClient(w.clients[1]);assert(#w.moves==1 and w:room(1).seats==1)
end)
test('re-entry before sealing does not accumulate old seats',function()
 local w=world();for g=1,4 do w:ready(g)end
 for i=1,6 do w.clients[i].x,w.clients[i].y,w.clients[i].z=1668,282,213 end
 w:ready(1);maze1(w);assert(w:room(1).seats==24)
end)
test('players cannot start a room where they were not admitted',function()
 local w=world();w:ready(1);w.clients[7].x,w.clients[7].y,w.clients[7].z=-4466,5642,5;w:inside(1,7);assert(w:room(1).state==1)
end)
test('missing inside Thelin prevents porting into an empty broken maze',function()
 local w=world();w.npcs[1].valid=false;w:ready(1);assert(w.clients[1].destination==4642)
end)
test('five-minute staging deadline survives reload without resetting',function()
 local w=world();w:ready(1);local deadline=w:room(1).deadline;w.now=w.now+200;w:load();w:check();assert(w:room(1).deadline==deadline and w:room(1).state==1)
 w.now=w.now+101;w:check();assert(w:room(1).state==5)
end)
test('an admitted GM can test alone without governor clearing the room',function()
 local w=world(1);w.clients[1].gm=true;w:readyClient(w.clients[1]);w:check();assert(w:room(1).state==1);w:inside(1);assert(w:room(1).state==2)
end)
test('ordinary players never receive technical routing diagnostics',function()
 local w=world();for g=1,4 do w:ready(g)end;assert(#w.logs>0)
 for _,m in ipairs(w.messages)do assert(not m.text:find('[Maze ',1,true)or m.gm)end
end)
test('legacy occupied rooms retain the raid and refuse to redirect late groups',function()
 local w=world();for i=1,6 do w.clients[i].x,w.clients[i].y,w.clients[i].z=-4466,5642,5 end
 w:ready(2);assert(w:room(1).state==5 and w:room(1).rid==101 and #w.moves==0)
 w:load();w:ready(3);assert(#w.moves==0)
end)
test('characters already reserved in conflicting rooms cannot be combined and split again',function()
 local w=world(24,true);for i=7,12 do w.clients[i].raid=202 end;w:ready(1);w:ready(2)
 for i=1,12 do w.clients[i].raid=101;w.clients[i].group=9 end
 for _,i in ipairs({1,2,3,7,8,9})do w.clients[i].group=0 end
 local before=#w.moves;w:ready(1);assert(#w.moves==before)
end)
test('red RP cues reach only the participants of the matching maze',function()
 local w=world();for i=7,12 do w.clients[i].raid=202 end;w:ready(1);w:ready(2);w:inside(1)
 local count=0;for _,m in ipairs(w.messages)do if m.text:find('The hedges twist behind you',1,true)then assert(m.color==13 and tonumber(m.name:sub(2))<=6);count=count+1 end end;assert(count==6)
end)
test('dagger and final-guardian milestones emit red RP and preserve spawns',function()
 local w=world(6);w:ready(1);w:inside(1);w.env.ThelinWaypointEvent({self=w.npcs[1],wp=26});assert(#w.npcs==6)
 w.env.ThelinWaypointEvent({self=w.npcs[1],wp=106});assert(w:room(1).state==3 and w.npcs[7].t==204464)
 for _,phrase in ipairs({'Thelin recovers the dagger hilt','The last guardian'})do
  local count=0;for _,m in ipairs(w.messages)do if m.text:find(phrase,1,true)then assert(m.color==13);count=count+1 end end;assert(count==6,phrase)
 end
end)
test('success and Thelin death have red cues without exposing technical logs',function()
 local w=world(6);w:ready(1);w:inside(1);w.env.ThelinTimerEvent({self=w.npcs[1],timer='talk3'})
 local success=0;for _,m in ipairs(w.messages)do if m.text:find('nightmare begins to loosen',1,true)then assert(m.color==13);success=success+1 end end;assert(success==6)
 local f=world(6);f:ready(1);f:inside(1);f.env.ThelinDeathEvent({self=f.npcs[1]})
 local failure=0;for _,m in ipairs(f.messages)do if m.text:find('Thelin falls',1,true)then assert(m.color==13);failure=failure+1 end end;assert(failure==6)
 for _,m in ipairs(f.messages)do assert(not m.text:find('[Maze ',1,true)or m.gm)end
end)
local failures=0;for _,t in ipairs(tests)do local ok,err=pcall(t[2]);print((ok and'PASS 'or'FAIL ')..t[1]..(ok and''or': '..tostring(err)));if not ok then failures=failures+1 end end
assert(failures==0,failures..' maze checks failed');print(#tests..' maze routing checks passed')
