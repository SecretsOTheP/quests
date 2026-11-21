-- Executes Grimror and the real items.lua turn-in helper.
local checks=0;
local function check(ok,text) assert(ok,text);checks=checks+1;end
local function world(enabled)
 local w={keys={},flags={},rewards={},returned={},loot={},messages={},writes=0};
 local npc,client={},{};
 function npc:GetCleanName() return "Grimror";end
 function npc:Say(text) w.messages[#w.messages+1]=text;end
 npc.Emote=npc.Say;
 function npc:GetQuestLoot(id) return w.loot[id] and w.loot[id]>0 or false;end
 function npc:AddQuestLoot(id) w.loot[id]=(w.loot[id] or 0)+1;end
 function npc:DeleteQuestLoot(...) for _,id in ipairs({...}) do if id~=0 then w.loot[id]=w.loot[id]-1;end;end;end
 function npc:HasRequiredQuestLoot(...) local counts={};for _,id in ipairs({...})do if id~=0 then counts[id]=(counts[id] or 0)+1;end;end;for id,n in pairs(counts)do if (w.loot[id] or 0)<n then return false;end;end;return true;end
 function npc:Charmed() return false;end
 function npc:CanTalk() return true;end
 function client:GetCleanName() return "Test";end
 function client:KeyRingCheck(id) return w.keys[id] or false;end
 function client:KeyRingAdd(id) w.keys[id]=true;w.writes=w.writes+1;end
 function client:HasZoneFlag(id) return w.flags[id] or false;end
 function client:SetZoneFlag(id) w.flags[id]=true;w.writes=w.writes+1;end
 function client:QuestReward(_,reward) w.rewards[#w.rewards+1]=reward;end
 function client:SummonItem(id) w.returned[#w.returned+1]=id;end
 local env=setmetatable({eq={get_data=function()return enabled and "1" or "0";end,debug=function()end,
 say_link=function(keyword,_,label)return "["..label..":"..keyword.."]";end,
 set_global=function()error("alternate entrance must not grant progression globals");end}}, {__index=_G});
 env.require=function(name)return setfenv(assert(loadfile("lua_modules/"..name..".lua")),env)();end
 setfenv(assert(loadfile("podisease/Grimror_Plaguebringer.lua")),env)();
 function w:hand(ids)
  local trade={platinum=0,gold=0,silver=0,copper=0};
  for i,id in ipairs(ids)do trade["item"..i]={valid=true,GetID=function()return id;end,GetCharges=function()return 1;end};end
  env.event_trade({self=npc,other=client,trade=trade});
 end
 function w:say(text)
  env.event_say({self=npc,other=client,message={findi=function(_,word)return text:lower():find(word:lower(),1,true);end}});
 end
 return w;
end
local w=world(true);w:say("hail");check(w.messages[1]:find("[stuffs:stuff]",1,true),"enabled hail exposes next dialogue step");
for _,phrase in ipairs({"stuff","big plan","help Grimror","dem tings"})do local n=#w.messages;w:say(phrase);check(#w.messages>n,"dialogue path responds: "..phrase);end
w:hand({9290,9291,9292,9293});check(#w.rewards==1 and w.rewards[1].itemid==9294,"four components still award bracer");
check(w.keys[9294] and w.flags[200] and w.writes==2,"completion immediately registers alternate Crypt access");
check(not w.flags[207] and not w.flags[219],"no unrelated zones granted");
local writes=w.writes;w:hand({9290,9291,9292,9293});check(w.writes==writes,"repeated completion does not duplicate access writes");
for mask=0,14 do
 local w=world(true);local ids={};for i=0,3 do if math.floor(mask/2^i)%2==1 then ids[#ids+1]=9290+i;end;end
 w:hand(ids);check(#w.rewards==0 and w.writes==0,"incomplete hand-in never grants access");
end
w=world(false);w:say("hail");check(w.messages[1]:find("come back",1,true),"disabled alternate quest remains unavailable");
w:hand({9290,9291,9292,9293});check(w.writes==0 and #w.rewards==0 and #w.returned==4,"disabled quest returns all components");
w=world(true);w:hand({1234});check(#w.returned==1 and w.returned[1]==1234 and w.writes==0,"unrelated item returned");
print("PASS: "..checks.." Grimror dialogue, real hand-in and access checks");
