local BERTOX_TYPE = 200226; -- #Bertoxxulous

local DARWOL_TYPE = 200234; -- Darwol_Adan
local FEIG_TYPE = 200240; -- Feig_Adan
local XHUT_TYPE = 200265; -- Xhut_Adan
local KAVILIS_TYPE = 200246; -- Kavilis_Adan

local RADDI_TYPE = 200257; -- Raddi_Adan
local WAVADOZZIK_TYPE = 200263; -- Wavadozzik_Adan
local ZANDAL_TYPE = 200266; -- Zandal_Adan
local AKKAPAN_TYPE = 200223; -- Akkapan_Adan

local MEEDO_TYPE = 200250; -- Meedo_Adan
local QEZZIN_TYPE = 200256; -- Qezzin_Adan
local PZO_TYPE = 200255; -- Pzo_Adan
local BHALY_TYPE = 200227; -- Bhaly_Adan

local SPECTRE_TYPE = 200016; -- #Spectre_of_Corruption
local SPECTRE_SPAWNID = 360643;
local SUCCESS_RESPAWN_TIME = 237600 * 1000; -- 66 hours

local SUMMONER_TYPE = 200260; -- Summoner_of_Bertoxxulous
local CONTROLLER_TYPE = 200195; -- PusEventController
local PROJECTION_TYPE = 200269; -- A_Planar_Projection

local BOSS_TABLE = {
	[44] = { DARWOL_TYPE, 0, 280, -247, 0, "A bestial squeak thunders" },
	[48] = { FEIG_TYPE, -200, 0, -277, 64, "A bestial squeak thunders" },
	[52] = { XHUT_TYPE, 0, -280, -247, 128, "A dark vision flashes" },
	[56] = { KAVILIS_TYPE, 200, 0, -269, 192, "A faint buzzing is heard" },
	[84] = { RADDI_TYPE, 0, 280, -247, 0, "A wailing cry echoes" },
	[88] = { WAVADOZZIK_TYPE, -200, 0, -277, 64, "Chittering is heard" },
	[92] = { ZANDAL_TYPE, 0, -280, -247, 128, "Chittering is heard" },
	[96] = { AKKAPAN_TYPE, 200, 0, -269, 192, "A maddened whispering is heard" },

	[10000] = { MEEDO_TYPE, 0, 280, -247, 0 },
	[10001] = { QEZZIN_TYPE, -200, 0, -277, 64 },
	[10002] = { PZO_TYPE, 0, -280, -247, 128 },
	[10003] = { BHALY_TYPE, 200, 0, -269, 192 },
};

local TRASH_TYPES = {
	200247, -- Knight_of_Decay (level 62)
	200268, -- Priest_of_Decay
	200251, -- Necromancer_of_Decay
	200236, -- Elite_Knight_of_Decay
	200238, -- Elite_Priest_of_Decay
	200237, -- Elite_Necromancer_of_Decay
};

-- create table with spawn IDs of trash mobs.  Some were deleted because the locs were wrong so there are 'holes', otherwise they are contiguous
local TRASH_SPAWNIDS = {};
for i = 369228, 369264 do
	if ( i ~= 369241 and i ~= 369244 and i ~= 369255 and i ~= 369257 and i ~= 369260 ) then
		table.insert(TRASH_SPAWNIDS, i);
	end
end

local SUMMONER_LOCS = {
	{ 0, 305, -240, 128 },
	{ -235, 0, -270, 64 },
	{ 235, 0, -270, 192 },
	{ 0, -55, -285, 0 },
	{ 0, -305, -240, 0 },
};

