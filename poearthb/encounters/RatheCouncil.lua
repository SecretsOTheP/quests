-- Shared Rathe Council / Avatar progression. Native Council combat mechanics
-- remain in A_Rathe_Councilman.lua; this encounter owns deaths and recovery.
local MEZABLE, UNMEZABLE, AVATAR, PROJECTION = 222003,222039,222040,222041;
local POINTS = {369377,369380,369382,369384,369386,369387,369376,369378,369379,369381,369383,369385};
local TYPES={};for i,id in ipairs(POINTS)do TYPES[id]=i<=6 and MEZABLE or UNMEZABLE;end
local COUNCIL_RESPAWN, COUNCIL_WINDOW, AVATAR_IDLE, FAILURE, SUCCESS = 420,3600,2100,900,496800;
local MISSING_GRACE, WATCHDOG_MS = 10,1000;
local names={[0]="Ready","Council","Avatar","Retry","Success"};
local phase,attempt,remaining,clockAt,paused,cooldownUntil,avatarID,nextWarning=0,0,AVATAR_IDLE,0,false,0,0,1;
local councilStarted=0;
local records,missing,notices={},{},{};
local initialized,creatingAvatar,cooldownArmed,readyAnnounced=false,false,false,false;
local encounter,lastSave;
local stateKey="rathe-recovery-v1-"..tostring(eq.get_zone_guild_id());
local Initialize,Fail,Watchdog;
local function Now()return os.time();end
local function Live(n)return n and n.valid and n:GetID()~=0 and n:GetHP()>0 and not n:IsCorpse();end
local function InInstance()return eq.get_zone_guild_id()~=-1;end
local function GuildOne()return eq.get_zone_guild_id()==1;end
local function RP(text)eq.zone_emote(13,text);end
local function Log(kind,text)
    local message=string.format("[Rathe guild=%s attempt=%d phase=%s] [%s] %s",tostring(eq.get_zone_guild_id()),attempt,names[phase]or"Unknown",kind,text);
    eq.debug(message);
    local list=eq.get_entity_list():GetClientList();
    for client in list.entries do if client.valid and client:GetGM()then client:Message(15,message);end end
end
local function Notice(key,kind,text)
    if not notices[key]or Now()-notices[key]>=30 then notices[key]=Now();Log(kind,text);end
end
local function Point(id)
    local p=eq.get_entity_list():GetSpawnByID(id);if p and p.valid then return p;end
