local InstallProjectionFixture = assert(loadfile((arg[1] or ".") .. "/tests/flagger_test_fixture.lua"))();
-- Lua 5.1: lua tests/rathe_recovery_test.lua /path/to/Quests
local root=arg[1]or".";
local function read(path)local f=assert(io.open(root.."/"..path));local s=f:read("*a");f:close();return s;end
local source=rawget(_G,"RATHE_TEST_SOURCE")or read("poearthb/encounters/RatheCouncil.lua");
local mechanics=rawget(_G,"RATHE_COUNCIL_SOURCE")or read("poearthb/A_Rathe_Councilman.lua");
local checks=0;local function check(ok,message)assert(ok,message);checks=checks+1;end
local POINTS={369377,369380,369382,369384,369386,369387,369376,369378,369379,369381,369383,369385};
local TYPES={};for i,id in ipairs(POINTS)do TYPES[id]=i<=6 and 222003 or 222039;end
local function world(options)
    options=options or{};
    local s={now=1000000,uid=100,guild=options.guild or 66,npcs={},points={},timers={},saved={},handlers={},rp={},debug={},gm={},player={},updates={},projection=0,quakeOpen=true};
    local env;local mechanicsEnv={};
    local function live(n)return n and n.valid and n.hp>0 and not n.corpse;end
    local function client(gm,id)
        local c={valid=true,uid=id};function c:GetGM()return gm;end;function c:GetID()return self.uid;end
        function c:GetGuildName()return"Test Guild";end
        function c:MovePC(zone,x,y,z,h)s.port={zone,x,y,z,h};end
        function c:Message(color,text)local out=gm and s.gm or s.player;out[#out+1]={color=color,text=text};end
        return c;
    end
    s.clients={client(true,9001),client(false,9002)};
    local function npc(typ,point,x,y,z)
        s.uid=s.uid+1;local n={valid=true,uid=s.uid,typ=typ,point=point or 0,x=x or 2050,y=y or 410,z=z or-210,hp=typ==222040 and 500000 or 300000,maxhp=typ==222040 and 500000 or 300000,engaged=false,vars={},stats={}};
        function n:GetID()return self.uid;end;function n:GetNPCTypeID()return self.typ;end;function n:GetSpawnPointID()return self.point;end
        function n:GetHP()return self.hp;end;function n:GetHPRatio()return 100*self.hp/self.maxhp;end;function n:IsCorpse()return self.corpse or false;end
        function n:IsEngaged()return self.engaged;end;function n:IsMezzed()return self.mezzed or false;end;function n:GetTarget()return self.target or{valid=false};end
        function n:GetX()return self.x;end;function n:GetY()return self.y;end;function n:GetZ()return self.z;end
        function n:SetEntityVariable(k,v)self.vars[k]=v;end;function n:GetEntityVariable(k)return self.vars[k]or"";end
        function n:ModifyNPCStat(k,v)self.stats[k]=tonumber(v);end
        function n:GetHateRandomClient()return s.clients[2];end
        function n:WipeHateList()self.engaged=false;self.wiped=(self.wiped or 0)+1;end
        function n:Depop()self.valid=false;self.engaged=false;local p=s.points[self.point];if p and p.npc==self then p.npc=nil;end end
        s.npcs[n.uid]=n;local p=s.points[n.point];if p then p.npc=n;end;return n;
    end
    for _,id in ipairs(POINTS)do
        local p={valid=true,id=id,enabled=true,seconds=420,deadline=s.now+420};
        function p:GetNPC()return self.npc or{valid=false};end
        function p:Enabled()return self.enabled;end;function p:Enable()self.enabled=true;end
        function p:Disable(depop)self.enabled=false;if depop~=false and self.npc then self.npc:Depop();end end
        function p:SetTimer(ms)self.deadline=s.now+ms/1000;end
        s.points[id]=p;npc(TYPES[id],id);
    end
    local function list(values)
        local owner={};local weak=setmetatable({owner},{__mode="v"});local i=0;
        owner.entries=function()
            collectgarbage("collect");assert(weak[1],"native list owner released during iteration");i=i+1;local n=values[i];if not n then return;end
            return setmetatable({}, {__index=function(_,k)
                assert(weak[1],"borrowed native handle escaped its list owner");local value=n[k];
                if type(value)=="function"then return function(_,...)assert(weak[1],"borrowed native call escaped owner");return value(n,...);end;end
                return value;
            end});
        end;
        return owner;
    end
    local el={};
    function el:GetClientList()return list(s.clients);end
    function el:GetNPCList()local a={};for _,n in pairs(s.npcs)do if n.valid and n.uid~=0 then a[#a+1]=n;end end;return list(a);end
    function el:GetNPCByID(id)local n=s.npcs[id];return live(n)and n or{valid=false};end
    function el:GetSpawnByID(id)return s.points[id]or{valid=false,GetNPC=function()return{valid=false};end};end
    function el:IsMobSpawnedByNpcTypeID(typ)for _,n in pairs(s.npcs)do if live(n)and n.typ==typ then return true;end end;return false;end
    local function key(owner,name)return tostring(owner.uid)..":"..name;end
    local eqmock={get_zone_guild_id=function()return s.guild;end,get_entity_list=function()return el;end,
        get_data=function(k)return s.saved[k]or"";end,set_data=function(k,v)s.saved[k]=v;end,
        debug=function(text)s.debug[#s.debug+1]=text;end,zone_emote=function(color,text)s.rp[#s.rp+1]={color=color,text=text};end,
        set_timer=function(name,ms,owner)owner=owner or s.owner;s.timers[key(owner,name)]={owner=owner,name=name,duration=ms/1000,deadline=s.now+ms/1000};end,
        stop_timer=function(name,owner)s.timers[key(owner or s.owner,name)]=nil;end,
        update_spawn_timer=function(id,ms)s.updates[#s.updates+1]={id=id,ms=ms};end,
        register_npc_event=function(_,event,typ,callback)s.handlers[event..":"..typ]=callback;end,
        unique_spawn=function(typ,grid,u,x,y,z)
            if s.failAvatar then return{valid=false};end
            for _,n in pairs(s.npcs)do if live(n)and n.typ==typ then return n;end end
            local n=npc(typ,0,x,y,z);s:dispatch("spawn",n);return n;
        end,
        spawn2=function(typ,grid,u,x,y,z)
            if s.throwProjection then error("projection spawn fault");end
            if s.failProjection then return{valid=false};end
            local n=npc(typ,0,x,y,z);if typ==222041 then s.projection=s.projection+1;end;return n;
        end,
        signal=function(typ,id)if s.throwSignal then error("projection signal fault");end;s.signal={typ,id};end
    };
    local function loadMechanics()for _,typ in ipairs({222003,222039})do
        local e=setmetatable({eq=eqmock,os={time=function()return math.floor(s.now);end}},{__index=_G});local chunk=assert(loadstring(mechanics));setfenv(chunk,e);chunk();mechanicsEnv[typ]=e;
    end end
    loadMechanics();
    function s:dispatch(event,n,args)
        args=args or{};args.self=n;self.owner=n;
        local m=mechanicsEnv[n.typ];local own=m and m["event_"..(event=="death"and"death_complete"or event)];if own then own(args);end
        local handler=self.handlers[event..":"..n.typ];if handler then handler(args);end;self.owner=nil;
    end
    function s:load()
        loadMechanics();self.handlers={};for k,t in pairs(self.timers)do if t.owner.encounter then self.timers[k]=nil;end end
        self.encounter={uid="enc"..tostring(self.uid),encounter=true};self.uid=self.uid+1;
        env=setmetatable({eq=eqmock,os={time=function()return math.floor(s.now);end},Event={spawn="spawn",combat="combat",death_complete="death",signal="signal"}},{__index=_G});
        InstallProjectionFixture(env, arg[1] or ".");local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();self.env=env;self.owner=self.encounter;env.event_encounter_load({encounter=self.encounter});self.owner=nil;
    end
    function s:state()
        local raw=self.saved["rathe-recovery-v1-"..self.guild]or"0|0|2100|0|0|0|0|1|0|";local fields={};for part in(raw.."|"):gmatch("(.-)|")do fields[#fields+1]=part;end;return fields;
    end
    function s:phase()return tonumber(self:state()[1]);end
    function s:countDeaths()local count=0;for part in self:state()[10]:gmatch("[^;]+")do if part:match("^%d+:%d+:%d+:1:%d+$")then count=count+1;end end;return count;end
    function s:council(id)return self.points[id].npc;end
    function s:avatar()for _,n in pairs(self.npcs)do if live(n)and n.typ==222040 then return n;end end;end
    function s:liveCouncil()local count=0;for _,id in ipairs(POINTS)do if live(self.points[id].npc)then count=count+1;end end;return count;end
    function s:spawnNative(id)
        local p=self.points[id];local n=npc(TYPES[id],id);self:dispatch("spawn",n);return n;
    end
    function s:kill(n,killer)
        n.hp=0;n.corpse=true;n.engaged=false;local p=self.points[n.point];if p then p.npc=nil;p.deadline=self.now+p.seconds;end
        n.deathID=n.uid;n.uid=0;self:dispatch("death",n,{killer=killer or self.clients[1]});
    end
    function s:killCouncil()local a={};for _,id in ipairs(POINTS)do if live(self.points[id].npc)then a[#a+1]=self.points[id].npc;end end;for _,n in ipairs(a)do self:kill(n);end end
    function s:engage(n,value)n.engaged=value;self:dispatch("combat",n,{joined=value});end
    function s:tick()self.owner=self.encounter;env.event_timer({timer="watchdog"});self.owner=nil;end
    function s:jump(seconds)self.now=self.now+seconds;for _,t in pairs(self.timers)do t.deadline=self.now+t.duration;end;self:tick();end
    function s:advance(seconds)
        local target=self.now+seconds;local iterations=0;
        while true do
            local event,deadline;
            for k,t in pairs(self.timers)do local due=math.max(self.now,t.deadline);if due<=target and(not deadline or due<deadline)then event={timer=t};deadline=due;end end
            for id,p in pairs(self.points)do local due=math.max(self.now,p.deadline);if p.enabled and not p.blocked and not live(p.npc)and due<=target and(self.guild~=1 or self.quakeOpen)then
                if not deadline or due<deadline then event={point=id};deadline=due;end
            end end
            if not event then break;end;self.now=deadline;
            if event.timer then local t=event.timer;t.deadline=self.now+t.duration;self.owner=t.owner;
                if t.owner.encounter then env.event_timer({timer=t.name});elseif live(t.owner)then self:dispatch("timer",t.owner,{timer=t.name});end;self.owner=nil;
            else local p=self.points[event.point];p.deadline=self.now+p.seconds;self:spawnNative(event.point);end
            iterations=iterations+1;assert(iterations<300000,"timer loop did not settle");
        end;self.now=target;
    end
    function s:start()self:load();self:advance(1);end
    return s;
end

local s=world();s:start();check(s:phase()==0 and s:liveCouncil()==12,"all native Council members admitted");
local first=s:council(POINTS[1]);s:kill(first);check(s:countDeaths()==1,"mezable Council confirmed death with cleared entity ID counts");
s:kill(s:council(POINTS[7]));check(s:countDeaths()==2,"unmezable death shares the same persisted counter");
s:dispatch("death",first,{killer=s.clients[1]});check(s:countDeaths()==2,"duplicate death does not count twice");
s:dispatch("signal",s:council(POINTS[2]),{signal=POINTS[3]});check(s:countDeaths()==2,"legacy signals cannot forge Council deaths");
s:killCouncil();check(s:phase()==2 and s:avatar(),"all twelve confirmed current deaths spawn one Avatar");
check(s:liveCouncil()==0,"Council remains absent during Avatar phase");
for _,id in ipairs(POINTS)do check(not s.points[id].enabled,"Council held while Avatar is active");end
local a=s:avatar();s:engage(a,true);s:jump(10000);check(s:phase()==2 and tonumber(s:state()[3])==2100,"Avatar combat alone pauses shared idle budget");
s:engage(a,false);s:jump(120);check(tonumber(s:state()[3])==1980,"clock resumes on disengagement");
s:kill(a);check(s:phase()==4 and tonumber(s:state()[6])-s.now==496800,"confirmed Avatar death preserves138-hour success");
local essence;for _,n in pairs(s.npcs)do if n.typ==222041 then essence=n;end;end;check(s.projection==1 and essence:GetEntityVariable("flagger_v1_ready")=="1" and essence:GetEntityVariable("flagger_v1_characters")=="|9001|","Essence binds directly to kill rights");
local deadline=s:state()[6];s:load();s:advance(1);check(s:phase()==4 and s:state()[6]==deadline,"success deadline survives reload");
s:dispatch("death",a,{killer=s.clients[1]});check(s.projection==1,"duplicate Avatar death cannot duplicate rewards");
for _,entry in ipairs(s.rp)do check(entry.color==13,"player RP is red");end
for _,entry in ipairs(s.gm)do check(entry.color==15,"GM technical debug is yellow");end
check(#s.player==0,"technical debug never reaches ordinary clients");

s=world();s:start();for i=1,5 do s:kill(s:council(POINTS[i]));end;s:load();s:advance(1);check(s:countDeaths()==5,"Council kill progress survives quest reload");s:killCouncil();check(s:phase()==2,"remaining deaths after reload advance normally");
s=world();s:start();first=s:council(POINTS[1]);s:kill(first);s:advance(421);check(s:countDeaths()==0 and s:liveCouncil()==12,"returned Councilman clears stale death credit at seven minutes");
s:dispatch("death",first,{killer=s.clients[1]});check(s:countDeaths()==0,"old corpse event after return cannot count");
s=world();s:start();s.points[POINTS[1]].blocked=true;s:kill(s:council(POINTS[1]));s:jump(421);check(s:countDeaths()==0,"expired credit clears even if native spawn conditions block return");s:killCouncil();check(not s:avatar()and s:countDeaths()==11,"eleven fresh deaths plus expired credit cannot spawn Avatar");
s=world();s:start();s:council(POINTS[1]):Depop();s:advance(12);check(s:phase()==3 and s:liveCouncil()==0,"Council disappearance without a kill fails independently");
check(tonumber(s:state()[6])-s.now<=900,"Council failure has fifteen-minute retry");s:jump(901);s:advance(1);check(s:phase()==0 and s:liveCouncil()==12,"all twelve return after retry");
s=world();s:start();s:kill(s:council(POINTS[1]));s:council(POINTS[2]):Depop();s:spawnNative(POINTS[2]);check(s:phase()==3,"replaced alive Councilman cannot silently carry progress");
s=world();s:start();s.points[POINTS[1]]=nil;s:advance(1);check(s:phase()==3,"missing spawnpoint fails without nil dereference");
s.points[POINTS[1]]={valid=true,id=POINTS[1],enabled=false,seconds=420,deadline=s.now+420};local repaired=s.points[POINTS[1]];function repaired:GetNPC()return self.npc or{valid=false};end;function repaired:Enabled()return self.enabled;end;function repaired:Enable()self.enabled=true;end;function repaired:SetTimer(ms)self.deadline=s.now+ms/1000;end
s:advance(1);check(repaired.enabled,"recovery retries a restored missing spawnpoint");

s=world();s:start();s.timers={};s:killCouncil();s:jump(2101);check(s:phase()==3,"attempt start re-arms supervisor after forced repop clears timers");
check(s:liveCouncil()==0 and not s:avatar(),"expiry cleans Council/Avatar without NPC-owned timer");
s=world();s:start();s:killCouncil();s:advance(1);s:avatar():Depop();s:advance(12);check(s:phase()==3,"Avatar depop triggers independent recovery");
s=world();s:start();s:killCouncil();s:jump(15*60);check(s:state()[8]=="2","first Avatar warning at15 idle minutes");s:jump(10*60);check(s:state()[8]=="3","second warning at25 idle minutes");s:jump(5*60);check(s:state()[8]=="4","third warning at30 idle minutes");s:jump(5*60);check(s:phase()==3,"original idle deadline is35 minutes");
s=world();s:start();s:killCouncil();s:jump(100);local before=s:state()[3];s:load();s:advance(1);check(s:phase()==2 and tonumber(s:state()[3])<=tonumber(before),"Avatar reload does not reset idle budget");
s=world();s:start();s.failAvatar=true;s:killCouncil();check(s:phase()==3,"Avatar spawn failure rolls back to recovery");
s=world();s:start();s:killCouncil();s.throwProjection=true;s:kill(s:avatar());check(s:phase()==4,"projection exception cannot downgrade a confirmed victory");
s=world();s:start();s:killCouncil();s.throwSignal=true;s:kill(s:avatar());check(s:phase()==4 and s.projection==1,"legacy signal failure cannot affect direct eligibility handoff");
s=world();s:start();s:killCouncil();s:kill(s:avatar());deadline=s:state()[6];local f=s:state();f[10]="damaged";s.saved["rathe-recovery-v1-"..s.guild]=table.concat(f,"|");s:load();s:advance(1);check(s:phase()==4 and s:state()[6]==deadline,"damaged terminal records retain full successful cooldown");
s=world();s:start();s:killCouncil();s:kill(s:avatar());deadline=s:state()[6];f=s:state();f[3]="999999";s.saved["rathe-recovery-v1-"..s.guild]=table.concat(f,"|");s:load();s:advance(1);check(s:phase()==4 and s:state()[6]==deadline,"damaged clock metadata cannot shorten a valid success header");

s=world({guild=-1});s:start();s:killCouncil();check(not s:avatar()and s.saved["rathe-recovery-v1--1"]==nil,"open-world Council cannot produce Avatar or write guild progress");
s=world({guild=1});s:start();s.quakeOpen=false;s:killCouncil();check(s:phase()==2,"native Guild1 Council can complete its admitted encounter");s:jump(2101);check(s:phase()==3 and #s.updates==0,"Guild1 failure never forces timed Council resurrection");s:jump(901);s:advance(1);check(s:liveCouncil()==0,"Guild1 remains absent until native quake admission");s.quakeOpen=true;for _,id in ipairs(POINTS)do s:spawnNative(id);end;s:advance(1);check(s:phase()==0 and s:liveCouncil()==12,"new native quake admits fresh Guild1 Council without losing its NPCs");

-- Forced repop must also recover in Ready and terminal cooldown states.
s=world();s:start();s.timers={};for _,id in ipairs(POINTS)do s:council(id):Depop();end;for _,id in ipairs(POINTS)do s:spawnNative(id);end;s:advance(1);check(s:phase()==0 and s:liveCouncil()==12,"forced repop before engagement admits a full fresh Council");s:killCouncil();s:advance(1);check(s:phase()==2,"fresh round after forced repop retains scheduled supervision");
s=world();s:start();s:killCouncil();s:avatar():Depop();s:advance(12);deadline=s:state()[6];s:spawnNative(POINTS[1]);check(s:phase()==3 and s:state()[6]==deadline and s:liveCouncil()==0,"early cooldown spawn suppressed without extending retry");s.points[POINTS[2]].enabled=false;s:advance(1);check(s.points[POINTS[2]].enabled,"supervisor repairs a disabled Council point during cooldown");
s=world();s:start();s:killCouncil();s:kill(s:avatar());deadline=s:state()[6];s:jump(10);s:load();s:advance(1);check(s:state()[6]==deadline,"successful cooldown remains absolute after elapsed time and reload");
s=world({guild=1});s:start();s.quakeOpen=false;s:killCouncil();s:kill(s:avatar());f=s:state();f[10]="damaged";s.saved["rathe-recovery-v1-1"]=table.concat(f,"|");s.quakeOpen=true;for _,id in ipairs(POINTS)do s:spawnNative(id);end;s:load();s:advance(1);check(s:phase()==0 and s:liveCouncil()==12 and #s.updates==0,"fresh Guild1 native Council survives damaged old cooldown records");

-- Council has its own hard sixty-minute window; mez/combat cannot pause it.
s=world();s:start();local c=s:council(POINTS[1]);s:engage(c,true);check(s:phase()==1 and s:state()[9]==tostring(s.now),"Council first engagement starts an absolute sixty-minute deadline");
s:jump(30*60);check(s:state()[8]=="2","Council warning at thirty minutes");s:jump(15*60);check(s:state()[8]=="3","Council warning at forty-five minutes");s:jump(10*60);check(s:state()[8]=="4","Council warning at fifty-five minutes");s:jump(5*60);check(s:phase()==3,"Council combat does not pause the sixty-minute deadline");
s=world();s:start();s:engage(s:council(POINTS[1]),true);local started=s:state()[9];s:jump(1800);s:load();s:advance(1);check(s:state()[9]==started,"Council reload retains its original deadline");s:jump(1800);check(s:phase()==3,"reloaded Council expires at the original sixty-minute endpoint");
s=world();s:start();s:engage(s:council(POINTS[1]),true);s:jump(3500);s:killCouncil();check(s:phase()==2 and s:state()[3]=="2100","late Council success gives Avatar its separate original thirty-five-minute budget");
s=world();s:start();s:engage(s:council(POINTS[1]),true);s.now=s.now+3601;s:killCouncil();check(s:phase()==3 and not s:avatar(),"late Council kill cannot bypass the expired deadline between timer ticks");

-- Retained NPC mechanics: teleport bounds, weakening and mez hate wipe.
s=world();s:start();local n=s:council(POINTS[7]);n.hp=n.maxhp*0.10;s:engage(n,true);s:advance(12);check(n.stats.min_hit==185 and n.stats.max_hit==850 and n.stats.accuracy==0 and n.stats.atk==0,"unmezable weakening thresholds remain intact");
s:advance(60);check(s.port==nil,"Council teleport is suppressed below11 percent HP");n.hp=n.maxhp;s:engage(n,false);s:advance(3);check(n.stats.min_hit==623 and n.stats.max_hit==2964,"unmezable stats recover after deaggro/heal");s:engage(n,true);s:advance(60);check(s.port and s.port[1]==222 and s.port[4]==-255,"Council still teleports within Earth B");
s=world();s:start();n=s:council(POINTS[1]);n.mezzed=true;s:engage(n,true);s:advance(602);check((n.wiped or 0)>0,"ten-minute mezzed hate wipe preserved");
-- Quest reload rebuilds NPC Lua environments as well as the supervisor.
s=world();s:start();n=s:council(POINTS[7]);n.hp=n.maxhp*0.10;s:engage(n,true);s:advance(12);check(n.stats.min_hit==185,"Councilman weakened before reload");
s:load();s:advance(5);check(n.stats.min_hit==185 and n.stats.max_hit==850,"reload must not temporarily strengthen a weakened Councilman");
s=world();s:start();n=s:council(POINTS[1]);n.mezzed=true;s:engage(n,true);s:advance(570);check(not n.wiped,"mez hate wipe has not happened before ten minutes");
s:load();s:advance(35);check((n.wiped or 0)>0,"reload must retain elapsed mez time instead of restarting ten minutes");

print(checks.." Rathe recovery, generation, timer, quake, RP and combat-mechanic checks passed.");