local RP_TEXT = {
    prepare="Crazed laughter is heard as you notice a foul creature standing before you. The creature then speaks saying, 'Violators of the depths of Lxanvom shall pay with your lives!'  The foul minion of decay then begins chanting a dark ritual.  Deeper within the depths of the crypt more chanting can be heard.",
    waves="A foul wind is felt carrying on it the stench of death and decay.  Suddenly a thunderous bang is heard throughout the crypt and then these words, 'Great soldiers of decay you are summoned forth to do battle with these infidels!'  All around the crypt echoes of footsteps and shuffling feet are heard.",
    warning="Dark voices whisper in your ear saying, 'Your time is close in coming to an end. Time to flee little ones!'",
    failure="Harsh laughter echoes around the crypt and a voice then speaks saying, 'Perhaps you would care to try when you are more powerful fools.'  The harsh laughter continues softly as all of  the summoned minions of Bertoxxulous vanish.",
    final="An unsettling feeling of fear passes through you as you hear the summoners finish a dark incantation then cry out saying, 'We call to you the last corrupted Kings of Lxanvom. Meedo Adan! Qezzin Adan! Pzo Adan! Bhaly Adan! Your master has need of you!' Four separate howls of rage and despair echo throughout the lower depths of the crypt as four foul fiends of Bertoxxulous are summoned forth.",
    bertox="A sinister vision enters your mind of a faceless one handsome yet dead and decaying. The vision then shifts to that of a torn bestial creature and a loud shout is heard, 'Defilers death comes for you today!'",
    victory="A nimbus of light floods through the crypt in one magnificent wave as an earth shattering howl is heard.  The Bringer of Plagues, Lord of All Disease and Decay, Bertoxxulous has been defeated. Suddenly an urgent whisper fills your head simply saying, 'The Torch of Lxanvom shall burn bright again.  Freedom is now ours, for that we thank you.'",
};

