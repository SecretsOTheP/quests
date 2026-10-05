local path=arg[1] or 'potactics/214319.lua'
local file=assert(io.open(path));local source=file:read('*a');file:close()
local function npc(x,y,z)
 local n={x=x,y=y,z=z,vars={}}
 function n:GetX()return self.x end
 function n:GetY()return self.y end
 function n:GetZ()return self.z end
 function n:SetEntityVariable(k,v)self.vars[k]=v end
 function n:GetEntityVariable(k)return self.vars[k] or ''end
 function n:GMMove(x,y,z,h)self.x,self.y,self.z,self.h=x,y,z,h;self.warped=true end
 return n
end
local function load()
 local env=setmetatable({eq={set_timer=function()end,pause_timer=function()end,resume_timer=function()end,stop_timer=function()end}},{__index=_G})
 local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();return env
end
local env=load();local room=npc(319,110,181.6);local north=npc(-625,1980,204.5)
env.event_spawn({self=room});env.event_spawn({self=north})
room.x=-10;room.y=100;env.event_timer({self=room,timer='bounds'});assert(not room.warped)
north.y=100;env.event_timer({self=north,timer='bounds'});assert(north.warped and north.x==-625 and north.y==1980)
print('PASS mixed council/north-wing copies keep independent leash identity')
env=load();env.event_timer({self=room,timer='bounds'});assert(not room.warped)
print('PASS council copy identity survives Lua script reload')
local env2=load();north=npc(-625,1980,204.5);room=npc(319,110,181.6)
env2.event_spawn({self=north});env2.event_spawn({self=room});north.y=100;env2.event_timer({self=north,timer='bounds'});assert(north.warped)
print('PASS council copy spawned last does not suppress north-wing leash')
print('3 companion tests passed')
