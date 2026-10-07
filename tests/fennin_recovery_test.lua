local InstallProjectionFixture = assert(loadfile((arg[1] or ".") .. "/tests/flagger_test_fixture.lua"))();
-- Run with Lua 5.1: lua tests/fennin_recovery_test.lua /path/to/Quests
local root=arg[1] or ".";
local source=rawget(_G,"FENNIN_TEST_SOURCE");
if not source then local f=assert(io.open(root.."/pofire/encounters/Fennin.lua"));source=f:read("*a");f:close();end
local checks=0;
local function check(ok,text) assert(ok,text);checks=checks+1;end
local function iterator(list) local i=0;return function() i=i+1;return list[i];end end
local TYPES={[217417]=true,[217418]=true,[217419]=true,[217420]=true,[217421]=true,[217422]=true,
 [217425]=true,[217426]=true,[217453]=true,[217427]=true,[217432]=true,[217433]=true,[217429]=true,[217428]=true,[217440]=true};
local GUARDIAN=367088;
local PREFIX="All of Doomfire trembles as the voice of Fennin Ro booms, ";
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
        function p:Disable(depop)self.enabled=false;if depop~=false and live(self.npc)then self.npc:Depop();end end
        function p:SetTimer(ms)self.deadline=s.now+ms/1000;end
        function p:NPCPointerValid()return live(self.npc);end
        s.points[id]=p;return p;
    end
    point(GUARDIAN,217050,true,options.nativeDelay or 496800);
    for id=369529,369538 do point(id,217430,false,360);end
    local function npc(typ,spawnid,x,y,z,h)
        s.uid=s.uid+1;local n={valid=true,uid=s.uid,typ=typ,spawnid=spawnid or 0,hp=100,vars={},x=x or 0,y=y or 0,z=z or 0,h=h or 0};
        function n:GetID()return self.uid;end;function n:GetNPCTypeID()return self.typ;end
        function n:GetSpawnPointID()return self.spawnid;end;function n:GetHP()return self.hp;end
        function n:IsCorpse()return self.corpse or false;end;function n:IsEngaged()return self.engaged or false;end
        function n:GetCleanName()return "NPC "..self.typ;end
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
    if options.guardian~=false then npc(217050,GUARDIAN);end
    npc(217068,0);
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
            if typ==217454 and s.throwProjection then error("projection fault");end
            if typ==217454 and s.failProjection then return {valid=false};end
            local n=npc(typ,0,x,y,z,h);if typ==217454 then s.projection=s.projection+1;end;s:dispatch("spawn",n);return n;
        end,
        signal=function(typ,sig)for _,n in pairs(s.npcs)do if n.typ==typ and live(n)then s:dispatch("signal",n,{signal=sig});end end end,
        register_npc_event=function(_,event,typ,handler)s.handlers[event..":"..typ]=handler;end
    };
    function s:load()
        self.handlers={};for k,t in pairs(self.timers)do if t.owner.encounter then self.timers[k]=nil;end end
        self.encounter={uid="enc"..tostring(self.uid),encounter=true};self.uid=self.uid+1;
        env=setmetatable({eq=eqmock,os={time=function()return math.floor(s.now);end},Event={spawn="spawn",combat="combat",death_complete="death",signal="signal",timer="timer"}},{__index=_G});
        InstallProjectionFixture(env,root);
        local chunk=assert(loadstring(source));setfenv(chunk,env);chunk();self.env=env;
        self.owner=self.encounter;env.event_encounter_load({encounter=self.encounter});self.owner=nil;
    end
    function s:state()
        local value=self.saved["fennin-recovery-v1-"..self.guild]or"0|0|17500|0|0|1|0|0|";local f={};
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
            for id,p in pairs(self.points)do if p.enabled and not live(p.npc)and p.deadline<=target and not(self.guild==1 and id==GUARDIAN and not self.quakeOpen)then
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
    function s:warnings()
        local out={};for _,e in ipairs(self.rp)do if e.text:sub(1,#PREFIX)==PREFIX and e.text:find("Norrathians! Your hunger",1,true)or
            e.text:sub(1,#PREFIX)==PREFIX and (e.text:find("You presume",1,true)or e.text:find("The balance of power will not bend to your greed",1,true)or e.text:find("Hear the roar",1,true)or e.text:find("My restraint",1,true)or e.text:find("Your time dwindles",1,true))then out[#out+1]=e;end end;return out;
    end
    function s:fennin()self:killStage();self:killStage();self:killStage();return self:actors()[1];end
    return s;
end

local s=world();s:start();check(s:phase()==1 and #s:actors()==41,"first army has 41 individually tracked NPCs");
check(tonumber(s:state()[3])==17500,"original shared clock begins once");
local first=s:actors()[1];s:kill(first);local kills=s:state()[8];s:dispatch("death",first,{killer=s.clients[1]});
check(s:state()[8]==kills and s:phase()==1,"duplicate death cannot count twice");
local foreign=s.npc(first.typ);s:dispatch("death",foreign,{killer=s.clients[1]});check(s:state()[8]==kills,"untracked kill cannot advance");foreign:Depop();
s:killStage();check(s:phase()==2 and #s:actors()==20,"second army has 20 NPCs including its four commanders");
s:killStage();check(s:phase()==3 and #s:actors()==4,"confirmed second-wave deaths summon the Council");
s:killStage();check(s:phase()==4 and #s:actors()==1,"all four Council deaths summon Fennin");
check(tonumber(s:state()[3])==17500,"phase changes and Fennin spawn do not extend budget");
s:advance(1);local elites=0;for _,n in pairs(s.npcs)do if n.typ==217430 and n.valid and n.hp>0 then elites=elites+1;end end
check(elites==10,"Fennin stage enables all ten elite spawnpoints");
local boss=s:actors()[1];s:engage(boss,true);local combatBudget=tonumber(s:state()[3]);s:advance(3600);check(tonumber(s:state()[3])==combatBudget-3600,"Fennin combat consumes the shared clock");
s:kill(boss);check(s:phase()==6 and s:state()[8]=="66","final kill durably records success and all 66 confirmed deaths");
check(s.updates[GUARDIAN]==496800000 and s.projection==1,"success retains 138-hour Guardian reuse and projection");
check(#s:actors()==0 and not s.points[369529].enabled,"success cleans living event mobs and disables elites");
check(first.valid and first.corpse,"cleanup preserves loot corpses");
for _,e in ipairs(s.rp)do check(e.color==13,"all player RP must be red");check(not e.text:lower():find("mortals",1,true),"RP uses Norrathians");check(not e.text:find('\\',1,true),"RP must not expose string escapes");end
check(#s.gm>0 and #s.player==0,"technical messages go only to GMs");for _,e in ipairs(s.gm)do check(e.color==15,"GM diagnostics must be yellow");end
local rpCount=#s.rp;s:load();s:advance(1);check(s:phase()==6 and s.projection==1 and #s.rp==rpCount,"success reload does not replay victory or projection");

s=world();s:start();first=s:actors()[1];s:kill(first);s:advance(120);local budget=s:state()[3];s:load();s:advance(1);
check(s:phase()==1 and s:state()[8]=="1" and #s:actors()==40,"quest reload restores phase and confirmed deaths");
check(tonumber(s:state()[3])<=tonumber(budget),"reload cannot reset the attempt budget");
s:dispatch("death",first,{killer=s.clients[1]});check(s:state()[8]=="1","reload retains duplicate-kill protection");s:killStage();check(s:phase()==2,"reloaded wave advances only after remaining confirmed deaths");

s=world();s:start();first=s:actors()[1];first:Depop();s:killStage();check(s:phase()==1,"a disappeared actor cannot be counted as killed");
s:advance(12);check(s:phase()==5 and #s:actors()==0,"missing NPC causes cleanup and failure after grace");
check(s.updates[GUARDIAN]<=64800000 and s.updates[GUARDIAN]>64700000,"failure retains the 18-hour recovery window");
local deadline=s:state()[7];s:spawnNative(GUARDIAN);check(s:state()[7]==deadline and not s.points[GUARDIAN].npc,"early Guardian cannot bypass or extend cooldown");
s.points[GUARDIAN].enabled=false;s:advance(1);check(s.points[GUARDIAN].enabled and s:state()[7]==deadline,"disabled Guardian spawnpoint is repaired without extending cooldown");
s:load();s:advance(1);check(s:phase()==5 and s:state()[7]==deadline,"failure cooldown survives quest reload");
s:jump(64801);s:advance(1);check(s:phase()==0 and s.points[GUARDIAN].npc,"cooldown expiry returns a native Guardian and readiness");
s:kill(s.points[GUARDIAN].npc);check(s:phase()==1 and s:state()[2]=="2","next Guardian kill begins a fresh attempt");
s:dispatch("death",first,{killer=s.clients[1]});check(s:state()[8]=="0","old attempt death cannot count in the new attempt");

s=world();s:start();local controller;for _,n in pairs(s.npcs)do if n.typ==217068 then controller=n;end end;controller:Depop();s:advance(12);
check(s:phase()==1 and tonumber(s:state()[3])<17500,"controller depop cannot stop supervision or deadline");

s=world();s:start();first=s:actors()[1];first:Depop();local clone=s.npc(first.typ);for k,v in pairs(first.vars)do clone.vars[k]=v;end
s:dispatch("spawn",clone);check(not clone.valid,"replacement with copied tags is rejected by entity identity");s:advance(12);check(s:phase()==5,"replacement cannot rescue unconfirmed progress");

s=world();s.failType=217418;s:start();check(s:phase()==5 and #s:actors()==0,"spawn failure rolls back the partial phase and schedules recovery");

s=world();s:start();local missing=s.points[GUARDIAN];s.points[GUARDIAN]=nil;s:advance(1);check(s:phase()==5,"missing Guardian spawnpoint fails safely");
local untilTime=s:state()[7];s:advance(30);s.points[GUARDIAN]=missing;missing.enabled=false;s:advance(1);
check(s.points[GUARDIAN].enabled and s:state()[7]==untilTime,"restored Guardian spawnpoint resumes original recovery deadline");

s=world();s:start();s:advance(2699);check(#s:warnings()==0,"first warning is not early");s:advance(1);check(#s:warnings()==1,"first warning fires at 45 minutes");
for i=2,6 do s:advance(2700);check(#s:warnings()==i,"six warnings follow the shared clock");end
check(s:warnings()[4].text:find("Flame and Chaos answer to me!",1,true),"approved fourth warning retained");
check(s:warnings()[6].text:find("Soon the flames of Doomfire shall consume you!",1,true),"approved final warning retained");
s:advance(1300);check(s:phase()==5,"clock expires at 4h 51m 40s");rpCount=#s:warnings();s:advance(3600);check(#s:warnings()==rpCount,"no warnings continue during cooldown");

s=world();s:start();boss=s:fennin();s:advance(2100);s:engage(boss,true);local combatBudget=tonumber(s:state()[3]);s:advance(7200);
check(tonumber(s:state()[3])==combatBudget-7200 and #s:warnings()==3,"Fennin combat consumes budget and emits scheduled warnings");
local beforeReload=tonumber(s:state()[3]);s:load();s:advance(6);
check(s:phase()==4 and tonumber(s:state()[3])==beforeReload-6 and s:state()[5]=="0","combat reload continues the same running clock");
s:engage(boss,false);s:advance(5);check(tonumber(s:state()[3])==beforeReload-11,"leaving combat never extends the budget");

s=world();s:start();boss=s:fennin();s:engage(boss,true);local legacy=s:state();legacy[5]="1";
s.saved["fennin-recovery-v1-66"]=table.concat(legacy,"|");s.now=s.now+60;s:load();s:advance(1);
check(s:phase()==4 and tonumber(s:state()[3])==tonumber(legacy[3])-61 and s:state()[5]=="0","old paused saves migrate without stopping or resetting the clock");

s=world();s:start();s:engage(s:actors()[1],true);s:advance(2700);
check(#s:warnings()==1 and s:state()[5]=="0","army combat cannot pause warnings or event clock");

s=world();s:start();boss=s:fennin();s:advance(17499);s:engage(boss,true);s:advance(1);
check(s:phase()==5 and s:state()[3]=="0" and #s:actors()==0,"clock expiry fails and cleans up even during Fennin combat");

s=world();s:start();boss=s:fennin();s:engage(boss,true);s.now=s.now+17500;s:kill(boss);
check(s:phase()==5 and s.projection==0,"a killing blow at expiry cannot bypass the hard deadline before the watchdog runs");

s=world();s:start();boss=s:fennin();s:engage(boss,true);s:advance(17499);s:kill(boss);
check(s:phase()==6 and s.projection==1,"a killing blow before the deadline still awards victory");

s=world();s:start();boss=s:fennin();s.throwProjection=true;s:kill(boss);
check(s:phase()==6 and s.updates[GUARDIAN]==496800000,"projection error cannot replace successful reuse with short failure cooldown");
s:load();s:advance(1);check(s:phase()==6,"durable final kill survives callback fault and reload");

s=world({guild=1});s:start();first=s:actors()[1];first:Depop();s:advance(12);check(s:phase()==5,"Guild 1 failure initially records recovery");
s.quakeOpen=true;s.points[GUARDIAN].enabled=true;s:spawnNative(GUARDIAN);
check(s:phase()==0 and s.points[GUARDIAN].npc,"native Guild 1 quake Guardian supersedes old cooldown");

s=world({guardian=false,nativeDelay=400000});local oldDeadline=s.points[GUARDIAN].deadline;s:load();s:advance(12);
check(s:phase()==0 and s.points[GUARDIAN].deadline==oldDeadline and s.updates[GUARDIAN]==nil,"unknown native Guardian countdown is preserved");

s=world({guardian=false,nativeDelay=400000});s.saved["fennin-recovery-v1-66"]="bad-state";oldDeadline=s.points[GUARDIAN].deadline;s:load();s:advance(12);
check(s.points[GUARDIAN].deadline==oldDeadline and s.updates[GUARDIAN]==nil,"malformed state cannot shorten an unknown native cooldown");

s=world();s:start();s:advance(2700);local warningsBefore=#s:warnings();s:load();s:advance(1);
check(#s:warnings()==warningsBefore,"reload cannot repeat an already emitted warning");

s=world();s:start();first=s:actors()[1];s:kill(first);local saved=s.saved["fennin-recovery-v1-66"];
-- Simulate a full-zone restart: saved progress remains but tagged actors do not.
for _,n in ipairs(s:actors())do n:Depop();end;s:load();s:advance(12);
check(s:phase()==5,"zone restart cannot silently rebuild or skip an unverified army");


s=world();s:start();local guardCorpse;for _,n in pairs(s.npcs)do if n.typ==217050 then guardCorpse=n;break;end end
s:dispatch("death",guardCorpse,{killer=s.clients[1]});
check(s:phase()==1 and not s.points[GUARDIAN].enabled and s.updates[GUARDIAN]==nil,"duplicate Guardian death cannot rearm or restart active encounter");
first=s:actors()[1];check(first.x==-588 and first.y==-1621,"original Y/X spawn coordinates are preserved");
check(math.abs(first.h-329.0625*0.7)<0.00001,"original spawn heading conversion is preserved");

s=world();s:start();local f=s:state();f[9]=f[9]:gsub("^1:(%d+):(%d+):","1:%1:0:");
s.saved["fennin-recovery-v1-66"]=table.concat(f,"|");for _,n in ipairs(s:actors())do n:Depop();end;s:load();s:advance(1);
check(s:phase()==5 and s.points[GUARDIAN].enabled,"interrupted zero-entity phase cannot strand a disabled Guardian");
check(s.updates[GUARDIAN]<=64800000,"interrupted phase uses the existing failure recovery");

s=world();s:start();boss=s:fennin();s:kill(boss);local terminalUntil=s:state()[7];f=s:state();f[9]="broken-record";
s.saved["fennin-recovery-v1-66"]=table.concat(f,"|");s:load();s:advance(1);
check(s:phase()==6 and s:state()[7]==terminalUntil,"valid success header preserves full cooldown despite damaged phase records");
check(s.projection==1,"terminal recovery does not create duplicate projection");

s=world();s:start();boss=s:fennin();s:engage(boss,true);local missingBudget=s:state()[3];boss:Depop();s:advance(12);
check(s:phase()==5,"missing Fennin still triggers failure recovery");
check(tonumber(s:state()[3])<tonumber(missingBudget),"clock keeps running while missing Fennin is investigated");

s=world();s:start();s:killStage();s:killStage();s.points[369530]=nil;s:killStage();
check(s:phase()==5 and #s:actors()==0,"missing elite spawnpoint recovers instead of leaving an incomplete final stage");

s=world();s:start();local foreignGuardian=s.npc(217050,0);s:kill(foreignGuardian);
check(s:phase()==1 and s:state()[2]=="1","foreign Guardian cannot advance or reset the actual encounter");


s=world({guild=1});local legacy=s.npc(217417,0);s:load();s:advance(1);
check(s:phase()==0 and s.points[GUARDIAN].npc,"fresh Guild 1 native Guardian remains admitted without a saved bucket");
check(not legacy.valid and s.updates[GUARDIAN]==nil,"legacy actors cannot convert a native Guild 1 quake into a failure cooldown");


s=world();s:start();first=s:actors()[1];local originalEntity=first.uid;s:kill(first);
check(first:GetID()==0 and first:GetEntityVariable("fennin_entity")==tostring(originalEntity),"death fixture matches cleared live ID with retained spawn tag");
check(s:state()[8]=="1","zero-ID completed death is credited exactly once");
s:advance(12);check(s:phase()==1,"a valid corpse-producing kill cannot trigger missing-NPC recovery");
local original=s:actors()[1];local impostor=s.npc(original.typ);for k,v in pairs(original.vars)do impostor.vars[k]=v;end
local beforeKills=s:state()[8];s:dispatch("death",impostor,{killer=s.clients[1]});
check(s:state()[8]==beforeKills,"a different live entity with copied tags remains rejected");impostor:Depop();


s=world({strictLists=true});s:start();collectgarbage("collect");s:advance(2);
check(s:phase()==1 and #s:actors()==41,"forced garbage collection cannot invalidate NPC list iteration or watchdog handles");
s:killStage();check(s:phase()==2 and #s:actors()==20,"phase transition survives borrowed-list lifetime stress");
first=s:actors()[1];first:Depop();s:advance(12);
check(s:phase()==5 and #s:actors()==0,"failure cleanup survives forced list garbage collection");
check(#s.gm>0 and #s.player==0,"GM-only logging safely retains its client list owner");

print(checks.." Fennin recovery, timer, RP and GM-visibility checks passed.");