local PREPARATION_SECONDS, EVENT_SECONDS, WARNING_SECONDS = 350, 7380, 300;
local TRASH_RESPAWN_SECONDS, FAILURE_SECONDS = 350, 300;
local WATCHDOG_MS, MISSING_GRACE = 5000, 10;
local phaseNames = { [0]="Ready", "Preparing", "Waves", "FinalKings", "Bertox", "Retry", "Success" };
local phase, attempt, trashKills = 0, 0, 0;
local preparationUntil, expiresUntil, cooldownUntil = 0, 0, 0;
local warned, initialized, cooldownReleased = false, false, false;
local encounter;
local spawned, killed, expected, pending, missingSince, notices = {}, {}, {}, {}, {}, {};
local creating={};
local stateKey="bertox-recovery-v1-"..tostring(eq.get_zone_guild_id());
local FIRST_KEYS={44,48,52,56,84,88,92,96};
local FINAL_KEYS={10000,10001,10002,10003};
local TYPES, KING_TYPES, MANAGED_SPAWNS={}, {}, {};
for _,keys in ipairs({FIRST_KEYS,FINAL_KEYS}) do
    for _,key in ipairs(keys) do
        local t=BOSS_TABLE[key][1]; TYPES[#TYPES+1]=t; KING_TYPES[t]=true;
    end
end
TYPES[#TYPES+1]=BERTOX_TYPE;
for _,id in ipairs(TRASH_SPAWNIDS) do MANAGED_SPAWNS[id]=true; end
local Fail, Advance, Initialize, BeginWaves;
local function Now() return os.time(); end
local function Active() return phase>=1 and phase<=4; end
local function Live(npc)
    return npc and npc.valid and npc:GetID()~=0 and npc:GetHP()>0 and not npc:IsCorpse();
end
local function Name(npc) return npc and npc.valid and npc:GetCleanName() or "Unknown NPC"; end
local function KingKills()
    local n=0;for t in pairs(KING_TYPES) do if killed[t] then n=n+1; end end;return n;
end
local function RP(message) eq.zone_emote(13,message); end
local function Log(kind,message)
    local text=string.format("[Bertox guild=%s attempt=%d phase=%s trash=%d kings=%d] [%s] %s",
        tostring(eq.get_zone_guild_id()),attempt,phaseNames[phase],trashKills,KingKills(),kind,message);
    eq.debug(text);
    for client in eq.get_entity_list():GetClientList().entries do
        if client.valid and client:GetGM() then client:Message(15,text); end
    end
end
local function Notice(key,kind,message)
    if not notices[key] or Now()-notices[key]>=30 then notices[key]=Now();Log(kind,message);end
end
local function Bits(values)
    local out={};for _,t in ipairs(TYPES) do out[#out+1]=values[t] and "1" or "0";end;return table.concat(out);
end
local function Save()
    eq.set_data(stateKey,table.concat({phase,attempt,trashKills,preparationUntil,expiresUntil,cooldownUntil,
        warned and 1 or 0,Bits(spawned),Bits(killed)},"|"));
end
local function Load()
    local value=eq.get_data(stateKey);if not value or value=="" then return false;end
    local fields={};for f in (value.."|"):gmatch("(.-)|") do fields[#fields+1]=f;end
    if #fields~=9 then Log("ERROR","Invalid saved state; refusing to adopt unverified progress.");return false;end
    for i=1,7 do if not fields[i]:match("^%d+$") then return false;end end
    if tonumber(fields[1])>6 or #fields[8]~=#TYPES or #fields[9]~=#TYPES or
        fields[8]:find("[^01]") or fields[9]:find("[^01]") then return false;end
    for i=1,#TYPES do if fields[9]:sub(i,i)=="1" and fields[8]:sub(i,i)~="1" then return false;end end
    phase,attempt,trashKills=tonumber(fields[1]),tonumber(fields[2]),tonumber(fields[3]);
    preparationUntil,expiresUntil,cooldownUntil=tonumber(fields[4]),tonumber(fields[5]),tonumber(fields[6]);
    warned=fields[7]=="1";spawned={};killed={};
    for i,t in ipairs(TYPES) do spawned[t]=fields[8]:sub(i,i)=="1";killed[t]=fields[9]:sub(i,i)=="1";end
    return true;
end
local function Tagged(npc)
    return npc and npc.valid and npc:GetEntityVariable("bertox_attempt")==tostring(attempt);
end
local function Tag(npc)
    npc:SetEntityVariable("bertox_attempt",tostring(attempt));
    npc:SetEntityVariable("bertox_entity",tostring(npc:GetID()));
    npc:SetEntityVariable("bertox_counted","0");
end
local function FindType(t)
    local npc=eq.get_entity_list():GetMobByNpcTypeID(t);return Live(npc) and npc or nil;
end
local function Summoners()
    local n=0;for npc in eq.get_entity_list():GetNPCList().entries do
        if Live(npc) and npc:GetNPCTypeID()==SUMMONER_TYPE and Tagged(npc) then n=n+1;end
    end;return n;
end
local function StopTrash()
    local ok=true;
    for _,id in ipairs(TRASH_SPAWNIDS) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if spawn and spawn.valid then spawn:Disable();
        else ok=false;Notice("trash-"..id,"ERROR","Missing event trash spawnpoint "..id);end
    end
    return ok;
end
local function Cleanup()
    StopTrash();
    for npc in eq.get_entity_list():GetNPCList().entries do
        if Live(npc) and (KING_TYPES[npc:GetNPCTypeID()] or npc:GetNPCTypeID()==SUMMONER_TYPE or npc:GetNPCTypeID()==BERTOX_TYPE) then
            eq.stop_all_timers(npc);npc:Depop();
        end
    end
    expected={};missingSince={};
end
local function ApplyCooldown()
    local spawn=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);
    if not spawn or not spawn.valid then Notice("spectre","ERROR","Spectre spawnpoint missing; recovery will retry.");return false;end
    local npc=spawn:GetNPC();if Live(npc) and Now()<cooldownUntil then npc:Depop();end
    local remaining=math.max(1,(cooldownUntil-Now())*1000);
    eq.update_spawn_timer(SPECTRE_SPAWNID,remaining);spawn:SetTimer(remaining);spawn:Enable();
    Log("RESET",string.format("Spectre spawnpoint enabled; remaining cooldown %.1f minutes.",remaining/60000));
    return spawn:Enabled();
end
local function CancelActions()
    for _,name in ipairs({"prepare","warning","expire"}) do pending[name]=nil;eq.stop_timer(name,encounter);end
end
local function ArmDeadlines()
    if not Active() then return;end
    if phase==1 then pending.prepare=attempt;eq.set_timer("prepare",math.max(1,(preparationUntil-Now())*1000),encounter);end
    pending.expire=attempt;eq.set_timer("expire",math.max(1,(expiresUntil-Now())*1000),encounter);
    if not warned then pending.warning=attempt;eq.set_timer("warning",math.max(1,(expiresUntil-WARNING_SECONDS-Now())*1000),encounter);end
end
local function RestoreSupervision()
    eq.set_timer("watchdog",WATCHDOG_MS,encounter);
    if not initialized then eq.set_timer("initialize",1000,encounter);else ArmDeadlines();end
end
Fail=function(reason,force)
    if not Active() and not force then return;end
    phase=5;cooldownUntil=Now()+FAILURE_SECONDS;cooldownReleased=false;
    preparationUntil=0;expiresUntil=0;CancelActions();Save();
    Log("FAIL",reason);RP(RP_TEXT.failure);
    Cleanup();ApplyCooldown();Save();
end
local function Expired()
    if Active() and Now()>=expiresUntil then Fail("The overall event deadline expired.");return true;end
    return false;
end
local function WarnExpiry()
    if Active() and not warned and Now()>=expiresUntil-WARNING_SECONDS then
        warned=true;Save();RP(RP_TEXT.warning);Log("WARN",string.format("%.1f minutes remain before the overall event deadline.",WARNING_SECONDS/60));
    end
end
local function SetReady()
    phase=0;preparationUntil=0;expiresUntil=0;cooldownUntil=0;
    spawned={};killed={};expected={};missingSince={};trashKills=0;warned=false;
    CancelActions();Save();
    RP("The dark ritual falls silent. The depths of Lxanvom await those who would challenge the Lord of Plagues once more.");
    Log("READY","Spectre recovery completed; a new attempt can begin.");
end
local function GuildOneRepop(npc)
    -- A real Guild 1 trigger spawned only after the server admitted it through
    -- the quake/timed-spawn policy. Do not veto that native repop with old Lua state.
    if eq.get_zone_guild_id()~=1 or phase==0 or not Live(npc) or npc:GetSpawnPointID()~=SPECTRE_SPAWNID then return false;end
    Log("RESET","Native Guild 1 Spectre repop supersedes the previous attempt/cooldown.");
    Cleanup();local spawn=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);if spawn and spawn.valid then spawn:Enable();end
    SetReady();return true;
end
local function ConfigureTrash(firstWave)
    for _,id in ipairs(TRASH_SPAWNIDS) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if not spawn or not spawn.valid then Fail("Missing event trash spawnpoint "..id);return false;end
        -- Content-authored timer: do not let Timekeeper select the stale 230-second NPC override.
        spawn:SetRespawnTimer(TRASH_RESPAWN_SECONDS);spawn:SetVariance(0);
        local npc=spawn:GetNPC();
        if Live(npc) then
            if not Tagged(npc) then Tag(npc);end
        elseif firstWave or not spawn:Enabled() then spawn:SetTimer(1);end
        spawn:Enable();
    end
    return true;
end
local function SpawnKing(key)
    local data=BOSS_TABLE[key];local t=data[1];
    if spawned[t] then return true;end
    if FindType(t) then Fail("Untracked or duplicate Adan already present: "..t);return false;end
    spawned[t]=true;Save();creating[t]=true;
    local npc=eq.spawn2(t,0,0,data[2],data[3],data[4],data[5]);
    creating[t]=nil;
    if not Active() then return false;end
    if not Live(npc) then Fail("Failed to spawn Adan type "..t);return false;end
    Tag(npc);expected[t]=npc:GetID();
    Log("SPAWN",Name(npc).." summoned; type "..t..", entity "..npc:GetID()..".");
    return npc;
end
local function AllKilled(keys)
    for _,key in ipairs(keys) do if not killed[BOSS_TABLE[key][1]] then return false;end end;return true;
end
Advance=function()
    if Expired() then return;end
    if phase==2 and AllKilled(FIRST_KEYS) then
        phase=3;Save();RP(RP_TEXT.final);Log("PHASE","All eight distinct Adans confirmed killed; summoning the final four.");
        for _,key in ipairs(FINAL_KEYS) do if not SpawnKing(key) then return;end end
    elseif phase==3 and AllKilled(FIRST_KEYS) and AllKilled(FINAL_KEYS) then
        phase=4;spawned[BERTOX_TYPE]=true;Save();RP(RP_TEXT.bertox);
        creating[BERTOX_TYPE]=true;
        local npc=eq.spawn2(BERTOX_TYPE,58,0,0,280,-243,0);
        creating[BERTOX_TYPE]=nil;
        if phase~=4 then return;end
        if not Live(npc) then Fail("Bertoxxulous failed to spawn.");return;end
        Tag(npc);expected[BERTOX_TYPE]=npc:GetID();Log("PHASE","All twelve distinct kings killed; Bertoxxulous summoned.");
    end
end
BeginWaves=function()
    if phase~=1 or Expired() then return;end
    if Now()<preparationUntil then ArmDeadlines();return;end
    phase=2;Save();pending.prepare=nil;eq.stop_timer("prepare",encounter);
    if not ConfigureTrash(true) then return;end
    RP(RP_TEXT.waves);Log("PHASE",string.format("Event trash enabled at 32 spawnpoints; recurring respawns every %d seconds.",TRASH_RESPAWN_SECONDS));
end
function SpectreDeathComplete(e)
    if e.self:GetSpawnPointID()~=SPECTRE_SPAWNID then Notice("foreign-spectre","WARN","Ignored Spectre death outside the event trigger spawnpoint.");return;end
    RestoreSupervision();if not initialized then Initialize();end
    if (phase==5 or phase==6) and Now()>=cooldownUntil then SetReady();end
    if phase~=0 then Notice("spectre-death","WARN","Ignored Spectre death while this attempt/cooldown is still active.");if phase==5 or phase==6 then ApplyCooldown();end;return;end
    if e.self:GetEntityVariable("bertox_start_credited")=="1" then return;end
    e.self:SetEntityVariable("bertox_start_credited","1");
    attempt=attempt+1;phase=1;trashKills=0;spawned={};creating={};killed={};expected={};missingSince={};notices={};warned=false;
    preparationUntil=Now()+PREPARATION_SECONDS;expiresUntil=Now()+EVENT_SECONDS;cooldownUntil=0;cooldownReleased=false;
    CancelActions();Save();Cleanup();
    local trigger=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);
    if not trigger or not trigger.valid then Fail("Spectre spawnpoint missing at attempt start.");return;end
    trigger:Disable();
    RP(RP_TEXT.prepare);Log("START",string.format("Spectre killed by %s; preparation %d seconds, overall deadline %.1f minutes.",Name(e.killer),PREPARATION_SECONDS,EVENT_SECONDS/60));
    for _,loc in ipairs(SUMMONER_LOCS) do
        local npc=eq.spawn2(SUMMONER_TYPE,0,0,loc[1],loc[2],loc[3],loc[4]);
        if not Live(npc) then Fail("A summoner failed to spawn.");return;end
        Tag(npc);
    end
    ArmDeadlines();Save();
end
function SpectreSpawnEvent(e)
    RestoreSupervision();
    if e.self:GetSpawnPointID()~=SPECTRE_SPAWNID then e.self:Depop();Notice("foreign-spectre","WARN","Removed a Spectre outside the event trigger spawnpoint.");return;end
    if GuildOneRepop(e.self) then return;end
    if Active() then e.self:Depop();local spawn=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);if spawn and spawn.valid then spawn:Disable();end
    elseif phase==5 or phase==6 then
        if Now()<cooldownUntil then e.self:Depop();ApplyCooldown();else SetReady();end
    end
