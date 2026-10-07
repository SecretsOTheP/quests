local ProjectionEligibility = require("projection_eligibility");

local CONTROLLER_TYPE = 217068; -- A_booming
local GUARDIAN_TYPE = 217050; -- Guardian_of_Doomfire
local REAVER_TYPE = 217417; -- a_rage_reaver_of_flame
local HEALER_TYPE = 217418; -- a_chaos_healer_of_flame
local MAGUS_TYPE = 217419; -- a_dark_magus_of_flame
local DARKFIEND_TYPE = 217421; -- a_doomfire_darkfiend
local CHAOSFIEND_TYPE = 217420; -- a_doomfire_chaosfiend
local RAGEFIEND_TYPE = 217422; -- a_doomfire_ragefiend
local AZOBIAN_TYPE = 217425; -- Azobian_the_Darklord
local JAVONN_TYPE = 217426; -- Javonn_the_Overlord
local HEBAB_TYPE = 217453; -- Hebabbilys_the_Ragelord
local REAX_TYPE = 217427; -- Reaxnous_the_Chaoslord
local KIRTRA_TYPE = 217432; -- Chancellor_Kirtra
local TRAXOM_TYPE = 217433; -- Chancellor_Traxom
local CRATO_TYPE = 217429; -- Omni_Magus_Crato
local PROLLAZ_TYPE = 217428; -- Warlord_Prollaz
local ELITE_TYPE = 217430; -- elite_guardian_of_ro
local FENNIN_TYPE = 217440; -- Fennin_Ro_the_Tyrant_of_Fire
local PROJECTION_TYPE = 217454; -- Essence_of_Fire
local GUARDIAN_SPAWN_ID = 367088;
local FAILURE_RETRY_TIME = 64800 * 1000; -- 18 hours
local SUCCESS_RESPAWN_TIME = 496800 * 1000; -- 5 days, 18 hours

local TRASH_TYPES = {
	REAVER_TYPE, HEALER_TYPE, MAGUS_TYPE, DARKFIEND_TYPE, CHAOSFIEND_TYPE, RAGEFIEND_TYPE, AZOBIAN_TYPE, 
	JAVONN_TYPE, HEBAB_TYPE, REAX_TYPE, KIRTRA_TYPE, TRAXOM_TYPE, CRATO_TYPE, PROLLAZ_TYPE
};

