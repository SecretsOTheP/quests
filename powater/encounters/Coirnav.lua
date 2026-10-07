--[[
p1.1[Tue Jul 10 22:49:39 2012] Coirnav the Avatar of Water shouts 'Those that violate my domain will pay. I call upon the power imbued to me by Povar! Come forth my minions of vapor and destroy these intruders.'
p1.2[Tue Jul 10 22:52:35 2012] Coirnav the Avatar of Water shouts 'Those that violate my domain will pay. I call upon the power imbued to me by E`ci! Come forth my minions of ice and destroy these intruders.'
p1.3[Tue Jul 10 22:54:33 2012] Coirnav the Avatar of Water shouts 'Those that violate my domain will pay. I call upon the power imbued to me by Tarew Marr! Come forth minions of water and destroy these intruders.'
p2[Tue Jul 10 22:58:06 2012] Coirnav the Avatar of Water shouts 'Fools you have gotten this far but you will not succeed. Pwelon, Nrinda, and Vamuil kill these intruders!'
10m[Tue Jul 10 22:59:26 2012] Coirnav the Avatar of Water is suddenly surrounded by a slight glow. A low constant humming is heard in the background.
12m[Tue Jul 10 23:01:23 2012] Coirnav the Avatar of Water is now glowing noticeably brighter and the constant humming is getting louder.
p3[Tue Jul 10 23:02:43 2012] Coirnav the Avatar of Water shouts 'Defenders of vapor, ice, and water I call thee to my aid.  Destroy the defilers of water.'
14m[Tue Jul 10 23:03:21 2012] Coirnav the Avatar of Water glows to brilliant flash of light that suddenly fades. The constant humming suddenly becomes a deafening roar that also mysteriously fades away.
15m[Tue Jul 10 23:04:20 2012] Coirnav the Avatar of Water shouts 'Violaters of this plane be banished from this domain!'

[Thu Apr  5 21:44:17 2012] The monstrous creature spasms in its last death throes sending shockwaves through the reef.  Corinav the Avatar of Water, empowered by the focus of the Triumvirate, has fallen at the hands of the brave adventurers deep within the reef.
]]
local COIRNAV_TYPE = 216048; -- Coirnav_the_Avatar_of_Water
local GUARDIAN_TYPE = 216053; -- Guardian_of_Coirnav
local PWELON_TYPE = 216236; -- Pwelon_of_Vapor
local NRINDA_TYPE = 216245; -- Nrinda_of_Ice
local VAMUIL_TYPE = 216247; -- Vamuil_of_Water
local VAPORFIEND_TYPE = 216257; -- a_triloun_vaporfiend
local VAPORLING_TYPE = 216256; -- a_triloun_vaporling
local ICEFIEND_TYPE = 216260; -- a_hraquis_icefiend
local ICELING_TYPE = 216259; -- a_hraquis_iceling
local WATERFIEND_TYPE = 216258; -- a_regrua_waterfiend
local WATERLING_TYPE = 216265; -- a_regrua_waterling
local PROJECTION_TYPE = 216266; -- Essence_of_Water
local MONSTROUS_TYPE = 216072; -- The_monstrous

local COIRNAV_SPAWNID = 365647;
local GUARDIAN_SPAWNID = 366321;

local SPAWN_LOCS = {
	{ -829,1017,-501 },
	{ -846,1062,-535 },
	{ -836,1125,-461 },
	{ -795,1108,-523 },
	{ -802,1119,-501 },
	{ -810,1034,-502 },
	{ -898,1041,-523 },
	{ -847,1148,-535 },
	{ -862,1125,-501 },
	{ -798,1067,-501 },
	{ -824,1018,-523 },
	{ -906,1048,-502 },
	{ -870,1141,-523 },
	{ -824,1152,-502 },
	{ -916,1121,-502 },
	{ -835,1075,-461 },
	{ -861,998,-502 },
	{ -863,1100,-535 },
	{ -894,1091,-523 },
	{ -882,1013,-501 },
	{ -837,1145,-523 },
	{ -875,1166,-502 },
	{ -794,1059,-523 },
	{ -884,1145,-535 },
	{ -779,1110,-502 },
};