end
function SummonerSpawnEvent(e)
    RestoreSupervision();
    if not Active() or Summoners()>=#SUMMONER_LOCS then e.self:Depop();Notice("extra-summoner","WARN","Removed an unexpected or duplicate summoner.");return;end
    Tag(e.self);
end
function BossSpawnEvent(e)
    RestoreSupervision();local t=e.self:GetNPCTypeID();
    if not Active() or not spawned[t] or killed[t] or
        (not creating[t] and not Tagged(e.self)) or (expected[t] and expected[t]~=e.self:GetID()) then
        e.self:Depop();Notice("unexpected-"..t,"WARN","Removed an unexpected/duplicate phase NPC "..t);return;
    end
    Tag(e.self);expected[t]=e.self:GetID();
end
function TrashSpawnEvent(e)
    local id=e.self:GetSpawnPointID();if not MANAGED_SPAWNS[id] then return;end
    RestoreSupervision();
    if phase>=2 and phase<=4 then
        Tag(e.self);local spawn=eq.get_entity_list():GetSpawnByID(id);if spawn and spawn.valid then spawn:SetRespawnTimer(TRASH_RESPAWN_SECONDS);spawn:SetVariance(0);end
    else
        local spawn=eq.get_entity_list():GetSpawnByID(id);if spawn and spawn.valid then spawn:Disable();else e.self:Depop();end
    end