local SPAWNS = {	-- these locs are copied from showeq so they are Y, X, Z, 360 degree headings
	[1] = {
		[REAVER_TYPE] = {
			{ -1621,	-588,	-166.625,	329.0625 },
			{ -1321,	-605,	-117.375,	37.26563 },
			{ -1085,	-673,	-145.1589,	2.109375 },
			{ -1620,	-834,	-207.625,	95.625 },
			{ -1465,	-668,	-146.747,	28.82813 },
			{ -1422,	-714,	-146.747,	47.8125 },
			{ -1321,	-561,	-116.625,	337.5 },
			{ -1070,	-719,	-146.747,	54.14063 },
			{ -992,	-579,	-146.747,	78.04688 },
			{ -1202,	-459,	-201.747,	73.82813 },
			{ -1147,	-452,	-201.7444,	94.21875 },
			{ -1643,	-789,	-201.375,	85.07813 },
			{ -1671,	-839,	-207.625,	80.85938 },
			{ -1166,	-624,	-119.75,	319.2188 },
			{ -944,	-575,	-146.747,	100.5469 },
			{ -995,	-500,	-166.747,	159.6094 },
			{ -1003,	-466,	-166.747,	181.4063 },
		},
		[HEALER_TYPE] = {
			{ -955,	-486,	-166.625,	114.6094 },
			{ -1635,	-560,	-166.625,	309.375 },
			{ -956,	-598,	-146.747,	86.48438 },
			{ -1658,	-867,	-207.625,	85.07813 },
			{ -1467,	-715,	-146.747,	44.29688 },
			{ -1197,	-625,	-116.625,	337.5 },
			{ -1172,	-452,	-201.747,	90.70313 },
		},
		[MAGUS_TYPE] = {
			{ -1175,	-584,	-116.625,	311.4844 },
			{ -1636,	-860,	-207.625,	85.07813 },
			{ -1586,	-508,	-166.625,	281.9531 },
			{ -1351,	-576,	-117,	52.73438 },
			{ -1117,	-709,	-145.2836,	16.17188 },
			{ -981,	-596,	-146.625,	86.48438 },
			{ -1152,	-505,	-201.747,	97.73438 },
			{ -1188,	-513,	-201.747,	90.70313 },
		},
		[DARKFIEND_TYPE] = {
			{ -1331,	-590,	-105.497,	10.54688 },
			{ -1180,	-613,	-105.4944,	319.9219 },
			{ -1081,	-703,	-135.4944,	45 },
		},
		[CHAOSFIEND_TYPE] = {
			{ -994,	-483,	-156.1194,	182.1094 },
			{ -969,	-577,	-136.1194,	90.70313 },
			{ -1172,	-471,	-191.122,	90 },
		},
		[RAGEFIEND_TYPE] = {
			{ -1444,	-692,	-134.872,	46.40625 },
			{ -1647,	-823,	-195.75,	90 },
			{ -1604,	-539,	-154.75,	305.1563 },
		},
	},
	[2] = {
		[REAVER_TYPE] = {
			{ -1573,	-1245,	-227.747,	142.0313 },
			{ -1629,	-1241,	-227.747,	104.0625 },
			{ -1621,	-1306,	-227.747,	94.21875 },
			{ -1611,	-1293,	-227.747,	142.0313 },
			{ -1595,	-1274,	-227.747,	142.0313 },
			{ -1585,	-1229,	-227.747,	106.1719 },
			{ -1551,	-1217,	-227.747,	142.0313 },
		},
		[HEALER_TYPE] = {
			{ -1577,	-1284,	-221.747,	142.7344 },
			{ -1584,	-1350,	-200.747,	142.7344 },
			{ -1525,	-1312,	-198.4345,	142.7344 },
			{ -1506,	-1247,	-200.747,	142.7344 },
			{ -1550,	-1302,	-203.747,	142.7344 },
		},
		[MAGUS_TYPE] = {
			{ -1592,	-1335,	-209.747,	142.7344 },
			{ -1540,	-1235,	-221.747,	142.7344 },
			{ -1604,	-1322,	-221.747,	142.7344 },
			{ -1525,	-1247,	-209.747,	142.7344 },
		},
		[AZOBIAN_TYPE] = { { -1513,	-1274,	-184.6845,	139.9219 }, },
		[JAVONN_TYPE] = { { -1495,	-1338,	-181.5,	142.7344 }, },
		[HEBAB_TYPE] = { { -1562,	-1339,	-184.6845,	123.0469 },	},
		[REAX_TYPE] = {	{ -1572,	-1286,	-204.997,	114.6094 },	},
	},
	[3] = {
		[KIRTRA_TYPE]  = { { -1152, -1555, -199, 182 } },
		[TRAXOM_TYPE]  = { { -1132, -1451, -199, 182 } },
		[CRATO_TYPE]   = { { -906, -1393, -183, 182 } },
		[PROLLAZ_TYPE] = { { -906, -1587, -183, 182 } },
	},
	[4] = {
		[FENNIN_TYPE]  = { { -930, -1504, -160, 182 } },
	},
};

local ELITE_SPAWNIDS = { 369529, 369530, 369531, 369532, 369533, 369534, 369535, 369536, 369537, 369538 };

-- Red RP is public; technical recovery diagnostics are GM-only.
local PHASE_TEXT = {
    "The Guardian of Doomfire crashes to the scorched earth. Frenzied cries erupt as an Army of Flames burns across the scorched realm of Doomfire. All of Doomfire trembles as the voice of Fennin Ro booms, \"Norrathians! You have brought your hunger for power into my realm. Let the fury of my armies teach you the price of your arrogance!\"",
    "The first ranks fall, but the roar of battle grows louder. Four commanders rise amid the flames, driving fresh soldiers forward in a frenzy of rage. All of Doomfire trembles as the voice of Fennin Ro booms, \"Azobian! Javonn! Hebabbilys! Reaxnous! Let these invaders drown in the Chaos of Doomfire!\"",
    "The commanders collapse beneath the onslaught. Columns of fire tear through the air as the Council of Fire advances through the wreckage of the army. All of Doomfire trembles as the voice of Fennin Ro booms, \"You have mistaken my restraint for weakness. Council of Fire! Burn this greed from their flesh! The balance of power will not bend to Norrathian ambition!\"",
    "The Council of Fire falls. A deafening roar shakes the Burning Lands as the flames gather into the towering form of Fennin Ro. The Tyrant of Fire rises from the inferno, his wrath spilling across Doomfire. \"Enough! Flame and Chaos answer to me! Face me, Norrathians, and learn what remains when my fury meets your ambition!\"",
};
local FAILURE_TEXT = "All of Doomfire trembles as the voice of Fennin Ro booms, \"Enough, Norrathians! Carry the memory of this failure back to your world. Should you return, my wrath will be waiting!\" The army withdraws into the raging flames, leaving the scorched battlefield silent.";
local VICTORY_TEXT = "Fennin Ro, the Tyrant of Fire, falls! His colossal form crashes into the scorched earth as shockwaves tear through the Burning Lands. Frenzied cries of rage rise from the creatures of Doomfire. The army's fury has been broken, and the Norrathians stand victorious amid the flames!";
local READY_TEXT = "The fires of Doomfire surge anew. Across the Burning Lands, the roar of an assembling army rises as the Guardian of Doomfire returns to defend the Tyrant's realm.";
local WARNING_PREFIX = "All of Doomfire trembles as the voice of Fennin Ro booms, ";
local WARNING_TEXT = {
    "Norrathians! Your hunger for power has carried you into my realm. You trespass among the flames of Doomfire, and you will answer for it!",
    "You presume to command powers beyond your understanding. Feel the fury of these flames! Let Doomfire teach you the price of your arrogance!",
    "The balance of power will not bend to your greed! Every servant you strike down deepens my wrath. Their vengeance shall be mine!",
    "Hear the roar of Doomfire! Flame and Chaos answer to me! We will see what remains when my fury meets your ambition!",
    "My restraint is nearly spent! You have brought slaughter into my realm and called it courage. I shall repay every fallen servant in Norrathian blood!",
    "Your time dwindles, Norrathians! Face the Tyrant of Fire while your courage still holds. Soon the flames of Doomfire shall consume you!",
};

