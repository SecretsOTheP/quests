-- Lua 5.1: exercise actual library dialogue callbacks without a running encounter.
local root = arg[1] or ".";
local checks = 0;
local function check(condition, message)
    assert(condition, message);
    checks = checks + 1;
end
local cases = {
    {name="Gork", file="Gork,_Theoretical_Physicist.lua", word="up", opposite="down", destination={202,948,36,389.4,157}},
    {name="Mork", file="Mork,_Applied_Physicist.lua", word="down", opposite="up", destination={202,949,17,3.4,157}}
};
for _,case in ipairs(cases) do
    local env = setmetatable({}, {__index=_G});
    local chunk = assert(loadfile(root .. "/poknowledge/" .. case.file));
    setfenv(chunk, env); chunk();
    local npc = {GetX=function()return 0;end,GetY=function()return 0;end,GetZ=function()return 0;end};
    function npc:Say() error("Library replies must remain private"); end
    local client = {horse=123, x=0, messages={}, moves={}};
    function client:GetX()return self.x;end
    function client:GetY()return 0;end
    function client:GetZ()return 0;end
    function client:GetHorseId()return self.horse;end
    function client:Message(color,text)self.messages[#self.messages+1]=text;end
    function client:MovePC(...)self.moves[#self.moves+1]={...};end
    local function say(message)env.event_say({self=npc,other=client,message=message});end
    say("  " .. case.word:upper() .. "  ");
    check(#client.moves==0,case.name .. " must not move a mounted player");
    check(#client.messages==1 and client.messages[1]:find("horse",1,true),case.name .. " explains dismount requirement privately");
    check(client.messages[1]:find("["..case.word:upper().."]",1,true),case.name .. " gives the retry keyword");
    check(client.messages[1]:find(case.name..' says, "',1,true)==1,case.name .. " preserves private NPC reply format");
    client.messages={};say("hail");
    check(#client.messages>0 and #client.moves==0,case.name .. " still responds to mounted hails without moving");
    client.messages={};say(case.opposite);
    check(#client.messages==1 and #client.moves==0,case.name .. " still explains the opposite direction");
    client.horse=0;client.messages={};say(case.word);
    check(#client.moves==1,case.name .. " allows the retry after dismount");
    for i,value in ipairs(case.destination) do
        check(client.moves[1][i]==value,case.name .. " preserves destination component "..i);
    end
    client.x=101;client.horse=123;client.messages={};say(case.word);
    check(#client.moves==1 and #client.messages==0,case.name .. " still ignores distant requests");
end
print("PASS library mounted teleport: "..checks.." checks.");