end
function TrashDeathComplete(e)
    if not initialized or phase<2 or phase>4 or Expired() then return;end
    if not MANAGED_SPAWNS[e.self:GetSpawnPointID()] or not Tagged(e.self) then Notice("foreign-trash","WARN","Ignored trash not owned by the current attempt/spawnpoints.");return;end
    if e.self:GetEntityVariable("bertox_counted")=="1" then return;end
    e.self:SetEntityVariable("bertox_counted","1");trashKills=trashKills+1;Save();
    Log("KILL",Name(e.self).." credited as trash kill "..trashKills..".");
    if phase==2 and trashKills<=96 and BOSS_TABLE[trashKills] then
        local data=BOSS_TABLE[trashKills];local npc=SpawnKing(trashKills);
        if npc and Live(npc) then RP(string.format("An unsettling feeling of fear passes through you as the summoners cry, 'We call to you, corrupted King of Lxanvom, %s! Your master has need of you!' %s through the crypt as a foul fiend of Bertoxxulous is summoned forth.",Name(npc),data[6]));end
    end
end
local function ConfirmBossDeath(npc)
    local t=npc:GetNPCTypeID();
    if not spawned[t] or killed[t] or not Tagged(npc) or npc:GetEntityVariable("bertox_entity")~=tostring(expected[t]) then
        Notice("foreign-death-"..t,"WARN","Ignored duplicate, stale, or untracked boss death "..t);return false;
    end
    killed[t]=true;expected[t]=nil;missingSince[t]=nil;Save();return true;