local EVENT_SECONDS, WARNING_SECONDS = 17500, 2700; -- original budget; no spawn extension
local WATCHDOG_MS, MISSING_GRACE, SAVE_SECONDS = 1000, 10, 5;
local PHASE_NAMES = { [0]="Ready", "Army", "Commanders", "Council", "Fennin", "Retry", "Success" };
local phase, attempt, remaining, clockAt, nextWarning, cooldownUntil, totalKills = 0,0,EVENT_SECONDS,0,1,0,0;
local paused, initialized, ownState, cooldownReleased, building = false,false,false,false,false;
local records, missingSince, notices = {},{},{};
local encounter, creatingSlot;
local lastSaved = 0;
local stateKey = "fennin-recovery-v1-" .. tostring(eq.get_zone_guild_id());
local EVENT_TYPES, ELITE_POINTS, PLANS = {},{},{};
for _,t in ipairs(TRASH_TYPES) do EVENT_TYPES[t]=true; end
EVENT_TYPES[FENNIN_TYPE]=true;
for _,id in ipairs(ELITE_SPAWNIDS) do ELITE_POINTS[id]=true; end
for p=1,4 do
    PLANS[p]={};local types={};for t in pairs(SPAWNS[p]) do types[#types+1]=t;end;table.sort(types);
    for _,t in ipairs(types) do for _,loc in ipairs(SPAWNS[p][t]) do
        PLANS[p][#PLANS[p]+1]={typ=t,loc=loc};
    end end
end
local Fail, Initialize, Advance, StartStage;
local function Now() return os.time(); end
local function Active() return phase>=1 and phase<=4; end
local function Live(npc) return npc and npc.valid and npc:GetID()~=0 and npc:GetHP()>0 and not npc:IsCorpse(); end
local function Name(npc) return npc and npc.valid and npc:GetCleanName() or "Unknown NPC"; end
local function RP(text) eq.zone_emote(13,text); end
local function CountKills()
    local n=0;for _,r in ipairs(records) do if r.dead then n=n+1;end end;return n;
end
local function Log(kind,text)
    local line=string.format("[Fennin guild=%s attempt=%d phase=%s kills=%d/%d total=%d] [%s] %s",
        tostring(eq.get_zone_guild_id()),attempt,PHASE_NAMES[phase],CountKills(),#records,totalKills,kind,text);
    eq.debug(line);
    -- luabind's iterator does not retain its vector-owning list object.
    local clients=eq.get_entity_list():GetClientList();
    for client in clients.entries do
        if client.valid and client:GetGM() then client:Message(15,line);end
    end
end
local function Notice(key,kind,text)
    if not notices[key] or Now()-notices[key]>=30 then notices[key]=Now();Log(kind,text);end
end
local function Save(force)
    if not ownState or (not force and Now()-lastSaved<SAVE_SECONDS) then return;end
    local list={};for slot,r in ipairs(records) do
        list[#list+1]=table.concat({slot,r.typ,r.entity,r.dead and 1 or 0},":");
    end
    eq.set_data(stateKey,table.concat({phase,attempt,remaining,clockAt,paused and 1 or 0,
        nextWarning,cooldownUntil,totalKills,table.concat(list,";")},"|"));lastSaved=Now();
end
local function Load()
    local value=eq.get_data(stateKey);if not value or value=="" then return false;end
    local f={};for part in (value.."|"):gmatch("(.-)|") do f[#f+1]=part;end
    if #f~=9 then return false,"Malformed saved encounter state";end
    for i=1,8 do if not f[i]:match("^%d+$") then return false,"Non-numeric saved encounter state";end end
    local p,a,r,c,pa,w,cd,k=tonumber(f[1]),tonumber(f[2]),tonumber(f[3]),tonumber(f[4]),tonumber(f[5]),tonumber(f[6]),tonumber(f[7]),tonumber(f[8]);
    if p>6 or r>EVENT_SECONDS or pa>1 or w<1 or w>7 or k>66 then return false,"Invalid saved encounter bounds";end
    local function bad(reason)
        return false,reason,{phase=p,attempt=a,cooldownUntil=cd,totalKills=k};
    end
    local loaded={};
    if f[9]~="" then for part in f[9]:gmatch("[^;]+") do
        local slot,t,id,dead=part:match("^(%d+):(%d+):(%d+):([01])$");
        slot,t,id=tonumber(slot),tonumber(t),tonumber(id);
        if not slot or slot~=#loaded+1 or id==0 then return bad("Interrupted or invalid phase creation");end
        loaded[slot]={typ=t,entity=id,dead=dead=="1"};
    end end
    if p>=1 and p<=4 then
        if #loaded~=#PLANS[p] then return bad("Saved phase size differs from its spawn plan");end
        local expected=0;for prior=1,p-1 do expected=expected+#PLANS[prior];end
        for slot,row in ipairs(loaded) do
            if row.typ~=PLANS[p][slot].typ then return bad("Saved phase NPC differs from its spawn plan");end
            if row.dead then expected=expected+1;end
        end
        if expected~=k then return bad("Saved confirmed-kill count differs from phase progress");end
    elseif #loaded~=0 then return bad("Inactive encounter retained phase actors");end
    phase,attempt,remaining,clockAt,paused,nextWarning,cooldownUntil,totalKills=p,a,r,c,pa==1,w,cd,k;
    records=loaded;ownState=true;return true;
end
local function Tagged(npc,slot,row)
    return npc and npc.valid and npc:GetNPCTypeID()==row.typ and npc:GetID()==row.entity and
        npc:GetEntityVariable("fennin_attempt")==tostring(attempt) and
        npc:GetEntityVariable("fennin_phase")==tostring(phase) and
        npc:GetEntityVariable("fennin_slot")==tostring(slot) and
        npc:GetEntityVariable("fennin_entity")==tostring(row.entity);
end
local function TaggedDeath(npc,slot,row)
    -- A corpse-producing death clears the live entity ID before this event.
    -- The immutable spawn identity on the dying NPC still proves ownership.
    return npc and npc.valid and npc:GetNPCTypeID()==row.typ and
        (npc:GetID()==0 or npc:GetID()==row.entity) and
        npc:GetEntityVariable("fennin_attempt")==tostring(attempt) and
        npc:GetEntityVariable("fennin_phase")==tostring(phase) and
        npc:GetEntityVariable("fennin_slot")==tostring(slot) and
        npc:GetEntityVariable("fennin_entity")==tostring(row.entity);
end
local function Tag(npc,slot,row)
    row.entity=npc:GetID();npc:SetEntityVariable("fennin_attempt",tostring(attempt));
    npc:SetEntityVariable("fennin_phase",tostring(phase));npc:SetEntityVariable("fennin_slot",tostring(slot));
    npc:SetEntityVariable("fennin_entity",tostring(row.entity));npc:SetEntityVariable("fennin_counted","0");
end
local function NPCIDs()
    -- Keep the list owner alive during iteration. Never retain its borrowed
    -- Lua_NPC elements after returning: only store immutable numeric IDs.
    local list=eq.get_entity_list():GetNPCList();local ids={};
    for npc in list.entries do
        if npc.valid then local id=npc:GetID();if id~=0 then ids[id]=id;end end
    end
    return ids;
end
local function Guardian()
    local spawn=eq.get_entity_list():GetSpawnByID(GUARDIAN_SPAWN_ID);
    if not spawn or not spawn.valid then return nil,nil;end
    local npc=spawn:GetNPC();return spawn,Live(npc) and npc or nil;
end
local function SetElites(enabled)
    local ok=true;
    for _,id in ipairs(ELITE_SPAWNIDS) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if not spawn or not spawn.valid then ok=false;Notice("elite-"..id,"ERROR","Missing elite spawnpoint "..id);
        elseif enabled then
            if not spawn:Enabled() then spawn:SetTimer(1);spawn:Enable();end
        elseif spawn:Enabled() or Live(spawn:GetNPC()) then spawn:Disable();end
    end
    return ok;
end
local function Cleanup()
    SetElites(false);
    local elist=eq.get_entity_list();
    for _,id in pairs(NPCIDs()) do
        local npc=elist:GetNPCByID(id);
        if Live(npc) and (EVENT_TYPES[npc:GetNPCTypeID()] or
            (npc:GetNPCTypeID()==ELITE_TYPE and ELITE_POINTS[npc:GetSpawnPointID()])) then
            eq.stop_all_timers(npc);npc:Depop();
        end
    end
    creatingSlot=nil;building=false;missingSince={};records={};
end
local function ApplyCooldown()
    local spawn,npc=Guardian();
    if not spawn then Notice("guardian-point","ERROR","Guardian spawnpoint missing; recovery will retry.");return false;end
    if npc and Now()<cooldownUntil then npc:Depop();end
    local delay=math.max(1,(cooldownUntil-Now())*1000);
    eq.update_spawn_timer(GUARDIAN_SPAWN_ID,delay);spawn:SetTimer(delay);spawn:Enable();
    cooldownReleased=Now()>=cooldownUntil;
    Notice("cooldown","RESET",string.format("Guardian spawnpoint enabled; %.1f hours of cooldown remain.",delay/3600000));
    return true;
end
local function Ready(announce)
    Cleanup();phase=0;remaining=EVENT_SECONDS;clockAt=0;paused=false;nextWarning=1;cooldownUntil=0;totalKills=0;
    ownState=true;cooldownReleased=false;Save(true);
    if announce then RP(READY_TEXT);Log("READY","Guardian returned; a fresh encounter can begin.");end
end
local function GuildOneRepop(npc)
    if eq.get_zone_guild_id()==1 and Live(npc) and npc:GetSpawnPointID()==GUARDIAN_SPAWN_ID and phase~=0 then
        -- A native Guardian already passed the server's quake/fresh-zone policy.
        Ready(false);Log("QUAKE","Native Guild 1 Guardian repop superseded old encounter state.");return true;
    end
    return false;
end
Fail=function(reason,force)
    if not Active() and not force then return;end
    phase=5;cooldownUntil=Now()+FAILURE_RETRY_TIME/1000;paused=false;ownState=true;cooldownReleased=false;
    Cleanup();Save(true);RP(FAILURE_TEXT);Log("FAIL",reason);ApplyCooldown();
end
local function FenninInCombat()
    if phase~=4 then return false;end
    local r=records[1];if not r or r.dead then return false;end
    local npc=eq.get_entity_list():GetNPCByNPCTypeID(FENNIN_TYPE);
    return Live(npc) and Tagged(npc,1,r) and npc:IsEngaged() or false;
end
local function UpdateClock(finishingCombat)
    if not Active() then return false;end
    local now=Now();local wasPaused=paused;local delta=math.max(0,now-clockAt);
    if not wasPaused then remaining=math.max(0,remaining-delta);end
    clockAt=now;paused=FenninInCombat();
    if wasPaused~=paused then
        Save(true);Log(paused and "PAUSE" or "RESUME",string.format("Fennin combat %s the shared clock; %.1f minutes remain.",paused and "paused" or "released",remaining/60));
    else Save(false);end
    if remaining==0 and not paused and not (finishingCombat and wasPaused) then
        Fail("The original shared event clock expired.");return false;
    end
    return true;
end
local function Warnings()
    if not Active() or paused then return;end
    local elapsed=EVENT_SECONDS-remaining;
    while WARNING_TEXT[nextWarning] and elapsed>=nextWarning*WARNING_SECONDS do
        RP(WARNING_PREFIX..'"'..WARNING_TEXT[nextWarning]..'"');
        Log("WARNING",string.format("%d-minute warning; %.1f minutes remain.",nextWarning*45,remaining/60));
        nextWarning=nextWarning+1;Save(true);
    end
end
local function EnsureInitialized() if not initialized then Initialize();end end
local function ArmSupervisor() eq.set_timer("watchdog",WATCHDOG_MS,encounter);end
StartStage=function(p)
    phase=p;records={};missingSince={};building=true;
    for slot,data in ipairs(PLANS[p]) do records[slot]={typ=data.typ,entity=0,dead=false};end
    Save(true);RP(PHASE_TEXT[p]);
    for slot,data in ipairs(PLANS[p]) do
        creatingSlot=slot;local loc=data.loc;
        local npc=eq.spawn2(data.typ,0,0,loc[2],loc[1],loc[3],loc[4]*0.7);
        creatingSlot=nil;
        if not Active() then building=false;return;end
        if not Live(npc) then Fail("Failed to spawn phase "..p.." slot "..slot.." type "..data.typ);return;end
        if records[slot].entity==0 then Tag(npc,slot,records[slot]);end
        if not Tagged(npc,slot,records[slot]) then Fail("Phase spawn returned an unverified/replaced NPC in slot "..slot);return;end
        Save(true);
    end
    building=false;
    if p==4 and not SetElites(true) then Fail("Fennin's elite spawnpoints could not be armed.");return;end
    Save(true);Log("PHASE","Stage created with "..#records.." individually tracked NPCs; shared clock was not extended.");
end
Advance=function()
    if building or not Active() or #records==0 then return;end
    for _,r in ipairs(records) do if not r.dead then return;end end
    if phase<4 then Log("COMPLETE","Every phase NPC has a confirmed death; advancing.");StartStage(phase+1);end
end
local function PhaseSpawn(e)
    if creatingSlot then
        local row=records[creatingSlot];
        if Active() and row and row.typ==e.self:GetNPCTypeID() and row.entity==0 then Tag(e.self,creatingSlot,row);return;end
    end
    EnsureInitialized();
    local slot=tonumber(e.self:GetEntityVariable("fennin_slot"));local row=slot and records[slot];
    if not Active() or not row or row.dead or not Tagged(e.self,slot,row) then
        e.self:Depop();Notice("foreign-spawn-"..e.self:GetNPCTypeID(),"WARN","Removed an untracked, duplicate or replaced phase NPC.");
    end
end
local function ConfirmDeath(npc)
    local slot=tonumber(npc:GetEntityVariable("fennin_slot"));local row=slot and records[slot];
    if not Active() or not row or row.dead or not TaggedDeath(npc,slot,row) or npc:GetEntityVariable("fennin_counted")=="1" then
        Notice("foreign-death-"..npc:GetNPCTypeID(),"WARN","Ignored a stale, duplicate or untracked death.");return false;
    end
    if not UpdateClock(npc:GetNPCTypeID()==FENNIN_TYPE) then return false;end
    npc:SetEntityVariable("fennin_counted","1");row.dead=true;missingSince[slot]=nil;totalKills=totalKills+1;
    if row.typ==FENNIN_TYPE then
        -- Persist victory and its full reuse in the same bucket write as the
        -- final confirmed kill; a reload cannot turn that kill into a failure.
        phase=6;cooldownUntil=Now()+SUCCESS_RESPAWN_TIME/1000;paused=false;cooldownReleased=false;records={};
    end
    Save(true);Log("KILL",Name(npc).." confirmed killed; slot "..slot..", entity "..row.entity..".");return true;
end
local function PhaseDeath(e) EnsureInitialized();if ConfirmDeath(e.self) then Advance();end end
local function FenninDeath(e)
    EnsureInitialized();if phase~=4 or not ConfirmDeath(e.self) then return;end
    Cleanup();Save(true);ApplyCooldown();RP(VICTORY_TEXT);Log("SUCCESS","Fennin confirmed killed; Guardian reuse remains 138 hours.");
    ProjectionEligibility.Spawn(PROJECTION_TYPE,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0,e.killer);
end
local function PhaseCombat(e)
    EnsureInitialized();local slot=tonumber(e.self:GetEntityVariable("fennin_slot"));local row=slot and records[slot];
    if not Active() or not row or row.dead or not Tagged(e.self,slot,row) then return;end
    if row.typ==FENNIN_TYPE then
        local before=paused;if not UpdateClock() then return;end
        if before~=paused then
            RP(paused and "The inferno erupts as Fennin Ro meets your challenge. \"Norrathians! You sought the power of a god. Now face the frenzy of Doomfire and the vengeance of its Tyrant!\"" or
                "Fennin Ro stands amid the raging flames, his laughter rolling across the scorched battlefield. \"Gather your courage, Norrathians! Doomfire still burns, and my vengeance awaits!\"");
        end
        Warnings();
    elseif e.joined then Log("ENGAGE",Name(e.self).." engaged; army combat does not pause the event clock.");end
end
local function GuardianSpawn(e)
    EnsureInitialized();if e.self:GetSpawnPointID()~=GUARDIAN_SPAWN_ID then return;end
    if GuildOneRepop(e.self) then return;end
    if phase==5 or phase==6 then
        if Now()<cooldownUntil then e.self:Depop();ApplyCooldown();Notice("early-guardian","WARN","Guardian appeared before cooldown ended; original cooldown restored.");
        else Ready(true);end
    elseif Active() then Fail("Guardian unexpectedly repopped during an active encounter.");
    end
end
local function GuardianCombat(e)
    EnsureInitialized();if phase==0 and e.joined and e.self:GetSpawnPointID()==GUARDIAN_SPAWN_ID then
        RP("The Guardian of Doomfire unleashes an echoing howl. Across the scorched battlefield, weapons clash and frenzied voices rise as the army of the Tyrant answers your challenge.");Log("ENGAGE","Guardian engaged.");
    end
end
local function GuardianDeath(e)
    EnsureInitialized();
    if e.self:GetSpawnPointID()~=GUARDIAN_SPAWN_ID then Notice("foreign-guardian","WARN","Ignored Guardian death outside the real event spawnpoint.");return;end
    if (phase==5 or phase==6) and Now()>=cooldownUntil then Ready(false);end
    if phase~=0 then
        Notice("guardian-death","WARN","Ignored Guardian death while an attempt/cooldown is already active.");
        if phase==5 or phase==6 then ApplyCooldown();end
        return;
    end
    local spawn=Guardian();if not spawn then Fail("Guardian spawnpoint missing at attempt start.",true);return;end
    Cleanup();attempt=attempt+1;remaining=EVENT_SECONDS;clockAt=Now();paused=false;nextWarning=1;totalKills=0;cooldownUntil=0;
    ownState=true;notices={};spawn:Disable(false);StartStage(1);ArmSupervisor();
end
local function EliteSpawn(e)
    EnsureInitialized();if not ELITE_POINTS[e.self:GetSpawnPointID()] then return;end
    if phase~=4 then
        local spawn=eq.get_entity_list():GetSpawnByID(e.self:GetSpawnPointID());if spawn and spawn.valid then spawn:Disable();end
    elseif Live(e.self) then e.self:SetEntityVariable("fennin_elite_attempt",tostring(attempt));end
end
Initialize=function()
    if initialized then return;end
    local saved,why,recovery=Load();local spawn,native=Guardian();
    if eq.get_zone_guild_id()==1 and native then
        -- Fresh-zone/quake admission also wins when no recovery bucket exists
        -- yet and actors from an older script are still present.
        Ready(false);Log("QUAKE","Native Guild 1 Guardian admitted a fresh encounter; old actors/state cleared.");
    elseif saved and Active() then
        if native then Fail("Reload found a new Guardian during an unfinished attempt.");
        else
            if spawn then spawn:Disable(false);end
            if phase==4 then if not SetElites(true) then Fail("Reload could not arm elite spawnpoints.");end else SetElites(false);end
            UpdateClock();
        end
    elseif saved and (phase==5 or phase==6) then Cleanup();ApplyCooldown();
    elseif not saved then
        if recovery and (recovery.phase==5 or recovery.phase==6) then
            -- A valid terminal header still owns its absolute cooldown even
            -- if obsolete/corrupt phase records cannot be recovered.
            phase=recovery.phase;attempt=recovery.attempt;cooldownUntil=recovery.cooldownUntil;
            totalKills=recovery.totalKills;paused=false;ownState=true;Cleanup();Save(true);ApplyCooldown();
            Log("ERROR",why.."; restored the recorded terminal cooldown without granting another attempt.");
        elseif recovery and recovery.phase>=1 and recovery.phase<=4 then
            attempt=recovery.attempt;totalKills=recovery.totalKills;
            Fail(why.."; interrupted active phase cannot be verified.",true);
        else
            local orphan=false;local elist=eq.get_entity_list();
            for _,id in pairs(NPCIDs()) do local npc=elist:GetNPCByID(id);
                if Live(npc) and EVENT_TYPES[npc:GetNPCTypeID()] then orphan=true;break;end
            end
            if orphan then attempt=attempt+1;Fail("Untracked pre-recovery encounter found; clearing it before another attempt.",true);
            else
                Cleanup();
                -- With no trustworthy state, do not shorten an unknown native cooldown.
                if why then Log("ERROR",why.."; preserving the native Guardian countdown.");end
            end
        end
    else Cleanup();end
    initialized=true;Save(true);Log("LOAD","Encounter-owned supervision active every second; phase progress, shared clock and cooldowns persist.");
end
local function Watchdog()
    EnsureInitialized();local spawn,native=Guardian();if GuildOneRepop(native) then return;end
    if Active() then
        if not UpdateClock() then return;end
        Warnings();
        if not spawn then Fail("Guardian spawnpoint disappeared during the attempt.");return;end
        if native then Fail("Guardian unexpectedly appeared during the attempt.");return;end
        if spawn:Enabled() then spawn:Disable(false);end
        if phase==4 then if not SetElites(true) then Fail("An elite spawnpoint disappeared during Fennin's stage.");return;end else SetElites(false);end
        local ids=NPCIDs();local elist=eq.get_entity_list();
        for slot,row in ipairs(records) do if not row.dead then
            local npc=ids[row.entity] and elist:GetNPCByID(row.entity);
            if not Live(npc) or not Tagged(npc,slot,row) then
                missingSince[slot]=missingSince[slot] or Now();
                if Now()-missingSince[slot]>=MISSING_GRACE then Fail("Phase NPC slot "..slot.." type "..row.typ.." disappeared/replaced without a confirmed kill.");return;end
            else missingSince[slot]=nil;end
        end end
        for _,id in pairs(ids) do
            local npc=elist:GetNPCByID(id);
            if Live(npc) and EVENT_TYPES[npc:GetNPCTypeID()] then
            local slot=tonumber(npc:GetEntityVariable("fennin_slot"));local row=slot and records[slot];
            if not row or row.dead or not Tagged(npc,slot,row) then npc:Depop();Notice("duplicate","WARN","Removed an untracked duplicate phase NPC.");end
        end end
        Advance();
        local controller=eq.get_entity_list():GetNPCByNPCTypeID(CONTROLLER_TYPE);
        if not Live(controller) then Notice("controller","WARN","Legacy invisible controller is absent; encounter-owned supervision continues.");end
    elseif phase==5 or phase==6 then
        Cleanup();
        if not spawn then Notice("guardian-point","ERROR","Guardian spawnpoint missing; recovery will retry.");return;end
        if Now()<cooldownUntil then
            if native then native:Depop();ApplyCooldown();Notice("early-guardian","WARN","Early Guardian suppressed without extending its cooldown.");
            elseif not spawn:Enabled() then ApplyCooldown();end
        elseif native then Ready(true);
        elseif not cooldownReleased then ApplyCooldown();
        else Notice("guardian-wait","WARN","Cooldown expired; waiting for native Guardian spawn/quake policy.");end
    elseif native and not ownState then ownState=true;Save(true);end
end
local function LegacySignal(e) Notice("legacy-signal-"..e.signal,"WARN","Ignored obsolete controller signal; confirmed kills and encounter supervision own progress.");end
local function LegacyTimer(e) eq.stop_timer(e.timer);Notice("legacy-timer-"..e.timer,"WARN","Stopped obsolete controller timer; encounter-owned deadline remains in control.");end
local function Safe(callback)
    return function(e)
        local ok,err=pcall(callback,e);
        if not ok then
            Log("ERROR","Lua callback failed: "..tostring(err));
            local recovered,why=pcall(function()
                if Active() then Fail("Lua callback error; recovering the Guardian spawnpoint.");
                elseif phase==5 or phase==6 then Cleanup();Save(true);ApplyCooldown();end
            end);
            if not recovered then Log("ERROR","Recovery also failed: "..tostring(why));end
            ArmSupervisor();
        end
    end;
end
function event_timer(e)
    if e.timer=="initialize" then eq.stop_timer(e.timer);Initialize();
    elseif e.timer=="watchdog" then Watchdog();end
end
function event_encounter_load(e)
    encounter=e.encounter;
    local function reg(event,typ,callback) eq.register_npc_event("Fennin",event,typ,Safe(callback));end
    reg(Event.spawn,GUARDIAN_TYPE,GuardianSpawn);reg(Event.combat,GUARDIAN_TYPE,GuardianCombat);reg(Event.death_complete,GUARDIAN_TYPE,GuardianDeath);
    for t in pairs(EVENT_TYPES) do
        reg(Event.spawn,t,PhaseSpawn);reg(Event.combat,t,PhaseCombat);
        reg(Event.death_complete,t,t==FENNIN_TYPE and FenninDeath or PhaseDeath);
    end
    reg(Event.spawn,ELITE_TYPE,EliteSpawn);
    reg(Event.signal,CONTROLLER_TYPE,LegacySignal);reg(Event.timer,CONTROLLER_TYPE,LegacyTimer);
    eq.set_timer("initialize",1000,encounter);ArmSupervisor();
end
local encounterTimer=event_timer;event_timer=Safe(encounterTimer);