end
local function NPCIDs()
    local list=eq.get_entity_list():GetNPCList();local ids={};
    for npc in list.entries do if npc.valid then local id=npc:GetID();if id~=0 then ids[#ids+1]=id;end end end
    return ids;
end
local function EmptyRecords()
    records={};for _,id in ipairs(POINTS)do records[id]={entity=0,status=0,deathAt=0};end
end
local function Save(force)
    if not InInstance()or(not force and lastSave and Now()-lastSave<5)then return;end
    local rows={};for _,id in ipairs(POINTS)do local r=records[id]or{entity=0,status=0,deathAt=0};rows[#rows+1]=table.concat({id,TYPES[id],r.entity,r.status,r.deathAt},":");end
    eq.set_data(stateKey,table.concat({phase,attempt,remaining,clockAt,paused and 1 or 0,cooldownUntil,avatarID,nextWarning,councilStarted,table.concat(rows,";")},"|"));lastSave=Now();
end
local function Load()
    local raw=eq.get_data(stateKey);if not raw or raw==""then return false;end
    local fields={};for part in(raw.."|"):gmatch("(.-)|")do fields[#fields+1]=part;end
    local h={};for i=1,9 do h[i]=tonumber(fields[i]);end
    local fallback;
    if h[1]and h[1]>=0 and h[1]<=4 and h[1]==math.floor(h[1])and h[2]and h[2]>=0 and h[2]==math.floor(h[2])and h[6]and h[6]>0 and h[6]==math.floor(h[6])then
        fallback={phase=h[1],attempt=h[2],untilTime=h[6]};
    end
    for i=1,9 do if not h[i]or h[i]<0 or h[i]~=math.floor(h[i])then return false,"Invalid saved header",fallback;end end
    if h[1]>4 or h[3]>AVATAR_IDLE or h[5]>1 or h[8]<1 or h[8]>4 then return false,"Invalid saved phase/clock",fallback;end
    fallback=fallback or{phase=h[1],attempt=h[2],untilTime=h[6]};
    if (h[1]==3 or h[1]==4)and h[6]==0 then return false,"Missing terminal deadline";end
    if #fields~=10 then return false,"Invalid saved field count",fallback;end
    if h[1]==1 and(h[9]==0 or h[9]>Now())then return false,"Invalid Council deadline",fallback;end
    local loaded={};local count=0;
    for part in fields[10]:gmatch("[^;]+")do
        local id,typ,entity,status,deathAt=part:match("^(%d+):(%d+):(%d+):(%d+):(%d+)$");
        id,typ,entity,status,deathAt=tonumber(id),tonumber(typ),tonumber(entity),tonumber(status),tonumber(deathAt);
        if not id or TYPES[id]~=typ or loaded[id]or status>2 then return false,"Invalid saved Council member",fallback;end
        if status~=0 and deathAt==0 then return false,"Missing recorded death time",fallback;end
        loaded[id]={entity=entity,status=status,deathAt=deathAt};count=count+1;
    end
    if count~=#POINTS then return false,"Incomplete saved Council",fallback;end
    phase,attempt,remaining,clockAt,paused,cooldownUntil,avatarID,nextWarning=h[1],h[2],h[3],h[4],h[5]==1,h[6],h[7],h[8];records=loaded;councilStarted=h[9];
    return true;
end
local function ArmSupervisor()eq.set_timer("watchdog",WATCHDOG_MS,encounter);end
local function Tag(n,point)
    n:SetEntityVariable("rathe_attempt",tostring(attempt));n:SetEntityVariable("rathe_point",tostring(point));n:SetEntityVariable("rathe_entity",tostring(n:GetID()));
end
local function Tagged(n,point,entity,death)
    if not n or not n.valid then return false;end
    local id=n:GetID();return (id==entity or(death and id==0))and
        n:GetEntityVariable("rathe_attempt")==tostring(attempt)and n:GetEntityVariable("rathe_point")==tostring(point)and n:GetEntityVariable("rathe_entity")==tostring(entity);
end
local function Avatar()
    local n=eq.get_entity_list():GetNPCByID(avatarID);if Live(n)and n:GetNPCTypeID()==AVATAR and Tagged(n,0,avatarID,false)then return n;end
end
local function Cleanup()
    local el=eq.get_entity_list();
    for _,id in ipairs(NPCIDs())do local n=el:GetNPCByID(id);if Live(n)and(n:GetNPCTypeID()==AVATAR or n:GetNPCTypeID()==MEZABLE or n:GetNPCTypeID()==UNMEZABLE)then n:Depop();end end
end
local function CleanupAvatar()
    local el=eq.get_entity_list();for _,id in ipairs(NPCIDs())do local n=el:GetNPCByID(id);if Live(n)and n:GetNPCTypeID()==AVATAR then n:Depop();end end
end
local function ApplyCooldown()
    local complete=true;local ms=math.max(1,(cooldownUntil-Now())*1000);
    for _,id in ipairs(POINTS)do local p=Point(id);
        if not p then complete=false;Notice("point-"..id,"ERROR","Missing Council spawnpoint "..id.."; recovery will retry.");
        elseif not GuildOne()then eq.update_spawn_timer(id,ms);p:SetTimer(ms);p:Enable();end
    end
    cooldownArmed=complete;Notice("cooldown-reset","RESET",GuildOne()and"Council cleanup complete; native Guild 1 earthquake admission remains in control."or string.format("All Council spawnpoints enabled; recovery remaining %.1f minutes.",math.max(0,cooldownUntil-Now())/60));
end
Fail=function(reason)
    if not InInstance()then Notice("outside","WARN","Ignored recovery outside a guild instance.");return;end
    if phase==3 or phase==4 then return;end
    phase=3;cooldownUntil=Now()+FAILURE;paused=false;missing={};Save(true);Cleanup();ApplyCooldown();ArmSupervisor();
    RP("The ground shifts as the Rathe Council speaks with one unwavering voice. \"Your advance cannot be allowed to continue, Norrathians. We shall rise again and preserve the balance of these planes.\" Stone gathers once more beneath the halls of Ragrax.");
    Log("FAIL",reason.."; recorded deaths cleared when a fresh Council returns. Retry remains fifteen minutes.");
end
local function StartReady(announce)
    phase=0;attempt=attempt+1;remaining=AVATAR_IDLE;clockAt=Now();paused=false;cooldownUntil=0;avatarID=0;nextWarning=1;councilStarted=0;missing={};notices={};readyAnnounced=false;cooldownArmed=false;EmptyRecords();Save(true);
    if announce then Log("RETURN","Native Council has begun returning; waiting for all twelve.");end
end
local function Adopt(n)
    local id=n:GetSpawnPointID();if TYPES[id]~=n:GetNPCTypeID()then return false;end
    local r=records[id];if not r then return false;end
    local wasDead=r.status~=0;
    if r.entity~=n:GetID()or not Tagged(n,id,r.entity,false)then
        r.entity=n:GetID();r.status=0;r.deathAt=0;Tag(n,id);missing[id]=nil;Save(true);
        if wasDead then RP("Stone knits together as a fallen Councilman rises anew. The Council speaks as one: \"We stand together, Norrathians. We shall not yield because one has fallen.\"");Log("RETURN","Councilman "..id.." returned; its old death no longer counts.");end
    end
    return true;
end
local function CountDeaths()
    local count=0;for _,id in ipairs(POINTS)do if records[id].status==1 then count=count+1;end end;return count;
end
local function AllKnown()
    for _,id in ipairs(POINTS)do if records[id].entity==0 and records[id].status==0 then return false;end end;return true;
end
local function AllPresent()
    for _,id in ipairs(POINTS)do local p=Point(id);local n=p and p:GetNPC();local r=records[id];
        if not Live(n)or TYPES[id]~=n:GetNPCTypeID()or r.status~=0 or not Tagged(n,id,r.entity,false)then return false;end
    end;return true;
end
local function ReconcileCouncil()
    for _,id in ipairs(POINTS)do
        local p=Point(id);if not p then Fail("Council spawnpoint "..id.." disappeared");return;end
        local n=p:GetNPC();local r=records[id];
        if Live(n)then
            if TYPES[id]~=n:GetNPCTypeID()then Fail("Council spawnpoint "..id.." contains the wrong NPC type");return;end
            if r.status==0 and r.entity~=0 and not Tagged(n,id,r.entity,false)then Fail("Live Councilman "..id.." was replaced without a recorded death");return;end
            Adopt(n);
        elseif r.status==0 and r.entity~=0 then
            missing[id]=missing[id]or Now();if Now()-missing[id]>=MISSING_GRACE then Fail("Councilman "..id.." disappeared without a confirmed kill");return;end
        elseif r.status==1 and not GuildOne()and Now()>=r.deathAt+COUNCIL_RESPAWN then
            r.status=2;r.entity=0;Save(true);eq.update_spawn_timer(id,1);p:SetTimer(1);p:Enable();
            Log("EXPIRE","Seven-minute kill credit expired for Councilman "..id.."; waiting for its return.");
        end
    end
end
local function Clock()
    if phase~=2 then return;end
    local now=Now();if not paused then remaining=math.max(0,remaining-math.max(0,now-clockAt));end;clockAt=now;
end
local function ArmCombat(n)
    if n:GetNPCTypeID()==UNMEZABLE then eq.set_timer("checkhp",3000,n);end
    if n:IsEngaged()then
        eq.set_timer("teleport",60000,n);
        if n:GetNPCTypeID()==MEZABLE then eq.set_timer("check_mez",1000,n);end
    end
end
local function HoldCouncil()
    for _,id in ipairs(POINTS)do local p=Point(id);if not p then return false;end
        if not GuildOne()then eq.update_spawn_timer(id,SUCCESS*1000);p:Disable(false);end
    end;return true;
end
local function SpawnAvatar()
    local el=eq.get_entity_list();
    for _,id in ipairs(NPCIDs())do local n=el:GetNPCByID(id);if Live(n)and(n:GetNPCTypeID()==MEZABLE or n:GetNPCTypeID()==UNMEZABLE or n:GetNPCTypeID()==AVATAR)then Fail("Unexpected live Council/Avatar prevented the final transition");return;end end
    phase=2;remaining=AVATAR_IDLE;clockAt=Now();paused=false;avatarID=0;nextWarning=1;Save(true);
    if not HoldCouncil()then Fail("Cannot hold every Council spawnpoint for the Avatar phase");return;end
    creatingAvatar=true;local ok,n=pcall(eq.unique_spawn,AVATAR,0,0,2050,410,-210,0);creatingAvatar=false;
    if not ok or not Live(n)or n:GetNPCTypeID()~=AVATAR or not Tagged(n,0,n:GetID(),false)then Fail("Avatar spawn failed or returned an untracked NPC");return;end
    avatarID=n:GetID();Save(true);ArmSupervisor();
    RP("The Rathe speak through the towering Avatar of Earth: \"We remain as one while battle is joined. We shall tolerate a half-hour of hesitation, and five minutes more. No more.\"");
    Log("PHASE","All twelve current Council deaths confirmed; Avatar spawned. Its idle budget is 35 minutes, paused only during its combat.");
end
local function CouncilSpawn(e)
    ArmSupervisor();if not InInstance()then return;end
    if not initialized then Initialize();end
    if TYPES[e.self:GetSpawnPointID()]~=e.self:GetNPCTypeID()then e.self:Depop();Notice("foreign-council","WARN","Suppressed Council NPC outside its native spawnpoint.");return;end
    if GuildOne()and phase~=0 and not Tagged(e.self,e.self:GetSpawnPointID(),e.self:GetID(),false)then
        CleanupAvatar()
        StartReady(true);Log("QUAKE","Native Guild 1 Council spawn admitted a new round.");
    end
    if phase==3 or phase==4 then
        if Now()<cooldownUntil then e.self:Depop();ApplyCooldown();Notice("early-council","WARN","Suppressed an early Council spawn without extending the deadline.");return;end
        StartReady(true);
    elseif phase==2 then e.self:Depop();HoldCouncil();Notice("active-council","WARN","Suppressed Council respawn during the Avatar phase.");return;end
    local id=e.self:GetSpawnPointID();local r=records[id];
    if r.entity~=0 and r.status==0 and not Tagged(e.self,id,r.entity,false)then
        if phase==0 then StartReady(false);else Fail("Councilman "..id.." was replaced during an active round");return;end
    end
    Adopt(e.self);ArmCombat(e.self);
end
local function CouncilCombat(e)
    ArmSupervisor();if not InInstance()then return;end;if not initialized then Initialize();end
    local id=e.self:GetSpawnPointID();local r=records[id];if not r or not Tagged(e.self,id,r.entity,false)then return;end
    if phase==0 and e.joined and AllKnown()then phase=1;councilStarted=Now();nextWarning=1;Save(true);RP("The stone beneath Ragrax trembles as the Rathe Council speaks as one: \"We shall not remain divided beyond the passing of an hour. The balance must be restored.\"");Log("ENGAGE","Council round engaged; sixty-minute running deadline started. Confirmed deaths share one counter.");end
end
local function CouncilDeath(e)
    ArmSupervisor();if not InInstance()then return;end;if not initialized then Initialize();end
    local id=e.self:GetSpawnPointID();local r=records[id];
    if phase~=0 and phase~=1 then Notice("late-death","WARN","Ignored Council death outside the Council phase.");return;end
    if not r or r.status~=0 or not Tagged(e.self,id,r.entity,true)or e.self:GetNPCTypeID()~=TYPES[id]then Notice("stale-death","WARN","Ignored duplicate/stale/untracked Council death.");return;end
    if not AllKnown()then Fail("Council killed before all twelve members were admitted");return;end
    if phase==1 and Now()>=councilStarted+COUNCIL_WINDOW then Fail("Council sixty-minute deadline expired before the confirmed death");return;end
    if phase==0 then councilStarted=Now();nextWarning=1;Log("ENGAGE","Council sixty-minute deadline started by first confirmed death.");end
    phase=1;r.status=1;r.deathAt=Now();missing[id]=nil;Save(true);
    local p=Point(id);if p and not GuildOne()then eq.update_spawn_timer(id,COUNCIL_RESPAWN*1000);p:SetTimer(COUNCIL_RESPAWN*1000);p:Enable();end
    ReconcileCouncil();if phase~=1 then return;end
    local count=CountDeaths();Log("KILL",string.format("Councilman %d confirmed killed; %d/12 current deaths.",id,count));
    if count==1 then RP("One of the Rathe Council crumbles into lifeless stone. The remaining voices answer without hesitation: \"We remain united. We shall rise again. You will not unravel the balance through the fall of one.\"");
    elseif count==6 then RP("Half of the Rathe Council lies broken upon the earth. The remaining Councilmen speak with grave resolve: \"We must stand together. We shall maintain the balance, whatever this defense demands.\"");end
    if count==12 then SpawnAvatar();end
end
local function AvatarSpawn(e)
    ArmSupervisor();if not InInstance()then e.self:Depop();Notice("outside-avatar","WARN","Rejected Avatar spawn outside a guild instance.");return;end
    if creatingAvatar and phase==2 and avatarID==0 then avatarID=e.self:GetID();Tag(e.self,0);Save(true);return;end
    if not initialized then Initialize();end
    if not Live(Avatar())or e.self:GetID()~=avatarID then e.self:Depop();if phase~=3 and phase~=4 then Fail("Untracked or duplicate Avatar appeared");else Notice("foreign-avatar","WARN","Suppressed Avatar during recorded cooldown.");end end
end
local function AvatarCombat(e)
    ArmSupervisor();if not initialized then Initialize();end
    if phase~=2 or not Tagged(e.self,0,avatarID,false)then return;end
    Clock();if remaining==0 then Fail("Avatar's 35-minute idle budget expired");return;end
    paused=e.joined;Save(true);
    Log(paused and"ENGAGE"or"DISENGAGE",string.format("Avatar idle clock %s; %.1f minutes remain.",paused and"paused"or"running",remaining/60));
    if paused then RP("The Avatar of Earth plants its feet upon the stone of Ragrax. The Rathe speak as one through its towering form: \"We stand as one, Norrathians. We cannot permit your ambition to unravel what we are sworn to preserve. Your advance ends here.\"");end
end
local function AvatarDeath(e)
    ArmSupervisor();if not initialized then Initialize();end
    if phase~=2 or not Tagged(e.self,0,avatarID,true)then Notice("stale-avatar-death","WARN","Ignored untracked/duplicate Avatar death.");return;end
    Clock();if remaining==0 then Fail("Avatar idle budget expired before the confirmed death");return;end
    phase=4;cooldownUntil=Now()+SUCCESS;paused=false;Save(true);Cleanup();ApplyCooldown();
    RP("The Avatar of Earth's colossal form fractures and crashes to the ground, shaking Ragrax to its foundations. The voices of the Rathe Council fall silent. Their united power has been overcome, and the Essence of Earth rises from the shattered stone.");
    Log("SUCCESS","Avatar confirmed killed; Council successful reuse and Avatar loot lockout remain 138 hours.");
    local ok,projection=pcall(eq.spawn2,PROJECTION,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0);
    if not ok or not Live(projection)then Log("ERROR","Essence of Earth failed to spawn; recorded success/cooldown retained.");return;end
    if e.killer and e.killer.valid and e.killer:GetID()~=0 then local signaled,err=pcall(eq.signal,PROJECTION,e.killer:GetID());if not signaled then Log("ERROR","Essence kill-rights signal failed: "..tostring(err));end
    else Log("ERROR","Avatar death had no valid kill-rights recipient; Essence spawned but cannot be signaled.");end
end
Initialize=function()
    if initialized then return;end;initialized=true;
    if not InInstance()then EmptyRecords();Notice("outside","WARN","Recovery and Avatar progression are disabled outside guild instances.");return;end
    local loaded,why,fallback=Load();
    if GuildOne()then
        for _,id in ipairs(POINTS)do local p=Point(id);local n=p and p:GetNPC();local r=records[id];
            if Live(n)and TYPES[id]==n:GetNPCTypeID()and(not r or not Tagged(n,id,r.entity,false))then
                if fallback then attempt=fallback.attempt;end
                CleanupAvatar();StartReady(true);loaded=true;Log("QUAKE","Native Guild 1 Council admitted before stale cooldown cleanup.");break;
            end
        end
    end
    if not loaded then
        if fallback and(fallback.phase==3 or fallback.phase==4)then phase=fallback.phase;attempt=fallback.attempt;cooldownUntil=fallback.untilTime;EmptyRecords();Save(true);Cleanup();ApplyCooldown();Log("ERROR",why.."; retained terminal cooldown.");
        elseif why then EmptyRecords();if fallback then attempt=fallback.attempt;end;Fail(why.."; unsafe saved progress reset");
        else StartReady(false);local el=eq.get_entity_list();for _,id in ipairs(NPCIDs())do local n=el:GetNPCByID(id);if Live(n)and n:GetNPCTypeID()==AVATAR then Fail("Untracked pre-recovery Avatar found");break;end end end
    end
    -- Guild 1 fresh-zone/quake admission supersedes old local progress only
    -- when native Council NPCs have actually returned. Never force its timers.
    if loaded and GuildOne()and phase~=0 then
        for _,id in ipairs(POINTS)do local p=Point(id);local n=p and p:GetNPC();local r=records[id];
            if Live(n)and TYPES[id]==n:GetNPCTypeID()and not Tagged(n,id,r.entity,false)then
                CleanupAvatar()
                StartReady(true);Log("QUAKE","Fresh native Guild 1 Council admitted after reload.");break;
            end
        end
    end
    if phase==0 or phase==1 then
        for _,id in ipairs(POINTS)do local p=Point(id);local n=p and p:GetNPC();local r=records[id];
            if Live(n)and TYPES[id]==n:GetNPCTypeID()then
                if r.status==0 and r.entity~=0 and not Tagged(n,id,r.entity,false)then Fail("Reload found replaced Councilman "..id);break;end
                Adopt(n);ArmCombat(n);
            elseif p and not GuildOne()and r.status~=0 then
                local ms=math.max(1,(r.deathAt+COUNCIL_RESPAWN-Now())*1000);
                eq.update_spawn_timer(id,ms);p:SetTimer(ms);p:Enable();
            end
        end
    elseif phase==2 then
        if not Avatar()then Fail("Reload found missing/replaced Avatar");else Clock();HoldCouncil();if remaining==0 then Fail("Avatar idle budget expired across reload");else paused=Avatar():IsEngaged();Save(true);end end
    elseif phase==3 or phase==4 then Cleanup();ApplyCooldown();end
    ArmSupervisor();Log("LOAD","Shared Council deaths, Avatar idle clock and cooldowns persist; encounter supervision is independent of NPC timers.");
end
Watchdog=function()
    if not initialized then Initialize();end;if not InInstance()then return;end
    if phase==0 or phase==1 then
        if phase==1 then
            local elapsed=math.max(0,Now()-councilStarted);
            if elapsed>=COUNCIL_WINDOW then Fail("Council sixty-minute running deadline expired");return;end
            local thresholds={1800,2700,3300};local texts={
                "The voices of the Rathe Council resound through Ragrax, \"Norrathians, this struggle shall not continue without end. We must preserve the balance. We shall soon stand together again; your opportunity is passing.\"",
                "The voices of the Rathe Council resound through Ragrax, \"Your time grows short. We shall stand united again. We will not remain bound to this struggle forever, Norrathians.\"",
                "The voices of the Rathe Council resound through Ragrax, \"We must stand together again. Your final moments are upon you, Norrathians. We shall soon stand together once more.\""
            };
            while thresholds[nextWarning]and elapsed>=thresholds[nextWarning]do RP(texts[nextWarning]);Log("WARNING","Council elapsed "..thresholds[nextWarning]/60 .." of sixty minutes.");nextWarning=nextWarning+1;Save(true);end
        end
        ReconcileCouncil();if phase~=0 and phase~=1 then return;end
        if phase==0 and AllPresent()and not readyAnnounced then readyAnnounced=true;RP("The Rathe Council stands once more within Ragrax. Their voices rise as one: \"We stand united again. We shall not abandon what we are sworn to preserve. The balance of these planes shall be preserved.\"");Log("READY","All twelve native Council members are present; a fresh round can begin.");end
    elseif phase==2 then
        Clock();if remaining==0 then Fail("Avatar's 35-minute idle budget expired");return;end
        local n=Avatar();if not n then missing.avatar=missing.avatar or Now();if Now()-missing.avatar>=MISSING_GRACE then Fail("Avatar disappeared/replaced without a confirmed kill");return;end
        else missing.avatar=nil;paused=n:IsEngaged();end
        local thresholds={900,1500,1800};local texts={
            "Ragrax trembles as the Rathe Council speaks through the Avatar of Earth, \"Norrathians, you do not comprehend the power you seek. We must preserve the balance. We shall bring this advance to an end.\"",
            "Ragrax trembles as the Rathe Council speaks through the Avatar of Earth, \"Your time dwindles, Norrathians. We shall not leave this stronghold exposed to your ambition. Face what we have become.\"",
            "Ragrax trembles as the Rathe Council speaks through the Avatar of Earth, \"This must end now. We shall soon stand together once more. Your final chance is upon you, Norrathians. We will not yield.\""
        };
        while thresholds[nextWarning]and AVATAR_IDLE-remaining>=thresholds[nextWarning]do RP(texts[nextWarning]);Log("WARNING","Avatar idle time elapsed "..thresholds[nextWarning]/60 .." minutes.");nextWarning=nextWarning+1;Save(true);end
        for _,id in ipairs(POINTS)do local p=Point(id);if not p then Fail("Council spawnpoint disappeared during Avatar phase");return;end;local c=p:GetNPC();if Live(c)then c:Depop();HoldCouncil();Notice("active-return","WARN","Suppressed Council return during Avatar without changing its clock.");end end
        Save(false);
    elseif phase==3 or phase==4 then
        local needsRepair=not cooldownArmed;
        for _,id in ipairs(POINTS)do local p=Point(id);if not p or(not GuildOne()and not p:Enabled())then needsRepair=true;break;end end
        if needsRepair then Cleanup();ApplyCooldown();end
        if Now()>=cooldownUntil then Notice("waiting","WARN",GuildOne()and"Cooldown elapsed; awaiting native Guild 1 earthquake admission."or"Cooldown elapsed; awaiting native Council spawns. Spawn conditions may still block them.");end
    end
end
local function LegacySignal(e)Notice("legacy","WARN","Ignored legacy Council kill signal; only confirmed current-generation deaths count.");end
local function Safe(callback)
    return function(e)local ok,err=pcall(callback,e);if not ok then
        Log("ERROR","Lua callback failed: "..tostring(err));local restored,why=pcall(function()
            if phase==3 or phase==4 then Cleanup();Save(true);ApplyCooldown();else Fail("Lua callback error");end;ArmSupervisor();
        end);if not restored then Log("ERROR","Recovery also failed: "..tostring(why));end
    end end;
end
function event_timer(e)
    if e.timer=="initialize"then eq.stop_timer(e.timer);Initialize();elseif e.timer=="watchdog"then Watchdog();end
end
function event_encounter_load(e)
    encounter=e.encounter;
    local function reg(event,typ,callback)eq.register_npc_event("RatheCouncil",event,typ,Safe(callback));end
    for _,typ in ipairs({MEZABLE,UNMEZABLE})do reg(Event.spawn,typ,CouncilSpawn);reg(Event.combat,typ,CouncilCombat);reg(Event.death_complete,typ,CouncilDeath);reg(Event.signal,typ,LegacySignal);end
    reg(Event.spawn,AVATAR,AvatarSpawn);reg(Event.combat,AVATAR,AvatarCombat);reg(Event.death_complete,AVATAR,AvatarDeath);
    eq.set_timer("initialize",1000,encounter);ArmSupervisor();
end
local timer=event_timer;event_timer=Safe(timer);
