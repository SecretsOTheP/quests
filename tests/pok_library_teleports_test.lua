-- Run with Lua 5.1: lua tests/pok_library_teleports_test.lua .
local root = assert(arg[1], "quest root required");
package.path = root .. "/lua_modules/?.lua;" .. package.path;
eq = { debug = function() end };
local count = 0;
local function check(ok, message)
    assert(ok, message);
    count = count + 1;
end

local function client(x, y, z)
    local c = { x=x, y=y, z=z, messages={}, moves={}, returned={}, coins={} };
    function c:GetX() return self.x; end
    function c:GetY() return self.y; end
    function c:GetZ() return self.z; end
    function c:Message(color, text) table.insert(self.messages, text); end
    function c:MovePC(zone, x2, y2, z2, heading)
        table.insert(self.moves, {zone,x2,y2,z2,heading});
        self.x, self.y, self.z = x2, y2, z2;
    end
    function c:SummonItem(id, charges, slot, force)
        table.insert(self.returned, {id,charges,slot,force});
    end
    function c:AddMoneyToPP(copper,silver,gold,platinum,update)
        self.coins = {copper,silver,gold,platinum};
    end
    return c;
end

local function npc(x, y, z)
    local n = client(x,y,z);
    function n:Say() error("PUBLIC NPC SPEECH"); end
    function n:Emote() error("PUBLIC NPC EMOTE"); end
    function n:GetQuestLoot() return false; end
    function n:Charmed() return false; end
    function n:CanTalk() return true; end
    return n;
end

local definitions = {
    {name="Gork", file="library_gork", command="up", wrong="down", x=949,y=25,z=3.4, target={202,948,36,389.4,157}},
    {name="Mork", file="library_mork", command="down", wrong="up", x=948,y=44,z=389.4, target={202,949,17,3.4,157}}
};

for _, d in ipairs(definitions) do
    local environment = require(d.file);
    local n = npc(d.x,d.y,d.z);
    local bystander = client(d.x,d.y,d.z);
    local function say(c, text)
        environment.event_say({self=n, other=c, message=text});
    end
    for _, text in ipairs({d.command, "  " .. d.command:upper() .. "  "}) do
        local c = client(d.x,d.y-8,d.z);
        say(c,text);
        check(#c.moves==1, d.name .. " exact command must teleport once");
        for i,value in ipairs(d.target) do
            check(c.moves[1][i]==value, d.name .. " wrong destination component " .. i);
        end
        check(#c.messages==1, "travel reply must be private and singular");
    end
    for _, text in ipairs({"hail", "Hail, " .. d.name, "physics", "plans", d.wrong}) do
        local c = client(d.x,d.y,d.z);
        say(c,text);
        check(#c.moves==0 and #c.messages>0, "dialogue must not move player");
        for _, line in ipairs(c.messages) do
            check(line:sub(1,#d.name+8)==d.name .. ' says, "' and line:sub(-1)=='"', "private quoted prefix");
            check(not line:find("\018",1,true), "no clickable saylink payload");
        end
    end
    for _, text in ipairs({"setup", "downstairs", "upward", "shut up", "I am down", "unknown"}) do
        local c = client(d.x,d.y,d.z);
        say(c,text);
        check(#c.moves==0, "substring must not activate teleport");
    end
    for _, position in ipairs({{d.x,d.y,d.z+386}, {d.x+101,d.y,d.z}}) do
        local c = client(unpack(position));
        say(c,d.command);
        check(#c.moves==0 and #c.messages==0, "distant or other-floor interaction must be ignored");
    end
    local item = {valid=true};
    function item:GetID() return 29132; end
    function item:GetCharges() return 3; end
    local c = client(d.x,d.y,d.z);
    environment.event_trade({self=n,other=c,trade={item1=item,copper=4,silver=3,gold=2,platinum=1}});
    check(#c.returned==1 and c.returned[1][1]==29132 and c.returned[1][2]==3 and c.returned[1][4]==true, "return the full original item stack");
    check(c.coins[1]==4 and c.coins[2]==3 and c.coins[3]==2 and c.coins[4]==1, "return all coins");
    check(#c.messages==1 and #c.moves==0, "trade produces only a private acknowledgement");
    check(#bystander.messages==0 and #bystander.moves==0, "bystander must not receive messages or move");
end

-- Round trip through both actual scripts, with the same requesting client.
local c = client(949,17,3.4);
for _, d in ipairs(definitions) do
    local env = require(d.file);
    env.event_say({self=npc(d.x,d.y,d.z),other=c,message=d.command});
end
check(#c.moves==2 and c.x==949 and c.y==17 and c.z==3.4, "round trip returns to supplied downstairs landing");
print("PASS: " .. count .. " checks; exact commands, both landings, round trip, private speech, range isolation, quiet item/coin returns.");
