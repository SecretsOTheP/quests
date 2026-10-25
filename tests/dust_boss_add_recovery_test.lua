-- Lua 5.1: lua tests/dust_boss_add_recovery_test.lua /path/to/Quests
local root = arg[1] or ".";
local checks = 0;
local function check(ok, message) assert(ok, message); checks = checks + 1; end
local function source(path)
    local f = assert(io.open(root.."/"..path)); local text = f:read("*a"); f:close(); return text;
end
local ADD, BOSS, FOLLOWER, CONTROLLER = 218421, 218413, 218415, 218397;
local function world(realBoss)
    local w = {now=1000000, nextid=1, npcs={}, handlers={}, writes={}, logs={}, messages={}, signals={}, addAttempts=0};
    local owner, env;
    local function live(n) return n and n.valid and n.hp > 0 and not n.corpse; end
    function w:list(typ)
        local result = {}; for _,n in pairs(self.npcs) do if live(n) and n.typ == typ then result[#result+1] = n; end end
        return result;
    end
    function w:one(typ) return self:list(typ)[1]; end
    function w:dispatch(event, n, extra)
        local cb = self.handlers[event..":"..n.typ];
        if cb then local previous = owner; owner = n; local e = extra or {}; e.self = n; cb(e); owner = previous; end
    end
    function w:spawn(typ, x, y, z)
        if typ == ADD then
            self.addAttempts = self.addAttempts + 1;
            if self.failAt == self.addAttempts then
                if self.failMode == "throw" then error("injected add spawn exception"); end
                if self.failMode == "nil" then return nil; end
                -- Real null Lua_NPC wrappers no-op on methods instead of raising an error.
                return setmetatable({valid=false}, {__index=function(_, key)
                    if key == "CastToNPC" then return function(n) return n; end; end
                    return function() end;
                end});
            end
        end
        local n = {id=self.nextid, typ=typ, valid=true, hp=100, vars={}, x=x or 0, y=y or 0, z=z or 0};
        self.nextid = self.nextid + 1; self.npcs[n.id] = n;
        function n:GetID() return self.corpse and 0 or self.id; end
        function n:GetNPCTypeID() return self.typ; end
        function n:GetHP() return self.hp; end
        function n:GetMaxHP() return 100; end
        function n:GetHPRatio() return self.hp; end
        function n:IsCorpse() return self.corpse or false; end
        function n:GetX() return self.x; end; function n:GetY() return self.y; end; function n:GetZ() return self.z; end
        function n:SetHP(hp) self.hp=hp; end
        function n:SetEntityVariable(k,v) self.vars[k]=v; end
        function n:GetEntityVariable(k) return self.vars[k] or ""; end
        function n:SetSpecialAbility() end; function n:SetBodyType() end; function n:SetRunning() end
        function n:CastToNPC() return self; end; function n:MoveTo() end
        function n:IsEngaged() return false; end; function n:GetTarget() return {valid=false}; end
        function n:GetGuardPointX() return self.x; end; function n:GetGuardPointY() return self.y; end
        function n:GetGuardPointZ() return self.z; end; function n:GetSpawnPointH() return 0; end
        function n:GMMove() end; function n:Depop() self.valid=false; end
        self:dispatch("spawn", n); return n;
    end
    function w:kill(n) assert(n); n.hp=0; n.corpse=true; self:dispatch("death", n); return n; end
    function w:killAll(typ) for _,n in ipairs(self:list(typ)) do self:kill(n); end end
    local el = {};
    function el:GetMob(id) return w.npcs[id] or {valid=false}; end
    function el:GetMobByNpcTypeID(typ) return w:one(typ) or {valid=false}; end
    function el:IsMobSpawnedByNpcTypeID(typ) return w:one(typ) ~= nil; end
    function el:MessageClose() end
    function el:GetSpawnByID() return {Enable=function() w.enabled=true; end}; end
    function el:GetNPCList()
        local list={}; for _,n in pairs(w.npcs) do if live(n) then list[#list+1]=n; end end
        local i=0; return {entries=function() i=i+1; return list[i]; end};
    end
    local eq = {
        get_entity_list=function() return el; end,
        register_npc_event=function(group,event,typ,cb) assert(group=="DustRing"); w.handlers[event..":"..typ]=cb; end,
        spawn2=function(typ,_,__,x,y,z) return w:spawn(typ,x,y,z); end,
        set_timer=function() end, stop_timer=function() end, pause_timer=function() end, resume_timer=function() end,
        depop_all=function(typ) for _,n in ipairs(w:list(typ)) do n:Depop(); end end,
        depop_with_timer=function(typ) for _,n in ipairs(w:list(typ)) do n:Depop(); end end,
        depop=function() if owner then owner:Depop(); end end,
        update_spawn_timer=function(id,ms) w.writes[#w.writes+1]={id=id,ms=ms}; end,
        debug=function(message) w.logs[#w.logs+1]=message; end,
        zone_emote=function(color,message) if color==15 then w.messages[#w.messages+1]=message; end end,
        signal=function(typ,value) w.signals[#w.signals+1]={typ=typ,value=value}; end,
    };
    env=setmetatable({eq=eq, os={time=function() return w.now; end}, Event={spawn="spawn",death_complete="death",combat="combat",timer="timer"}}, {__index=_G});
    env.require=function(name) assert(name=="earth_ring_guard"); return setfenv(assert(loadstring(source("lua_modules/earth_ring_guard.lua"))),env)(); end;
    setfenv(assert(loadstring(source("poeartha/encounters/DustRing.lua"))),env)(); env.event_encounter_load({encounter={}});
    function w:tick(seconds) self.now=self.now+(seconds or 5); env.event_timer({timer="earth_guard"}); end
    function w:begin()
        if realBoss then self:spawn(218412); end
        self:kill(self:spawn(218022)); self:killAll(218366); self:killAll(218367);
        self.boss=assert(self:one(realBoss and BOSS or FOLLOWER));
    end
    function w:spawnAdds() self:dispatch("timer",self.boss,{timer="triumvirates"}); end
    function w:failed()
        check(#self.writes==1 and self.writes[1].id==366233 and self.writes[1].ms==900000 and self.enabled,"failure saves only 15-minute warder retry");
        check(#self.signals==0,"failure grants no Arbitor credit");
        check(#self.messages==1 and self.messages[1]:find("15 minutes",1,true),"failure emits one RP retry announcement");
        check(not self.messages[1]:find("type=",1,true) and not self.messages[1]:find("Phase:",1,true),"technical debug stays out of public chat");
        check(self.logs[#self.logs]:find("Boss Triumvirates awaiting kills:",1,true),"server debug records pending required add kills");
        check(not self:one(ADD) and not self:one(CONTROLLER) and not self:one(BOSS) and not self:one(FOLLOWER),"failure cleans encounter NPCs");
    end
    function w:succeeded()
        check(#self.writes==1 and self.writes[1].ms==237600000,"success retains 66-hour cooldown");
        check(#self.signals==1 and self.signals[1].typ==218393 and self.signals[1].value==4,"success grants exactly one Dust credit");
        check(#self.messages==0,"success emits no failure RP");
    end
    w:begin(); return w;
end

for _,realBoss in ipairs({true,false}) do
    for _,mode in ipairs({"invalid","nil","throw"}) do
        for failAt=1,3 do
            local w=world(realBoss); w.failAt=failAt; w.failMode=mode; w:spawnAdds(); w:failed();
            w:dispatch("timer",w.boss,{timer="triumvirates"}); w:dispatch("combat",w.boss,{joined=true}); w:kill(w.boss); w:tick(6000);
            check(w.addAttempts==failAt and #w.writes==1 and #w.messages==1,"late boss callbacks cannot spawn adds or grant success after failure");
        end
    end
    local w=world(realBoss); w:spawnAdds(); check(#w:list(ADD)==3,"normal boss wave spawns all three required adds");
    local lost=w:one(ADD); lost:Depop(); w:killAll(ADD);
    w:dispatch("combat",w.boss,{joined=true}); w:spawnAdds();
    check(w.addAttempts==3,"re-engaging cannot replace an unconfirmed missing add");
    w.boss.hp=40; w:dispatch("timer",w.boss,{timer="drophate"});
    check(w.boss.hp==50,"boss remains HP-gated while a missing add lacks a confirmed death");
    w:tick(); check(#w.writes==0,"missing add gets normal watchdog grace"); w:tick(30); w:failed();

    w=world(realBoss); w:spawnAdds(); lost=w:one(ADD); lost:Depop(); w:killAll(ADD); w:kill(w.boss); w:failed();
    check(w.logs[#w.logs]:find("required boss Triumvirate kills missing",1,true),"boss kill during missing-add grace cannot grant free progress");

    w=world(realBoss); w:spawnAdds(); local adds=w:list(ADD);
    w:kill(adds[1]); w:dispatch("death",adds[1]); w:kill(adds[2]);
    w.boss.hp=40; w:dispatch("timer",w.boss,{timer="drophate"});
    check(w.boss.hp==50,"duplicate add death cannot satisfy last required kill");
    w:kill(adds[3]); w.boss.hp=40; w:dispatch("timer",w.boss,{timer="drophate"});
    check(w.boss.hp==40,"three confirmed deaths release boss HP gate");
    w:kill(w.boss); w:dispatch("death",w.boss); w:succeeded(); w:tick(6000);
    check(#w.writes==1,"completed wave cannot fail later");

    w=world(realBoss); w:spawnAdds(); adds=w:list(ADD); w:killAll(ADD);
    w:dispatch("combat",w.boss,{joined=false}); w:dispatch("combat",w.boss,{joined=true}); w:spawnAdds();
    check(#w:list(ADD)==3 and w.addAttempts==6,"normal wipe after cleared adds can summon a fresh wave");
    for _,n in ipairs(adds) do w:dispatch("death",n); end
    w.boss.hp=40; w:dispatch("timer",w.boss,{timer="drophate"});
    check(w.boss.hp==50,"previous-wave death callbacks cannot clear fresh wave");
    w:killAll(ADD); w:kill(w.boss); w:succeeded();

    w=world(realBoss); w:dispatch("timer",w.boss,{timer="protectors"});
    check(#w:list(218414)==3,"optional protector behavior unchanged"); w:kill(w.boss); w:succeeded();
end
print("PASS: "..checks.." Dust boss add recovery checks");
