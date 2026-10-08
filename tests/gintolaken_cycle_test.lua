-- Lua 5.1: lua tests/gintolaken_cycle_test.lua /path/to/Quests
local root = arg[1] or ".";
local checks = 0;
local function check(ok, message) assert(ok, message); checks = checks + 1; end
local HOURS = 66 * 3600;
local GROUPS = {
    {trigger=222008,boss=222037,bossPoint=369492,marker=369489,first=369438,triggerFile="A_Myrmidon_of_Stone.lua",bossFile="#War_Chieftan_Awisano.lua"},
    {trigger=222009,boss=222035,bossPoint=369493,marker=369487,first=369442,triggerFile="A_Stonefist_Clansman.lua",bossFile="#War_Chieftan_Birak.lua"},
    {trigger=222010,boss=222036,bossPoint=369494,marker=369488,first=369446,triggerFile="A_Rock_Studded_Champion.lua",bossFile="#War_Chieftan_Galronar.lua"},
};
local function world(guild)
    local w={now=1000,points={},saved={},writes={},mobs={},signals={},depopCalls={}};
    local invalid={valid=false};
    for id=369438,369449 do w.points[id]={valid=true,id=id};end
    for id=369487,369494 do w.points[id]={valid=true,id=id};end
    for id,p in pairs(w.points) do
        p.deadline=w.now+12345;
        function p:GetNPC() return self.npc or invalid;end
        function p:SetTimer(ms) self.deadline=w.now+ms/1000;end
        if id>=369487 and id<=369490 then
            local point=p;
            p.npc={valid=true};
            function p.npc:Depop(start)
                self.valid=false;point.npc=nil;
                if start then
                    -- Deliberately model the old marker base: explicit Lua
                    -- must replace it with 66h, without altering the 84h gate.
                    local seconds=point.id==369490 and 302400 or 216000;
                    point.deadline=w.now+seconds;w.saved[point.id]=point.deadline;
                end
            end
        end
        w.saved[id]=p.deadline;
    end
    local el={};
    function el:GetSpawnByID(id) return w.points[id] or invalid;end
    function el:IsMobSpawnedByNpcTypeID(id) return w.mobs[id] or false;end
    w.eq={
        get_zone_guild_id=function() return guild or 7;end,
        get_entity_list=function() return el;end,
        update_spawn_timer=function(id,ms)
            w.saved[id]=w.now+ms/1000;w.writes[#w.writes+1]={id=id,ms=ms};
            local p=w.points[id];if p and not p:GetNPC().valid then p:SetTimer(ms);end
        end,
        signal=function(id,value) w.signals[#w.signals+1]={id=id,value=value};end,
        depop_with_timer=function(id) w.depopCalls[#w.depopCalls+1]=id or 0;end,
        set_timer=function()end,stop_timer=function()end
    };
    w.moduleEnv=setmetatable({eq=w.eq},{__index=_G});
    local f=assert(loadfile(root.."/lua_modules/gintolaken_cycle.lua"));setfenv(f,w.moduleEnv);w.cycle=f();
    function w:script(name)
        local env=setmetatable({eq=self.eq,require=function(name)assert(name=="gintolaken_cycle");return self.cycle;end},{__index=_G});
        local f=assert(loadfile(root.."/poearthb/"..name));setfenv(f,env);f();return env;
    end
    return w;
end
local w=world();
for _,g in ipairs(GROUPS) do w:script(g.triggerFile);w:script(g.bossFile);end
w:script("#Warlord_Gintolaken.lua");
check(#w.writes==0,"loading scripts must preserve saved cooldowns");
local controller=w:script("The.lua");
for index,g in ipairs(GROUPS) do
    local trigger=w:script(g.triggerFile);
    w.mobs[g.trigger]=true;local before=#w.writes;
    trigger.event_death_complete({});
    check(#w.writes==before,"partial prerequisite clear must not advance or reset timers");
    w.mobs[g.trigger]=false;trigger.event_death_complete({});
    check(w.saved[g.bossPoint]==w.now+1,"last prerequisite must still activate its chieftain");
    for id=g.first,g.first+3 do
        check(w.saved[id]==w.now+HOURS and w.points[id].deadline==w.now+HOURS,"all four prerequisite timers must share the clear time");
    end
    check(w.points[g.marker]:GetNPC().valid,"group clear must not count as a chieftain kill");
    w.now=w.now+900;
    w.saved[g.bossPoint]=w.now+HOURS; -- Native death/loot timer starts now.
    w.points[g.bossPoint].deadline=w.saved[g.bossPoint];
    w:script(g.bossFile).event_death_complete({});
    check(not w.points[g.marker]:GetNPC().valid,"confirmed chieftain kill must remove its marker");
    check(w.saved[g.marker]==w.now+HOURS and w.points[g.marker].deadline==w.now+HOURS,"marker must get persisted 66h timer from boss death");
    for id=g.first,g.first+3 do check(w.saved[id]==w.saved[g.bossPoint],"prerequisites must not return before chieftain loot unlocks");end
    local signal=w.signals[#w.signals];check(signal.id==222034 and signal.value==1,"original progression signal must remain");
    controller.event_signal({signal=1});
    check((w.saved[369491]==w.now+1)==(index==3),"only three confirmed chieftain kills should open Gintolaken");
    w.now=w.now+300;
end
local killAt=w.now;
w.saved[369491]=killAt+HOURS;w.points[369491].deadline=killAt+HOURS;
w:script("#Warlord_Gintolaken.lua").event_death_complete({});
for _,g in ipairs(GROUPS) do
    for id=g.first,g.first+3 do check(w.saved[id]==killAt+HOURS and w.points[id].deadline==killAt+HOURS,"full chain must align to the final kill and shared event reuse");end
    check(w.saved[g.marker]==killAt+HOURS,"all chieftain markers align to final kill");
    check(w.saved[g.bossPoint]==killAt+HOURS,"chieftain native respawns must not jump ahead of final cycle");
end
check(w.saved[369491]==killAt+HOURS,"Gintolaken native death timer must remain unchanged");
check(w.points[369490].deadline==killAt+302400 and w.saved[369490]==killAt+302400,"Council access must remain 84h");
check(not w.points[369490]:GetNPC().valid,"Council must still unlock on Gintolaken death");
w.now=w.now+3600;local writes=#w.writes;
local f=assert(loadfile(root.."/lua_modules/gintolaken_cycle.lua"));setfenv(f,w.moduleEnv);f();
check(#w.writes==writes and w.saved[369438]==killAt+HOURS,"module reload must not restart the cooldown");
local pvp=world(1);
for _,g in ipairs(GROUPS) do pvp.saved[g.bossPoint]=987654321;pvp.points[g.bossPoint].deadline=987654321;end
pvp:script("#Warlord_Gintolaken.lua").event_death_complete({});
for _,g in ipairs(GROUPS) do
    check(pvp.saved[g.bossPoint]==987654321 and pvp.points[g.bossPoint].deadline==987654321,"Guild 1 raid earthquake timers must not be replaced");
end
local missing=world();missing.points[369489]=nil;
missing:script("#War_Chieftan_Awisano.lua").event_death_complete({});
check(missing.saved[369489]==missing.now+HOURS,"missing live marker must still receive a durable cooldown");
check(#missing.signals==1,"missing marker must not abort a confirmed kill");
local returned=world();
for _,g in ipairs(GROUPS) do
    local script=returned:script(g.triggerFile);script.event_spawn({});
    check(returned.depopCalls[#returned.depopCalls]==g.boss,"returning prerequisite retains original chieftain cleanup");
    for id=g.first,g.first+3 do check(returned.saved[id]==returned.now+1,"returning prerequisite still synchronizes all four spawns");end
    check(returned.saved[g.marker]==returned.now+1,"returning prerequisite rearms its death marker");
end
print("gintolaken_cycle_test: "..checks.." checks passed");
