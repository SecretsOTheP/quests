-- Run: lua5.1 tests/pok_spell_turnins.lua .
local setup=[====[
store={};slots={};messages={};rewards={};deliveries={};choice=1;capacity=8;fail_delivery=false;character=4000000000;missing={}
write_count=0;fail_write=0;throw_write=0;read_count=0;fail_read=0;crash_before=false;crash_after=false;reenter=false
eq={get_data=function(k) return store[k] or '' end,
 set_data=function(k,v,expires)
  assert(expires==nil);write_count=write_count+1
  if write_count==throw_write then error('simulated database exception') end
  if write_count~=fail_write then store[k]=v end
 end,
 ChooseRandom=function(...) return select(choice,...) end,
 debug=function() end,get_zone_short_name=function() return 'poknowledge' end}
eq.get_data=function(k) read_count=read_count+1;if read_count==fail_read then return '' end;return store[k] or '' end
string.findi=function(s,p) return string.find(string.lower(s),string.lower(p)) end
local nop=function() end
function ItemInst(id,qty)
 return {valid=not missing[id], GetID=function() return id end,GetCharges=function() return qty end,
 GetName=function() return 'item '..id end,IsStackable=function() return true end,
 GetItem=function() return {Size=function() return 1 end} end}
end
inventory={GetItem=function(self,slot) return slots[slot] or {valid=false} end,
 FindFreeSlot=function(self,bag,cursor,size)
  assert(not bag and not cursor)
  for i=22,21+capacity do if not slots[i] then return i end end
  return -1
 end}
client={CharacterID=function() return character end,GetCleanName=function() return 'Audit' end,
 GetInventory=function() return inventory end,AddMoneyToPP=nop,
 Message=function(self,color,msg) table.insert(messages,msg) end,
 SummonItem=function(self,id,qty,slot,forced)
  assert(slot>=22 and slot<=29,'unsafe delivery slot');assert(not slots[slot],'overwriting item')
  if crash_before then error('simulated interruption before inventory delivery') end
  if reenter then require('pop_spell_turnins').Claim({other=client}) end
  if not fail_delivery then slots[slot]=ItemInst(id,qty);table.insert(deliveries,{id,qty}) end
  if crash_after then error('simulated interruption after inventory delivery') end
 end,
 QuestReward=function(self,n,c,s,g,p,id) assert(id==0,'duplicate native reward');table.insert(rewards,id) end}
npc={Say=nop,Emote=nop,GetCleanName=function() return 'Elementalist Somat' end,
 GetQuestLoot=function() return false end,CanTalk=function() return true end,Charmed=function() return false end}
function event_with(items)
 local t={copper=0,silver=0,gold=0,platinum=0}
 for i,v in ipairs(items) do t['item'..i]=ItemInst(v[1],v[2]) end
 return {self=npc,other=client,trade=t,message='Hail'}
end
function raw_pending() return store['pop_spell_pending:'..character] or '' end
function pending() return (raw_pending():gsub('^P|','')) end
]====]
local names={"Cavalier_Waut.lua","Channeler_Olaemos.lua","Elementalist_Somat.lua","Heretic_Drahur.lua","Illusionist_Jerup.lua","Minstrel_Eoweril.lua","Mystic_Abomin.lua","Pathfinder_Viliken.lua","Primalist_Saosith.lua","Reaver_Nydlil.lua","Vicar_Ceraen.lua","Wanderer_Astobin.lua"}

local root=assert(arg[1])
package.path=root..'/lua_modules/?.lua;'..package.path
local count=0
local function boot(name)
 assert(loadstring(setup))()
 package.loaded.pop_spell_turnins=nil
 package.loaded.knowledge_protection_trade=nil
 assert(loadfile(root..'/poknowledge/'..name))()
end
for _,name in ipairs(names) do
 for _,id in ipairs({29112,29131,29132}) do
  boot(name)
  e=event_with({{id,1}});event_trade(e)
  assert(#deliveries==1 and pending()=='' and e.trade.item1==nil)
  event_say(e);assert(#deliveries==1);count=count+1
  boot(name);capacity=0
  e=event_with({{id,1}});event_trade(e)
  assert(#deliveries==0 and pending()~='')
  package.loaded.pop_spell_turnins=nil;capacity=8
  event_say(e);event_say(e)
  assert(#deliveries==1 and pending()=='');count=count+1
  boot(name);fail_delivery=true
  e=event_with({{id,1}});event_trade(e)
  assert(#deliveries==0 and pending()~='')
  fail_delivery=false;event_say(e)
  assert(#deliveries==0 and raw_pending():sub(1,2)=='I|');count=count+1
  boot(name);capacity=0
  e=event_with({{id,20}});event_trade(e)
  assert(#rewards==0 and pending()==id..':20;')
  capacity=8;event_say(e)
  assert(#deliveries==1 and deliveries[1][1]==id and deliveries[1][2]==20 and pending()=='');count=count+1
 end
 boot(name);capacity=1;e=event_with({{29112,1},{29131,1},{29132,1}});event_trade(e)
 assert(#deliveries==1 and #rewards==0)
 slots={};capacity=8;event_say(e);event_say(e)
 assert(#deliveries==3 and pending()=='');count=count+1
 boot(name);npc.GetCleanName=function() return 'Other NPC' end;capacity=0;e=event_with({{29132,20}})
 assert(require('knowledge_protection_trade').ReturnProtectedItems(e))
 assert(pending()=='29132:20;')
 capacity=8;event_say(e);assert(#deliveries==1 and deliveries[1][2]==20 and pending()=='');count=count+1
 for _,fault in ipairs({'fail_write=2','throw_write=2','fail_write=3','throw_write=3','crash_before=true','crash_after=true','reenter=true','fail_read=4'}) do
  boot(name);assert(loadstring(fault))();e=event_with({{29112,1}});pcall(event_trade,e)
  local initial=#deliveries
  local no_attempt=fault=='fail_write=2' or fault=='throw_write=2'
  if no_attempt or fault=='crash_before=true' or fault=='fail_read=4' then assert(initial==0) else assert(initial==1) end
  fail_write=0;throw_write=0;crash_before=false;crash_after=false;reenter=false;fail_read=0
  package.loaded.pop_spell_turnins=nil;event_say(e);event_say(e)
  assert(#deliveries==(no_attempt and 1 or initial));count=count+1
 end
end
for _,name in ipairs({'Gork,_Theoretical_Physicist.lua','Mork,_Applied_Physicist.lua','../global/Nexus_Scion.lua'}) do
 boot(name);npc.GetCleanName=function() return 'Other NPC' end;capacity=0;e=event_with({{29112,2}})
 event_trade(e);assert(e.trade.item1==nil and pending()=='29112:2;' and #deliveries==0)
 capacity=8;require('pop_spell_turnins').Claim(e);require('pop_spell_turnins').Claim(e)
 assert(#deliveries==1 and deliveries[1][2]==2 and pending()=='');count=count+1
 boot(name);npc.GetCleanName=function() return 'Other NPC' end;eq.get_zone_short_name=function() return 'nexus' end;e=event_with({{29112,1}})
 assert(not require('knowledge_protection_trade').ReturnProtectedItems(e) and e.trade.item1~=nil and #deliveries==0);count=count+1
end
print(count..' PoK spell turn-in checks passed. Inventory and data buckets are mocked.')
