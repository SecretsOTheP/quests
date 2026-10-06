-- Run with Lua 5.1: lua tests/coirnav_recovery_test.lua /path/to/Quests
local root=arg[1] or ".";
local source=rawget(_G,"COIRNAV_TEST_SOURCE");
if not source then local f=assert(io.open(root.."/powater/encounters/Coirnav.lua"));source=f:read("*a");f:close();end
local checks=0;
local function check(ok,text) assert(ok,text);checks=checks+1;end
local function iterator(list) local i=0;return function() i=i+1;return list[i];end end
local TYPES={[216257]=true,[216260]=true,[216258]=true,[216236]=true,[216245]=true,[216247]=true,[216256]=true,[216259]=true,[216265]=true};
local GUARDIAN=366321;
local function world(options)
    options=options or {};
    local s={now=1000000,guild=options.guild or 66,uid=100,npcs={},points={},timers={},saved={},rp={},debug={},gm={},player={},updates={},projection=0};
    local env;
    local function key(owner,name) return tostring(owner.uid)..":"..name;end
    local function live(n) return n and n.valid and n.hp>0 and not n.corpse;end
    local function client(gm,uid)
        local c={valid=true,uid=uid};function c:GetGM()return gm;end;function c:GetID()return uid;end
        function c:Message(color,text) local list=gm and s.gm or s.player;list[#list+1]={color=color,text=text};end
        return c;
    end
    s.clients={client(true,9001),client(false,9002)};
    local function point(id,typ,enabled,seconds)
        local p={valid=true,id=id,typ=typ,enabled=enabled,seconds=seconds,deadline=s.now+(seconds or 0)};
        function p:GetNPC()return self.npc or {valid=false};end
        function p:Enabled()return self.enabled;end
        function p:Enable()self.enabled=true;end
        function p:Repop()if live(self.npc)then self.npc:Depop();end;self.enabled=true;self.deadline=s.now;return s:spawnNative(self.id);end
        function p:Disable(depop)self.enabled=false;if depop~=false and live(self.npc)then self.npc:Depop();end end
        function p:SetTimer(ms)self.deadline=s.now+ms/1000;end
        function p:NPCPointerValid()return live(self.npc);end
        s.points[id]=p;return p;
    end
    point(GUARDIAN,216053,true,496800);
    point(365647,216048,true,options.nativeDelay or 496800);
    
    local function npc(typ,spawnid,x,y,z,h)
        s.uid=s.uid+1;local n={valid=true,uid=s.uid,typ=typ,spawnid=spawnid or 0,hp=100,vars={},x=x or 0,y=y or 0,z=z or 0,h=h or 0};
        function n:GetID()return self.uid;end;function n:GetNPCTypeID()return self.typ;end
        function n:GetSpawnPointID()return self.spawnid;end;function n:GetHP()return self.hp;end
        function n:IsCorpse()return self.corpse or false;end;function n:IsEngaged()return self.engaged or false;end
        function n:GetCleanName()return "NPC "..self.typ;end
        function n:CastToNPC()return self;end
        function n:SetBaseHP(hp)self.hp=hp;self.baseHP=hp;end
        function n:SetSpecialAbility(id,value)self.abilities=self.abilities or {};self.abilities[id]=value;end
        function n:SetBodyType(body)self.body=body;end
        function n:BuffFadeAll()self.faded=true;end
        function n:WipeHateList()self.engaged=false;end
        function n:CastSpell(id,target)s.banish=s.banish or {};s.banish[#s.banish+1]=id;end
        function n:SetEntityVariable(k,v)self.vars[k]=v;end;function n:GetEntityVariable(k)return self.vars[k]or"";end
        function n:GetX()return self.x;end;function n:GetY()return self.y;end;function n:GetZ()return self.z;end
        function n:Depop()self.valid=false;self.hp=0;local p=s.points[self.spawnid];if p and p.npc==self then p.npc=nil;end end
        s.npcs[n.uid]=n;local p=s.points[n.spawnid];if p then p.npc=n;end
        return n;
    end
    s.npc=npc;
    function s:dispatch(event,n,extra)
        local callback=self.handlers and self.handlers[event..":"..n.typ];if not callback then return;end
        local previous=self.owner;self.owner=n;local e=extra or {};e.self=n;callback(e);self.owner=previous;
    end
    function s:spawnNative(id)
        local p=assert(self.points[id]);local n=npc(p.typ,id);self:dispatch("spawn",n);return n;
    end
    if options.boss~=false then npc(216048,365647);end
    if options.guardian~=false then npc(216053,GUARDIAN);end
    if options.controller~=false then npc(216072,0);end
    local function scopedList(list)
        if not options.strictLists then return {entries=iterator(list)};end
        local owner={};local weak=setmetatable({owner},{__mode="v"});local index=0;
        owner.entries=function()
            collectgarbage("collect");assert(weak[1],"temporary entity list owner was collected during iteration");
            index=index+1;local native=list[index];if not native then return nil;end
            return setmetatable({}, {__index=function(_,field)
                collectgarbage("collect");assert(weak[1],"borrowed entity handle escaped its list lifetime");
                local value=native[field];
                if type(value)=="function" then return function(_,...)return value(native,...);end end
                return value;
            end});
        end
        return owner;
    end
    local elist={};
    function elist:GetNPCList()
        local a={};for _,n in pairs(s.npcs)do if n.valid and not n.corpse then a[#a+1]=n;end end
        table.sort(a,function(x,y)return x.uid<y.uid;end);return scopedList(a);
    end
    function elist:GetClientList()return scopedList(s.clients);end
    function elist:GetNPCByID(id)local n=s.npcs[id];return live(n)and n or {valid=false};end
    function elist:GetSpawnByID(id)return s.points[id]or{valid=false};end
    function elist:GetNPCByNPCTypeID(typ)for _,n in pairs(s.npcs)do if n.typ==typ and live(n)then return n;end end;return{valid=false};end
    local eqmock={
        get_zone_guild_id=function()return s.guild;end,get_entity_list=function()return elist;end,
        get_data=function(k)return s.saved[k]or"";end,set_data=function(k,v)s.saved[k]=v;end,
        debug=function(text)s.debug[#s.debug+1]=text;end,
        zone_emote=function(color,text)s.rp[#s.rp+1]={color=color,text=text,time=s.now};end,
        set_timer=function(name,ms,owner)owner=owner or s.owner;s.timers[key(owner,name)]={owner=owner,name=name,duration=ms/1000,deadline=s.now+ms/1000};end,
        stop_timer=function(name,owner)s.timers[key(owner or s.owner,name)]=nil;end,
        stop_all_timers=function(owner)for k,t in pairs(s.timers)do if t.owner==owner then s.timers[k]=nil;end end;end,
        update_spawn_timer=function(id,ms)s.updates[id]=ms;end,
        spawn2=function(typ,grid,unused,x,y,z,h)
            if s.failType==typ then return {valid=false};end
            if typ==216266 and s.throwProjection then error("projection fault");end
            if typ==216266 and s.failProjection then return {valid=false};end
            local n=npc(typ,0,x,y,z,h);if typ==216266 then s.projection=s.projection+1;end;s:dispatch("spawn",n);return n;
        end,
        signal=function(typ,sig)for _,n in pairs(s.npcs)do if n.typ==typ and live(n)then s:dispatch("signal",n,{signal=sig});end end end,
        ChooseRandom=function(...)return select(1,...);end,
        register_npc_event=function(_,event,typ,handler)s.handlers[event..":"..typ]=handler;end
    };
    function s:load()
        self.handlers={};for k,t in pairs(self.timers)do if t.owner.encounter then self.timers[k]=nil;end end
        self.encounter={uid="enc"..tostring(self.uid),encounter=true};self.uid=self.uid+1;
        env=setmetatable({eq=eqmock,os={time=function()return math.floor(s.now);end},Event={spawn="spawn",combat="combat",death_complete="death",signal="signal",timer="timer"}},{__index=_G});
        local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();self.env=env;
        self.owner=self.encounter;env.event_encounter_load({encounter=self.encounter});self.owner=nil;
    end
    function s:state()
        local value=self.saved["coirnav-recovery-v1-"..self.guild]or"0|0|0|0|0|0|1|0|0|0|0|";local f={};
        for part in(value.."|"):gmatch("(.-)|")do f[#f+1]=part;end;return f;
    end
    function s:phase()return tonumber(self:state()[1]);end
    function s:actors()
        local a={};for _,n in pairs(self.npcs)do if live(n)and TYPES[n.typ]then a[#a+1]=n;end end
        table.sort(a,function(x,y)return x.uid<y.uid;end);return a;
    end
    function s:kill(n)
        n.hp=0;n.corpse=true;n.engaged=false;local p=self.points[n.spawnid];if p then p.npc=nil;p.deadline=self.now+p.seconds;end
        -- NPC::CreateCorpse removes the live entity and clears its ID before
        -- EVENT_DEATH_COMPLETE; entity variables still retain spawn identity.
        n.deathEntityID=n.uid;n.uid=0;
        self:dispatch("death",n,{killer=self.clients[1]});
    end
    function s:engage(n,value)n.engaged=value;self:dispatch("combat",n,{joined=value});end
    function s:killStage()local list=self:actors();for _,n in ipairs(list)do self:kill(n);end;end
    function s:advance(seconds)
        local target=self.now+seconds;local iterations=0;
        while true do
            local event,deadline;
            for k,t in pairs(self.timers)do if t.deadline<=target and(not deadline or t.deadline<deadline)then event={timer=t,k=k};deadline=t.deadline;end end
            for id,p in pairs(self.points)do if p.enabled and not live(p.npc)and p.deadline<=target and not(self.guild==1 and (id==GUARDIAN or id==365647)and not self.quakeOpen)then
                if not deadline or p.deadline<deadline then event={point=id};deadline=p.deadline;end
            end end
            if not event then break;end
            self.now=deadline;
            if event.timer then
                local t=event.timer;t.deadline=self.now+t.duration;self.owner=t.owner;
                if t.owner.encounter then env.event_timer({timer=t.name});end;self.owner=nil;
            else local p=self.points[event.point];p.deadline=self.now+p.seconds;self:spawnNative(event.point);end
            iterations=iterations+1;assert(iterations<300000,"event loop did not settle");
        end
        self.now=target;
    end
    function s:tick()self.owner=self.encounter;env.event_timer({timer="watchdog"});self.owner=nil;end
    function s:jump(seconds)self.now=self.now+seconds;for _,t in pairs(self.timers)do t.deadline=self.now+t.duration;end;self:tick();end
    function s:start()self:load();self:advance(1);self:kill(self.points[GUARDIAN].npc);end
    function s:boss()return self.points[365647].npc;end
    function s:fiends()
        local out={};for _,n in ipairs(self:actors())do if n.typ==216257 or n.typ==216260 or n.typ==216258 then out[#out+1]=n;end end;return out;
    end
    function s:killFiends()for _,n in ipairs(self:fiends())do self:kill(n);end end
    function s:minis()
        local out={};for _,n in ipairs(self:actors())do if n.typ==216236 or n.typ==216245 or n.typ==216247 then out[#out+1]=n;end end;return out;
    end
    function s:openBoss()self:killFiends();self:advance(180);self:killFiends();self:advance(120);self:killFiends();end
    function s:warnings()
        local out={};for _,e in ipairs(self.rp)do if e.text:find("The waters churn as three voices",1,true)or e.text:find("Ice spreads across the reef",1,true)or e.text:find("The reef trembles beneath the gathering fury",1,true)then out[#out+1]=e;end end;return out;
    end
    return s;
end


local s=world();s:start();check(s:phase()==1 and #s:fiends()==25 and #s:minis()==1,"first wave starts with 25 tracked fiends and Pwelon");
check(s:boss().abilities[35]==1 and s:boss().body==11,"Coirnav remains protected during fiend waves");
local first=s:fiends()[1];s:kill(first);local credit=s:state()[6];s:dispatch("death",first,{killer=s.clients[1]});check(s:state()[6]==credit,"duplicate corpse-producing kill cannot count twice");
s:killFiends();check(s:state()[6]=="25" and s:phase()==1,"first wave alone cannot unlock boss");
s:advance(179);check(#s:fiends()==0,"ice wave is not early");s:advance(1);check(#s:fiends()==25 and #s:minis()==2,"ice wave arrives after three minutes");
s:killFiends();s:advance(120);check(#s:fiends()==25 and #s:minis()==3,"water wave arrives after five minutes");s:killFiends();
check(s:phase()==2 and s:state()[6]=="75" and #s:minis()==3,"75 confirmed deaths summon the three stronger minibosses");
check(s:boss().abilities[35]==0 and s:boss().body==1,"Coirnav becomes attackable at the original stage");
local hp={};for _,n in ipairs(s:minis())do hp[n.typ]=n.baseHP;end
check(hp[216236]==130000 and hp[216245]==120000 and hp[216247]==155000,"stronger miniboss base HP values retained");
for _,n in ipairs(s:minis())do s:kill(n);end
check(s:phase()==3 and s:boss().baseHP==250000 and s:boss().faded,"confirmed miniboss deaths trigger original final boss reset");
check(#s:actors()==25,"first final reinforcement wave appears immediately");s:advance(48);check(#s:actors()==25,"repeat wave is not early");s:advance(1);check(#s:actors()==50,"reinforcements repeat every 49 seconds");
local boss=s:boss();s:kill(boss);check(s:phase()==5 and s.projection==1,"boss death records success and projection");
check(s.updates[365647]==496800000 and s.updates[GUARDIAN]==496800000,"success aligns boss and Guardian at 138 hours");
check(#s:actors()==0 and first.valid and first.corpse,"success removes living adds and preserves corpses");
check(#s.gm>0 and #s.player==0,"technical messages are GM-only");for _,e in ipairs(s.rp)do check(e.color==13,"player RP is red");end
for _,e in ipairs(s.gm)do check(e.color==15,"GM debug is yellow");end
local untilTime=s:state()[9];s:load();s:advance(1);check(s:phase()==5 and s:state()[9]==untilTime and s.projection==1,"success reload preserves cooldown without another projection");

s=world();s:start();s:killFiends();s:advance(50);local started=s:state()[3];local deadline=s:state()[4];s:load();s:advance(1);
check(s:phase()==1 and s:state()[6]=="25" and s:state()[3]==started and s:state()[4]==deadline,"reload preserves fiend count and absolute deadline");
s:advance(129);check(#s:fiends()==25,"scheduled wave remains aligned with original start after reload");

s=world();s:start();first=s:fiends()[1];first:Depop();s:killFiends();check(s:state()[6]=="24","depop is not a kill");s:advance(14);
check(s:phase()==4 and #s:actors()==0 and s.banish[1]==1099,"missing fiend triggers banishment and independent cleanup");
check(s.updates[365647]<=600000 and s.updates[365647]>590000,"failed attempt retains ten-minute recovery");
untilTime=s:state()[9];s:load();s:advance(1);check(s:state()[9]==untilTime,"retry deadline survives reload without restarting");
s:jump(601);s:advance(1);check(s:phase()==0 and s:boss()and s.points[GUARDIAN].npc,"Coirnav and Guardian return after failure reuse");
s:kill(s.points[GUARDIAN].npc);check(s:phase()==1 and s:state()[2]=="2","returned Guardian starts a fresh attempt");
s:dispatch("death",first,{killer=s.clients[1]});check(s:state()[6]=="0","old death cannot count in new attempt");

s=world({controller=false});s:start();s:advance(900);check(s:phase()==4,"deadline expires without The_monstrous");
check(#s:actors()>0,"banishment retains its original two-second cleanup grace");s:advance(2);check(#s:actors()==0 and not s:boss(),"cleanup follows banishment without an NPC signal");
check(#s:warnings()==3,"all three countdown warnings fire once");

s=world();s:start();s:engage(s:boss(),true);s:advance(902);check(s:phase()==4 and #s:actors()==0,"combat does not pause original fifteen-minute deadline");

s=world();s:start();s:openBoss();local minis=s:minis();minis[1]:Depop();s:kill(minis[2]);s:kill(minis[3]);
check(s:phase()==2,"missing miniboss cannot satisfy final-stage completion");s:advance(14);check(s:phase()==4,"missing miniboss recovers instead of stalling or advancing");

s=world();s:start();s:openBoss();s:kill(s:boss());check(s:phase()==5 and s.projection==1,"original attackable-stage boss victory remains allowed before miniboss clear");

s=world();s:start();s:openBoss();s.throwProjection=true;s:kill(s:boss());check(s:phase()==5 and s.updates[365647]==496800000,"projection fault cannot shorten successful reuse");

s=world();s.failType=216257;s:start();s:advance(2);check(s:phase()==4 and #s:actors()==0,"failed wave creation cleans partial setup and recovers");

s=world();s:start();first=s:fiends()[1];first:Depop();local clone=s.npc(first.typ);for k,v in pairs(first.vars)do clone.vars[k]=v;end;s:dispatch("spawn",clone);
check(not clone.valid,"replaced NPC with copied tags is rejected");s:advance(14);check(s:phase()==4,"replacement cannot satisfy progress");

s=world();s:start();s:boss():Depop();s:advance(14);check(s:phase()==4,"unexpected boss depop has independent recovery");

s=world();s:start();s:openBoss();for _,n in ipairs(s:minis())do s:kill(n);end;s:advance(20);local nextWave=s:state()[8];s:load();s:advance(1);
check(s:phase()==3 and s:state()[8]==nextWave,"final reinforcement schedule survives reload");

s=world({strictLists=true});s:start();s:advance(2);check(s:phase()==1 and #s:fiends()==25,"forced collection cannot invalidate watchdog NPC/client lists");
first=s:fiends()[1];first:Depop();s:advance(14);check(s:phase()==4 and #s:actors()==0,"forced-collection cleanup remains safe");

s=world({guild=1});s:start();s:boss():Depop();s:advance(14);s.quakeOpen=true;s.points[365647].enabled=true;s:spawnNative(365647);
check(s:phase()==0 and s:boss()and s.points[GUARDIAN].npc,"native Guild 1 quake boss supersedes old retry state");

s=world({boss=false,guardian=false,nativeDelay=400000});local nativeDeadline=s.points[365647].deadline;s:load();s:advance(14);
check(s.points[365647].deadline==nativeDeadline and s.updates[365647]==nil,"unknown native boss reuse is preserved");

s=world();s:start();s:killFiends();s:advance(10);for _,n in ipairs(s:actors())do n:Depop();end;s:boss():Depop();s:load();s:advance(14);
check(s:phase()==4,"zone restart cannot adopt unverified progress or remove original deadline");

print(checks.." Coirnav recovery, scheduling, ownership and RP checks passed.");