-- Encounter-owned recovery: an NPC depop cannot remove the deadline.
local EVENT_SECONDS, FAILURE_SECONDS, SUCCESS_SECONDS = 900,600,496800;
local WATCHDOG_MS, MISSING_GRACE = 1000,10;
local FIENDS={VAPORFIEND_TYPE,ICEFIEND_TYPE,WATERFIEND_TYPE};
local MINIS={PWELON_TYPE,NRINDA_TYPE,VAMUIL_TYPE};
local MINI_LOCS={{-860,1065,-480,64},{-877,1095,-480,64},{-860,1120,-480,64}};
local MINI_HP={130000,120000,155000};
local LINGS={[VAPORLING_TYPE]=true,[ICELING_TYPE]=true,[WATERLING_TYPE]=true};
local ACTORS={};for _,t in ipairs(FIENDS)do ACTORS[t]=true;end;for _,t in ipairs(MINIS)do ACTORS[t]=true;end;for t in pairs(LINGS)do ACTORS[t]=true;end
local phaseNames={[0]="Ready","Waves","Minibosses","Final","Retry","Success"};
local phase,attempt,started,deadline,waves,kills,nextWarning,nextLing,cooldownUntil,bossID,cleanupAt=0,0,0,0,0,0,1,0,0,0,0;
local records,missing,notices={},{},{};
local initialized,ownState,released,building=false,false,false,false;
local encounter,creatingSlot,creatingLing;
local cooldownArmed=false;
local stateKey="coirnav-recovery-v1-"..tostring(eq.get_zone_guild_id());
local Fail,Initialize,Advance;
local function Now()return os.time();end
local function Active()return phase>=1 and phase<=3;end
local function Live(n)return n and n.valid and n:GetID()~=0 and n:GetHP()>0 and not n:IsCorpse();end
local function NPCIDs()
    local list=eq.get_entity_list():GetNPCList();local ids={};
    for npc in list.entries do if npc.valid then local id=npc:GetID();if id~=0 then ids[#ids+1]=id;end end end
    return ids;
end
local function RP(text)eq.zone_emote(13,text);end
local function Log(kind,text)
    local message=string.format("[Coirnav guild=%s attempt=%d phase=%s fiends=%d/75] [%s] %s",tostring(eq.get_zone_guild_id()),attempt,phaseNames[phase],kills,kind,text);
    eq.debug(message);local list=eq.get_entity_list():GetClientList();
    for c in list.entries do if c.valid and c:GetGM()then c:Message(15,message);end end
end
local function Notice(key,kind,text)if not notices[key]or Now()-notices[key]>=30 then notices[key]=Now();Log(kind,text);end end
local function Save()
    if not ownState then return;end
    local entries={};for slot,r in ipairs(records)do entries[#entries+1]=table.concat({slot,r.typ,r.entity,r.kind,r.status},":");end
    eq.set_data(stateKey,table.concat({phase,attempt,started,deadline,waves,kills,nextWarning,nextLing,cooldownUntil,bossID,cleanupAt,table.concat(entries,";")},"|"));
end
local function Load()
    local value=eq.get_data(stateKey);if not value or value==""then return false;end
    local f={};for part in(value.."|"):gmatch("(.-)|")do f[#f+1]=part;end
    if #f~=12 then return false,"Malformed saved state";end
    for i=1,11 do if not f[i]:match("^%d+$")then return false,"Non-numeric saved state";end end
    local n={};for i=1,11 do n[i]=tonumber(f[i]);end
    if n[1]>5 or n[5]>3 or n[6]>75 or n[7]<1 or n[7]>4 then return false,"Saved state outside event bounds";end
    local fallback={phase=n[1],attempt=n[2],untilTime=n[9],cleanupAt=n[11]};
    local function bad(text)return false,text,fallback;end
    local restored={};if f[12]~=""then for part in f[12]:gmatch("[^;]+")do
        local slot,t,id,kind,status=part:match("^(%d+):(%d+):(%d+):([123]):([012])$");slot,t,id,kind,status=tonumber(slot),tonumber(t),tonumber(id),tonumber(kind),tonumber(status);
        if not slot or slot~=#restored+1 or id==0 or not ACTORS[t]then return bad("Interrupted or invalid NPC creation");end
        restored[slot]={typ=t,entity=id,kind=kind,status=status};
    end end
    if n[1]>=1 and n[1]<=3 then
        if n[5]<1 or n[10]==0 or n[4]~=n[3]+EVENT_SECONDS then return bad("Invalid active event clock/identity");end
        local expected=n[5]*26+(n[1]>=2 and 3 or 0);
        if #restored~=expected or(n[1]>=2 and(n[5]~=3 or n[6]~=75))then return bad("Saved phase does not match completed wave milestones");end
        local count=0;
        for slot,r in ipairs(restored)do
            if slot<=n[5]*26 then
                local wave=math.floor((slot-1)/26)+1;local offset=(slot-1)%26;
                local typ=offset<25 and FIENDS[wave]or MINIS[wave];local kind=offset<25 and 1 or 2;
                if r.typ~=typ or r.kind~=kind or(kind==1 and r.status==2)then return bad("Saved wave actor differs from its plan");end
                if kind==1 and r.status==1 then count=count+1;end
            elseif r.kind~=3 or r.typ~=MINIS[slot-78]then return bad("Saved miniboss identity differs from its plan");end
        end
        if count~=n[6]then return bad("Saved fiend kill count differs from confirmed deaths");end
    elseif #restored~=0 then return bad("Inactive event retained phase actors");end
    phase,attempt,started,deadline,waves,kills,nextWarning,nextLing,cooldownUntil,bossID,cleanupAt=unpack(n);
    records=restored;ownState=true;return true;
end
local function Tagged(n,r,slot,death)
    return n and n.valid and n:GetNPCTypeID()==r.typ and(n:GetID()==r.entity or(death and n:GetID()==0))and
        n:GetEntityVariable("coirnav_attempt")==tostring(attempt)and n:GetEntityVariable("coirnav_slot")==tostring(slot)and n:GetEntityVariable("coirnav_entity")==tostring(r.entity);
end
local function Tag(n,r,slot)
    r.entity=n:GetID();n:SetEntityVariable("coirnav_attempt",tostring(attempt));n:SetEntityVariable("coirnav_slot",tostring(slot));
    n:SetEntityVariable("coirnav_entity",tostring(r.entity));n:SetEntityVariable("coirnav_counted","0");
end
local function BossPoint()local p=eq.get_entity_list():GetSpawnByID(COIRNAV_SPAWNID);return p and p.valid and p or nil;end
local function GuardianPoint()local p=eq.get_entity_list():GetSpawnByID(GUARDIAN_SPAWNID);return p and p.valid and p or nil;end
local function Boss()
    local p=BossPoint();local n=p and p:GetNPC();return Live(n)and n or nil;
end
local function OwnedBoss(n,death)
    return n and n.valid and n:GetNPCTypeID()==COIRNAV_TYPE and n:GetSpawnPointID()==COIRNAV_SPAWNID and
        (n:GetID()==bossID or(death and n:GetID()==0))and n:GetEntityVariable("coirnav_attempt")==tostring(attempt)and n:GetEntityVariable("coirnav_entity")==tostring(bossID);
end
local function TagBoss(n)bossID=n:GetID();n:SetEntityVariable("coirnav_attempt",tostring(attempt));n:SetEntityVariable("coirnav_entity",tostring(bossID));end
local function Cleanup(removeBoss)
    local el=eq.get_entity_list();for _,id in ipairs(NPCIDs())do local n=el:GetNPCByID(id);
        if Live(n)and ACTORS[n:GetNPCTypeID()]and n:GetSpawnPointID()==0 then eq.stop_all_timers(n);n:Depop();end
    end
    local guardian=GuardianPoint();if guardian then guardian:Disable();end
    if removeBoss then local boss=Boss();if boss then eq.stop_all_timers(boss);boss:Depop();end end
    records={};missing={};creatingSlot=nil;creatingLing=false;building=false;
end
local function ApplyCooldown()
    local p=BossPoint();if not p then Notice("boss-point","ERROR","Coirnav spawnpoint missing; recovery will retry.");return;end
    local ms=math.max(1,(cooldownUntil-Now())*1000);
    eq.update_spawn_timer(COIRNAV_SPAWNID,ms);p:SetTimer(ms);p:Enable();released=Now()>=cooldownUntil;cooldownArmed=true;
    local g=GuardianPoint();if g then g:Disable();eq.update_spawn_timer(GUARDIAN_SPAWNID,ms);
    else Notice("guardian-point","ERROR","Guardian spawnpoint missing; recovery will retry.");end
    Notice("cooldown","RESET",string.format("Coirnav reuse restored; %.1f minutes remain.",ms/60000));
end
local function ConfigureBoss(n)
    if not Live(n)then return;end
    if phase==0 then n:SetSpecialAbility(24,1);n:SetSpecialAbility(25,1);n:SetSpecialAbility(35,1);n:SetBodyType(11,false);
    elseif phase==1 then n:SetSpecialAbility(24,0);n:SetSpecialAbility(25,0);n:SetSpecialAbility(35,1);n:SetBodyType(11,false);
    else n:SetSpecialAbility(24,0);n:SetSpecialAbility(25,0);n:SetSpecialAbility(35,0);n:SetBodyType(1,false);end
end
local function Ready(n,announce)
    Cleanup(false);phase=0;started=0;deadline=0;waves=0;kills=0;nextWarning=1;nextLing=0;cooldownUntil=0;cleanupAt=0;bossID=n:GetID();ownState=true;released=false;cooldownArmed=false;
    ConfigureBoss(n);local g=GuardianPoint();if g then g:Enable();g:Repop();else Notice("guardian-point","ERROR","Guardian spawnpoint missing; ready supervision will retry.");end
    Save();if announce then RP("The reef stirs as Coirnav and his Guardian return. Vapor, ice and water gather once more beneath the will of the Triumvirate.");Log("READY","Coirnav and Guardian are ready for a fresh attempt.");end
end
Fail=function(reason,force)
    if not Active()and not force then return;end
    local n=Boss();phase=4;cooldownUntil=Now()+FAILURE_SECONDS;cleanupAt=Now()+2;ownState=true;released=false;cooldownArmed=false;records={};missing={};Save();
    local g=GuardianPoint();if g then g:Disable();end
    RP("Three voices thunder as one through Coirnav. \"The Triumvirate has spoken! These waters reject you, Norrathians. Be banished from our domain!\" A crushing surge tears through the reef as his summoned defenders dissolve into water, ice and vapor.");
    Log("FAIL",reason.." Cleanup follows the banishment after two seconds; retry remains ten minutes.");
    if Live(n)then n:CastSpell(1099,n:GetID());end
end
local function Expired()
    if Active()and Now()>=deadline then Fail("The original fifteen-minute event deadline expired.");return true;end
    return false;
end
local function EnsureInitialized()if not initialized then Initialize();end end
local function ArmSupervisor()eq.set_timer("watchdog",WATCHDOG_MS,encounter);end
local function SpawnRecord(typ,kind,loc,grid,hp)
    local slot=#records+1;local r={typ=typ,kind=kind,entity=0,status=0};records[slot]=r;Save();creatingSlot=slot;
    local n=eq.spawn2(typ,grid or 0,0,loc[1],loc[2],loc[3],loc[4]or 0);creatingSlot=nil;
    if not Active()then return false;end
    if not Live(n)then Fail("Failed to spawn type "..typ.." in slot "..slot);return false;end
    if r.entity==0 then Tag(n,r,slot);end
    if not Tagged(n,r,slot,false)then Fail("Spawn returned an unverified NPC in slot "..slot);return false;end
    if hp then n:CastToNPC():SetBaseHP(hp);end
    Save();return true;
end
local function SpawnWave(w)
    if not Active()or waves>=w then return;end
    waves=w;building=true;Save();
    local name=w==1 and "Povar"or(w==2 and "E`ci"or"Tarew Marr");local element=w==1 and "vapor"or(w==2 and "ice"or"water");
    RP("Coirnav the Avatar of Water shouts, \"Those that violate my domain will pay. I call upon the power imbued to me by "..name.."! Come forth my minions of "..element.." and destroy these intruders.\"");
    for _,loc in ipairs(SPAWN_LOCS)do if not SpawnRecord(FIENDS[w],1,loc,70)then building=false;return;end end
    if not SpawnRecord(MINIS[w],2,MINI_LOCS[w],0)then building=false;return;end
    building=false;Save();Log("WAVE","Wave "..w.." created: 25 individually tracked fiends and its early miniboss.");
end
local function LingWave()
    if phase~=3 or Expired()then return;end
    creatingLing=true;for _,loc in ipairs(SPAWN_LOCS)do
        local typ=eq.ChooseRandom(VAPORLING_TYPE,ICELING_TYPE,WATERLING_TYPE);
        local n=eq.spawn2(typ,70,0,loc[1],loc[2],loc[3],0);
        if not Live(n)then creatingLing=false;Fail("Final reinforcement spawn failed.");return;end
        n:SetEntityVariable("coirnav_ling_attempt",tostring(attempt));
    end;creatingLing=false;nextLing=Now()+49;Save();Log("WAVE","Final reinforcements spawned; next wave in 49 seconds.");
end
Advance=function()
    if building or not Active()or Expired()then return;end
    if phase==1 and waves==3 and kills==75 then
        local el=eq.get_entity_list();for slot,r in ipairs(records)do if r.kind==2 and r.status==0 then
            local n=el:GetNPCByID(r.entity);if Live(n)and Tagged(n,r,slot,false)then n:Depop();end;r.status=2;
        end end
        phase=2;building=true;Save();
        RP("The currents wrench across the reef as Pwelon, Nrinda and Vamuil gather before Coirnav. The Triumvirate speaks as one through the Avatar of Water: \"We will permit no further advance. Pwelon, Nrinda, Vamuil - unite and drive these invaders from the depths!\"");
        for i,t in ipairs(MINIS)do if not SpawnRecord(t,3,MINI_LOCS[i],0,MINI_HP[i])then building=false;return;end end
        building=false;ConfigureBoss(Boss());Save();Log("PHASE","All 75 fiends confirmed killed; three stronger minibosses summoned and Coirnav made attackable.");
    elseif phase==2 then
        for _,r in ipairs(records)do if r.kind==3 and r.status~=1 then return;end end
        phase=3;Save();local n=Boss();if not n or not OwnedBoss(n,false)then Fail("Coirnav disappeared during final transition.");return;end
        n:SetBaseHP(250000);n:BuffFadeAll();n:WipeHateList();
        RP("Water surges, ice fractures and vapor coils through the reef as Coirnav summons the remaining defenders of the depths. The Triumvirate's voices thunder as one: \"We shall not yield! Defenders of vapor, ice and water - rise! Let the depths claim these invaders!\"");
        LingWave();Log("PHASE","All three stronger minibosses confirmed killed; final phase active without extending the deadline.");
    end
end
local function ActorSpawn(e)
    if creatingSlot then local r=records[creatingSlot];if r and r.typ==e.self:GetNPCTypeID()and r.entity==0 then Tag(e.self,r,creatingSlot);return;end end
    if creatingLing and LINGS[e.self:GetNPCTypeID()]then e.self:SetEntityVariable("coirnav_ling_attempt",tostring(attempt));return;end
    EnsureInitialized();local slot=tonumber(e.self:GetEntityVariable("coirnav_slot"));local r=slot and records[slot];
    if LINGS[e.self:GetNPCTypeID()]and phase==3 and e.self:GetEntityVariable("coirnav_ling_attempt")==tostring(attempt)then return;end
    if not Active()or not r or r.status~=0 or not Tagged(e.self,r,slot,false)then e.self:Depop();Notice("foreign-spawn","WARN","Removed an untracked/duplicate event actor.");end
end
local function ActorDeath(e)
    EnsureInitialized();local slot=tonumber(e.self:GetEntityVariable("coirnav_slot"));local r=slot and records[slot];
    if not Active()or not r or r.status~=0 or not Tagged(e.self,r,slot,true)or e.self:GetEntityVariable("coirnav_counted")=="1"then Notice("foreign-death","WARN","Ignored stale, duplicate or untracked event death.");return;end
    if Expired()then return;end
    e.self:SetEntityVariable("coirnav_counted","1");r.status=1;missing[slot]=nil;if r.kind==1 then kills=kills+1;end;Save();
    Log("KILL","Type "..r.typ.." slot "..slot.." entity "..r.entity.." confirmed killed.");Advance();
end
local function BossDeath(e)
    EnsureInitialized();if(phase~=2 and phase~=3)or not OwnedBoss(e.self,true)or Expired()then Notice("boss-death","WARN","Ignored unverified or premature Coirnav death.");return;end
    phase=5;cooldownUntil=Now()+SUCCESS_SECONDS;cleanupAt=0;records={};ownState=true;released=false;cooldownArmed=false;Save();
    Cleanup(false);ApplyCooldown();
    RP("Coirnav, the Avatar of Water, has fallen! His colossal form collapses, driving a thunderous shockwave through the reef. Ice shatters and currents roar as the voices of the Triumvirate fall silent. The united power of Povar, E`ci and Tarew Marr has been overcome, and the Essence of Water rises from the depths!");
    Log("SUCCESS","Coirnav confirmed killed; successful reuse remains 138 hours.");
    local n=eq.spawn2(PROJECTION_TYPE,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0);
    if Live(n)and e.killer and e.killer.valid then eq.signal(PROJECTION_TYPE,e.killer:GetID());else Log("ERROR","Victory saved, but projection spawn or kill-rights recipient was missing.");end
end
local function BossSpawn(e)
    ArmSupervisor();
    EnsureInitialized();if e.self:GetSpawnPointID()~=COIRNAV_SPAWNID then return;end
    if eq.get_zone_guild_id()==1 then Ready(e.self,false);Log("QUAKE","Native Guild 1 Coirnav repop superseded old state.");
    elseif Active()then if not OwnedBoss(e.self,false)then Fail("Coirnav unexpectedly respawned during an active attempt.");end
    elseif phase==4 or phase==5 then
        if Now()<cooldownUntil then e.self:Depop();ApplyCooldown();Notice("early-boss","WARN","Suppressed early Coirnav without extending cooldown.");else Ready(e.self,true);end
    else Ready(e.self,false);end
end
local function GuardianDeath(e)
    EnsureInitialized();if e.self:GetSpawnPointID()~=GUARDIAN_SPAWNID then Notice("foreign-guardian","WARN","Ignored Guardian death outside the event spawnpoint.");return;end
    if phase~=0 then Notice("guardian-death","WARN","Ignored Guardian death during an active attempt/cooldown.");return;end
    local n=Boss();if not n then Notice("boss-missing","ERROR","Guardian killed while Coirnav was missing; preserving native boss cooldown.");return;end
    Cleanup(false);attempt=attempt+1;phase=1;started=Now();deadline=started+EVENT_SECONDS;waves=0;kills=0;nextWarning=1;nextLing=0;cooldownUntil=0;cleanupAt=0;notices={};ownState=true;
    TagBoss(n);ConfigureBoss(n);Save();SpawnWave(1);ArmSupervisor();
end
Initialize=function()
    if initialized then return;end
    local saved,why,fallback=Load();local n=Boss();
    if n and eq.get_zone_guild_id()==1 and(not saved or not Active()or not OwnedBoss(n,false))then Ready(n,false);Log("QUAKE","Native Guild 1 boss admitted a fresh encounter.");
    elseif saved and Active()then
        if not n or not OwnedBoss(n,false)then Fail("Reload found a missing/replaced Coirnav.");else ConfigureBoss(n);local g=GuardianPoint();if g then g:Disable();end;Expired();end
    elseif saved and(phase==4 or phase==5)then if Now()>=cleanupAt then Cleanup(true);ApplyCooldown();end
    elseif not saved and fallback and(fallback.phase==4 or fallback.phase==5)then
        phase=fallback.phase;attempt=fallback.attempt;cooldownUntil=fallback.untilTime;cleanupAt=fallback.cleanupAt;ownState=true;records={};Save();if Now()>=cleanupAt then Cleanup(true);ApplyCooldown();end
        Log("ERROR",why.."; retained recorded terminal cooldown.");
    elseif not saved and fallback and fallback.phase>=1 and fallback.phase<=3 then attempt=fallback.attempt;Fail(why.."; interrupted attempt cannot be verified.",true);
    elseif not saved then
        local orphan=false;local el=eq.get_entity_list();for _,id in ipairs(NPCIDs())do local actor=el:GetNPCByID(id);if Live(actor)and ACTORS[actor:GetNPCTypeID()]and actor:GetSpawnPointID()==0 then orphan=true;break;end end
        if orphan then Fail("Untracked pre-recovery attempt found.",true);elseif n then Ready(n,false);elseif why then Log("ERROR",why.."; preserving unknown native boss cooldown.");end
    elseif n then Ready(n,false);end
    initialized=true;Save();Log("LOAD","Persistent fifteen-minute deadline and encounter-owned recovery active; red RP and GM-only diagnostics enabled.");
end
local function Watchdog()
    EnsureInitialized();local n=Boss();
    if Active()then
        if Expired()then return;end
        if not BossPoint()then Fail("Coirnav spawnpoint disappeared.");return;end
        if not n or not OwnedBoss(n,false)then missing.boss=missing.boss or Now();if Now()-missing.boss>=MISSING_GRACE then Fail("Coirnav disappeared/replaced without a confirmed kill.");return;end;else missing.boss=nil;end
        if phase==1 then if waves<2 and Now()>=started+180 then SpawnWave(2);end;if Active()and waves<3 and Now()>=started+300 then SpawnWave(3);end end
        if not Active()then return;end
        local warningAt={600,720,840};local warningText={
            "The waters churn as three voices rise as one through Coirnav, echoing throughout the reef. \"Norrathians! The powers of Povar, E`ci and Tarew Marr are bound within me. You will not break the will of the Triumvirate!\"",
            "Ice spreads across the reef as vapor coils around Coirnav's towering form. His voice rolls through the depths. \"Our power gathers, and your time dwindles. Struggle against the currents! Spend what strength you have left. These waters will yield to no invader!\"",
            "The reef trembles beneath the gathering fury of water, ice and vapor. Coirnav's voice resounds through the depths. \"Your time is nearly spent, Norrathians! Finish what you began. Soon the united power of the Triumvirate shall sweep you from this domain!\""
        };
        while warningAt[nextWarning]and Now()>=started+warningAt[nextWarning]do RP(warningText[nextWarning]);Log("WARNING","Time warning at "..(warningAt[nextWarning]/60).." minutes.");nextWarning=nextWarning+1;Save();end
        local el=eq.get_entity_list();for slot,r in ipairs(records)do if r.status==0 then
            local actor=el:GetNPCByID(r.entity);
            if not Live(actor)or not Tagged(actor,r,slot,false)then missing[slot]=missing[slot]or Now();if Now()-missing[slot]>=MISSING_GRACE then Fail("Actor slot "..slot.." type "..r.typ.." disappeared/replaced without a confirmed kill.");return;end;else missing[slot]=nil;end
        end end
        Advance();if phase==3 and Now()>=nextLing then LingWave();end
    elseif phase==4 or phase==5 then
        if Now()<cleanupAt then return;end
        Cleanup(true);
        if Now()<cooldownUntil then local p=BossPoint();if p and(not cooldownArmed or not p:Enabled())then ApplyCooldown();end
        elseif not released then ApplyCooldown();else Notice("boss-wait","WARN","Cooldown expired; waiting for native boss spawn/quake policy.");end
    elseif n then
        local g=GuardianPoint();if g and not Live(g:GetNPC())then g:Enable();g:Repop();elseif not g then Notice("guardian-point","ERROR","Guardian spawnpoint missing; ready supervision will retry.");end
    end
end
local function Legacy(e)
    Notice("legacy-"..tostring(e.signal or e.timer),"WARN","Ignored obsolete NPC-owned signal/timer; encounter supervisor owns progress and cleanup.");
    if e.timer then eq.stop_timer(e.timer);end
end
local function Safe(callback)
    return function(e)local ok,err=pcall(callback,e);if not ok then
        Log("ERROR","Lua callback failed: "..tostring(err));local recovered,why=pcall(function()
            if Active()then Fail("Lua callback error.");elseif phase==4 or phase==5 then if Now()>=cleanupAt then Cleanup(true);Save();ApplyCooldown();end end
        end);if not recovered then Log("ERROR","Recovery also failed: "..tostring(why));end
        ArmSupervisor();
    end end;
end
function event_timer(e)if e.timer=="initialize"then eq.stop_timer(e.timer);Initialize();elseif e.timer=="watchdog"then Watchdog();end end
function event_encounter_load(e)
    encounter=e.encounter;local function reg(event,t,callback)eq.register_npc_event("Coirnav",event,t,Safe(callback));end
    reg(Event.spawn,COIRNAV_TYPE,BossSpawn);reg(Event.death_complete,COIRNAV_TYPE,BossDeath);reg(Event.signal,COIRNAV_TYPE,Legacy);reg(Event.timer,COIRNAV_TYPE,Legacy);
    reg(Event.death_complete,GUARDIAN_TYPE,GuardianDeath);
    for t in pairs(ACTORS)do reg(Event.spawn,t,ActorSpawn);if not LINGS[t]then reg(Event.death_complete,t,ActorDeath);end end
    reg(Event.signal,MONSTROUS_TYPE,Legacy);
    eq.set_timer("initialize",1000,encounter);ArmSupervisor();
end
local timer=event_timer;event_timer=Safe(timer);
