-- lua tests/karana_claims_test.lua /path/to/Quests
-- Exercises the actual reward script with isolated clients/qglobals.
local root=arg[1] or ".";
local f=assert(io.open(root.."/bothunder/Karana.lua"));local source=f:read("*a");f:close();
local checks=0;
local function check(ok,message)assert(ok,message);checks=checks+1;end
local function world()
 local w={clients={},writes={},now=nil};local invalid={valid=false};local env;
 function w:client(id,flags,raid)
  local c={valid=true,id=id,q=flags or {},raid=raid or 100};self.clients[id]=c;
  function c:IsClient()return true;end;function c:CastToClient()return self;end;
  function c:GetID()return self.id;end;function c:GetName()return "Client"..self.id;end;
  function c:GetRaid()return {valid=true,GetID=function()return self.raid;end};end;
  function c:GetGroup()return invalid;end;function c:Message()end;
  return c;
 end
 local npc={Say=function()end};local eqmock={
  get_entity_list=function()return {GetClientByID=function(_,id)return w.clients[id]or invalid;end};end,
  get_qglobals=function(c)return c.q;end,
  set_global=function(k,v)w.now.q[k]=v;w.writes[#w.writes+1]={character=w.now.id,key=k};end,
  delete_global=function(k)w.now.q[k]=nil;end,set_timer=function()end,debug=function()end};
 -- Isolate reward accounting from the travel-window hook; the actual helper
 -- is covered with Karana and Askr by flagging_travel_test.lua.
 env=setmetatable({eq=eqmock,require=function(name)
  assert(name=="flagging_travel","unexpected module "..name);
  return {OpenWindow=function()end};
 end},{__index=_G});local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();env.event_spawn({self=npc});
 local owner=w:client(1);env.event_signal({self=npc,signal=owner.id});
 function w:claim(c)
  self.now=c;env.event_say({self=npc,other=c,message={findi=function(_,phrase)return phrase=="follow the path of the Fallen";end}});
 end
 function w:remaining(first,count)
  for id=first,first+count-1 do local c=self:client(id,{karana="3"});self:claim(c);check(c.q.karana=="4","eligible character "..id.." denied a remaining claim");end
 end
 return w;
end
local w=world();local c=w.clients[1];for i=1,100 do w:claim(c);end
check(c.q.cl_karana=="1" and #w.writes==1,"pending repeated requests must grant only once");
w:remaining(2,71);local extra=w:client(73,{karana="3"});w:claim(extra);check(extra.q.karana=="3","72-claim limit must remain enforced");
w=world();c=w.clients[1];c.q.cl_karana="1";for i=1,100 do w:claim(c);end
check(#w.writes==0,"pre-existing checklist must consume no claim");w:remaining(2,72);
w=world();c=w.clients[1];c.q={karana="3",cl_karana="1"};w:claim(c);for i=1,100 do w:claim(c);end
check(c.q.karana=="4" and not c.q.cl_karana and #w.writes==1,"ready prerequisite must still upgrade and clear pending flag once");w:remaining(2,71);
w=world();c=w.clients[1];c.q={zebuxoruk="1"};w:claim(c);check(#w.writes==0,"completed progression must not get a new checklist");
c.q={karana="4"};w:claim(c);check(#w.writes==0,"completed Karana flag must not be awarded again");
local outsider=w:client(2,{karana="3"},200);w:claim(outsider);check(outsider.q.karana=="3","unrelated raid must remain ineligible");
print(checks.." Karana reward and duplicate-claim checks passed");