end
function TriggerBossDeathComplete(e)
    if (phase~=2 and phase~=3) or Expired() or not ConfirmBossDeath(e.self) then return;end
    RP(string.format("The corrupted king, %s, falls. His dying cry echoes through the depths of Lxanvom.",Name(e.self)));
    Log("KILL",Name(e.self).." confirmed killed once for this attempt.");Advance();
end
function BertoxDeathComplete(e)
    if phase~=4 or Expired() or not ConfirmBossDeath(e.self) then return;end
    phase=6;cooldownUntil=Now()+SUCCESS_RESPAWN_TIME/1000;cooldownReleased=false;
    preparationUntil=0;expiresUntil=0;CancelActions();Save();Cleanup();ApplyCooldown();Save();
    RP(RP_TEXT.victory);Log("SUCCESS",string.format("Bertoxxulous confirmed killed; Spectre cooldown %.1f hours.",SUCCESS_RESPAWN_TIME/3600000));
    local projection=eq.spawn2(PROJECTION_TYPE,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0);
    if Live(projection) and e.killer and e.killer.valid then eq.signal(PROJECTION_TYPE,e.killer:GetID());
    else Log("ERROR","Victory recorded, but projection spawn or kill-rights recipient is missing.");end
end
function BossCombat(e)
    if not Active() or not Tagged(e.self) or (not e.joined and e.self:GetHP()<=0) then return;end
    if e.joined then RP(Name(e.self).." rises to meet your challenge! The depths of Lxanvom ring with the clash of battle.");Log("ENGAGE",Name(e.self).." engaged.");
    else RP(Name(e.self).." stands amid the decay, awaiting those who would challenge the Lord of Plagues.");Log("DISENGAGE",Name(e.self).." lost all aggro; the overall deadline continues.");end
end
function ControllerSignal(e) Notice("legacy-signal-"..e.signal,"WARN","Ignored obsolete controller signal "..e.signal.."; encounter state owns progression.");end
function ControllerTimer(e) eq.stop_timer(e.timer);Notice("legacy-timer-"..e.timer,"WARN","Ignored obsolete controller timer "..e.timer.."; encounter timers own deadlines.");end
function ControllerSpawnEvent(e) RestoreSupervision();end

-- this trash has atypical loiting behavior
function TrashCombat(e)
	if ( e.joined ) then
		eq.stop_timer("end_loiter");
		
	elseif ( math.random(1, 5) == 1 ) then
		eq.set_timer("end_loiter", math.random(1, 300)*1000);
	end
end

function TrashTimer(e)

	if ( e.timer == "end_loiter" ) then
		eq.stop_timer(e.timer);
		
		e.self:ResumeWandering();
	end
end

function TrashWaypointArrive(e)
	if ( e.self:GetGrid() > 0 and e.wp == (e.self:GetMaxWp() - 1) ) then
		e.self:RemoveWaypoints();
		e.self:SaveGuardSpot();
	end
end


Initialize=function()
    local saved=Load();
    local native=FindType(SPECTRE_TYPE);
    local nativeGuildOne=eq.get_zone_guild_id()==1 and native and native:GetSpawnPointID()==SPECTRE_SPAWNID;
    if saved and GuildOneRepop(native) then
        -- Native quake/fresh-zone handling already reset this encounter above.
    elseif not saved then
        local orphan,oldActive=false,false;
        for npc in eq.get_entity_list():GetNPCList().entries do
            if Live(npc) then
                local t=npc:GetNPCTypeID();
                if KING_TYPES[t] then orphan=true;
                elseif t==BERTOX_TYPE or t==SUMMONER_TYPE then oldActive=true;end
            end
        end
        if oldActive and not nativeGuildOne then Fail("Untracked old active encounter found; clearing it before a fresh attempt.",true);
        else
            if orphan then Log("WARN","Removed old Adans; preserving the unknown pre-existing Spectre cooldown rather than replacing it with a short retry.");end
            Cleanup();
        end
    elseif Active() then
        if not Expired() then
            if Summoners()~=#SUMMONER_LOCS then Fail("Reload found missing or untracked summoners; the old attempt cannot be verified.");
            else
                for _,t in ipairs(TYPES) do
                    if spawned[t] and not killed[t] then
                        local npc=FindType(t);
                        if not npc or not Tagged(npc) then Fail("Reload found a missing/untracked phase NPC "..t);break;end
                        expected[t]=npc:GetID();
                    end
                end
                if phase>=2 and phase<=4 then ConfigureTrash(false);else StopTrash();end
                if Active() then Advance();ArmDeadlines();end
            end
        end
    elseif phase==5 or phase==6 then Cleanup();ApplyCooldown();else Cleanup();end
    initialized=true;Save();Log("LOAD","Persistent progress restored; encounter supervision every five seconds; red RP and GM-only diagnostics active.");
end
local function Watchdog()
    if not initialized then return;end
    if Active() then
        if Expired() then return;end
        WarnExpiry();
        if phase==1 then
            StopTrash();if Now()>=preparationUntil then BeginWaves();end
        else
            if not ConfigureTrash(false) then return;end
        end
        if not Active() then return;end
        local trigger=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);if trigger and trigger.valid then trigger:Disable();end
        if Summoners()~=#SUMMONER_LOCS then
            missingSince.summoners=missingSince.summoners or Now();
            if Now()-missingSince.summoners>=MISSING_GRACE then Fail("Summoners disappeared without completing the attempt.");return;end
        else missingSince.summoners=nil;end
        for _,t in ipairs(TYPES) do
            if spawned[t] and not killed[t] then
                local npc=FindType(t);
                if not npc or not Tagged(npc) or npc:GetID()~=expected[t] then
                    missingSince[t]=missingSince[t] or Now();
                    if Now()-missingSince[t]>=MISSING_GRACE then Fail("Phase NPC "..t.." disappeared/replaced without a confirmed kill.");return;end
                else missingSince[t]=nil;end
            end
        end
        Advance();
    elseif phase==5 or phase==6 then
        Cleanup();
        local spawn=eq.get_entity_list():GetSpawnByID(SPECTRE_SPAWNID);
        if not spawn or not spawn.valid then Notice("spectre","ERROR","Missing Spectre spawnpoint; recovery remains pending.");return;end
        if not spawn:Enabled() then ApplyCooldown();end
        local npc=spawn:GetNPC();
        if Now()<cooldownUntil then
            if Live(npc) then npc:Depop();spawn:SetTimer(math.max(1,(cooldownUntil-Now())*1000));Notice("early-spectre","WARN","Spectre appeared early; original cooldown restored.");end
        else
            if not cooldownReleased then cooldownReleased=true;if not spawn:NPCPointerValid() then spawn:SetTimer(1);spawn:Enable();end end
            if Live(spawn:GetNPC()) then SetReady();else Notice("spectre-pending","WARN","Cooldown elapsed; waiting for the Spectre to spawn. Server policy/spawn conditions may still block it.");end
        end
    else Cleanup();end
end
function event_timer(e)
    if e.timer=="initialize" then eq.stop_timer(e.timer);Initialize();return;end
    if e.timer=="watchdog" then Watchdog();return;end
    local token=pending[e.timer];pending[e.timer]=nil;eq.stop_timer(e.timer);
    if token~=attempt then return;end
    if e.timer=="prepare" then BeginWaves();elseif e.timer=="warning" then WarnExpiry();elseif e.timer=="expire" then Expired();end
end
local function SafeHandler(callback)
    return function(e)
        local ok,err=pcall(callback,e);
        if not ok then
            Log("ERROR","Lua callback failed: "..tostring(err));
            local recovered,why=pcall(Fail,"Lua callback error; initiating Spectre recovery.");
            if not recovered then Log("ERROR","Recovery also failed: "..tostring(why));end
            if not initialized then eq.set_timer("initialize",5000,encounter);end
        end
    end;
end
function event_encounter_load(e)
    encounter=e.encounter;
    local function reg(event,t,callback)eq.register_npc_event("Bertox",event,t,SafeHandler(callback));end
    reg(Event.death_complete,SPECTRE_TYPE,SpectreDeathComplete);reg(Event.spawn,SPECTRE_TYPE,SpectreSpawnEvent);
    reg(Event.timer,CONTROLLER_TYPE,ControllerTimer);reg(Event.signal,CONTROLLER_TYPE,ControllerSignal);reg(Event.spawn,CONTROLLER_TYPE,ControllerSpawnEvent);
    reg(Event.spawn,SUMMONER_TYPE,SummonerSpawnEvent);
    for _,t in ipairs(TRASH_TYPES) do
        reg(Event.spawn,t,TrashSpawnEvent);reg(Event.death_complete,t,TrashDeathComplete);
        reg(Event.combat,t,TrashCombat);reg(Event.timer,t,TrashTimer);reg(Event.waypoint_arrive,t,TrashWaypointArrive);
    end
    for t in pairs(KING_TYPES) do reg(Event.spawn,t,BossSpawnEvent);reg(Event.death_complete,t,TriggerBossDeathComplete);reg(Event.combat,t,BossCombat);end
    reg(Event.spawn,BERTOX_TYPE,BossSpawnEvent);reg(Event.death_complete,BERTOX_TYPE,BertoxDeathComplete);reg(Event.combat,BERTOX_TYPE,BossCombat);
    eq.set_timer("initialize",1000,encounter);eq.set_timer("watchdog",WATCHDOG_MS,encounter);
end
local encounterTimer=event_timer;event_timer=SafeHandler(encounterTimer);
