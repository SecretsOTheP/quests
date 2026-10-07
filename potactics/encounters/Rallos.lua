local ProjectionEligibility = require("projection_eligibility");

local CONTROLLER_TYPE = 214104; -- General_Invisible_Man
local UNTARGETABLE_TYPE = 214052; -- #Rallos_Zek_
local RALLOS_ZEK_TYPE = 214311; -- Rallos_Zek
local WARLORD_TYPE = 214312; -- Rallos_Zek_the_Warlord
local TALLON_TYPE = 214313; -- Tallon_Zek
local VALLON_TYPE = 214320; -- Vallon_Zek (level 73)
local VALLON_SPAWN_TYPE = 214319; -- Vallon_Zek (level 64, no slow mitigation version)
local BOAR_TYPE = 214287; -- A_Chaos_Boar
local WRAITH_TYPE = 214288; -- A_Chaos_Wraith
local BERIK_TYPE = 214056; -- Decorin_Berik
local GRUNHORK_TYPE = 214057; -- Decorin_Grunhork
local FLAYER_TYPE = 214084; -- Gindan_Flayer
local SHADOW_TYPE = 214086; -- Hendin_Shadow_Master
local ELITE_TYPE = 214289; -- A_Decorin_Elite
local PLANAR_PROJECTION_TYPE = 214322; -- A_Planar_Projection 
local CORPSE_TYPES = { 214007, 214008, 214009, 214010, 214011 };

local UNTARGETABLE_SPAWNID = 361379;
local BERIK_SPAWNID = 361190;
local GRUNHORK_SPAWNID = 361200;
local SUCCESS_RESPAWN_TIME = 237600 * 1000; -- 66 hours
local WRAITH_CORPSE_SPAWNIDS = { 361133, 361135, 361137, 361138, 361140 };
local ARENA_SPAWNIDS = { 
	361141, 361347,		-- two arena corpses; this will make the remaining five spawn wraiths
	361191, 361192, 361195, 361198, 361199, 361203, 361219,		-- initiates
	361197, 361205, 361211,		-- wraiths
	361166, 361167, 361202, 361209, 361212,		-- boars
	361176, 361196,		-- war crows
	361208,	361170, 361173	-- kobolds
};
local FLOOR_SPAWNS = {
	361366, 361369, 361371, 361372, 361375, 361378, 361382, 361383, 361386, 361388, 361389, 361392, 361394, 361396, 361398, 361187, 361367, 
	361368, 361370, 361373, 361374, 361376, 361377, 361380, 361381, 361384, 361385, 361387, 361390, 361391, 361393, 361395, 361397, 361399
};

-- Encounter-owned timers survive loss of the invisible controller NPC.
local encounter;
local phase, attempt = 0, 0; -- ready, brothers, upstairs, pit, retry, success
local phaseNames = { [0]="Ready", "Brothers", "Upstairs", "Pit", "Retry", "Success" };
local arenaEmpty = false;
local arenaRestore, roomSpawns, expected, deaths, arrived, idle = {}, {}, {}, {}, {}, {};
local guardDeaths, pending, missingSince, notices = {}, {}, {}, {};
local copiesSpawned=false;
local cooldownUntil, arenaUntil, cooldownReleased = 0, 0, false;
local killerName, killerGName = "", "";
local BALANCE_NAMELESS = 3230;
-- Lua arrival indices are zero-based: DB waypoint number 4 is e.wp == 3.
local BROTHER_HOMES = { [TALLON_TYPE]={319,-85,181.6,128}, [VALLON_TYPE]={319,110,181.6,0} };
-- Door-guard Y positions, with a 20-unit tolerance; retain the original X/Z limits.
local COUNCIL_MIN_Y, COUNCIL_MAX_Y = -306, 321;
local WATCHDOG_MS, MISSING_GRACE = 5000, 10;
local initialized=false;
local stateKey = "rallos-recovery-v3-" .. tostring(eq.get_zone_guild_id());

-- Zone::Repop clears all quest timers without unloading the encounter.
-- Guard activity must restore encounter supervision after a GM repop.
local function RestoreSupervision()
    eq.set_timer("watchdog",WATCHDOG_MS,encounter);
    if not initialized then eq.set_timer("initialize",1000,encounter); end
end
local function Now() return os.time(); end
local function Alive(t)
    local mob = eq.get_entity_list():GetMobByNpcTypeID(t);
    if mob and mob.valid and mob:GetID()~=0 and not mob:IsCorpse() then return mob; end
end
local function Log(kind, message)
    local text = string.format("[RZ guild=%s attempt=%d phase=%s] [%s] %s",
        tostring(eq.get_zone_guild_id()), attempt, phaseNames[phase] or "Unknown", kind, message);
    eq.debug(text);
    local clientList=eq.get_entity_list():GetClientList(); for client in clientList.entries do
        if client.valid and client:GetGM() then client:Message(15,text); end
    end
end
local function RP(message)
    eq.zone_emote(13,message); -- Chat::Red: permanent, visible encounter milestones.
end
local function Notice(key, kind, message)
    if not notices[key] or Now() - notices[key] >= 30 then
        notices[key] = Now(); Log(kind, message);
    end
end
local function SaveState()
    local arena, timers = {}, {};
    for id in pairs(arenaRestore) do arena[#arena+1] = tostring(id); end
    for t, v in pairs(idle) do
        timers[#timers+1] = string.format("%d:%d:%d", t, v.remaining, v.started or 0);
    end
    eq.set_data(stateKey, table.concat({phase, attempt, deaths[TALLON_TYPE] and 1 or 0,
        deaths[VALLON_TYPE] and 1 or 0, arrived[TALLON_TYPE] and 1 or 0,
        arrived[VALLON_TYPE] and 1 or 0, cooldownUntil, arenaUntil,
        guardDeaths[BERIK_TYPE] and 1 or 0, guardDeaths[GRUNHORK_TYPE] and 1 or 0,
        table.concat(arena, ","), table.concat(timers, ","), copiesSpawned and 1 or 0}, "|"));
end
local function LoadState()
    local text = eq.get_data(stateKey);
    if not text or text == "" then return false; end
    local fields = {};
    for field in (text .. "|"):gmatch("(.-)|") do fields[#fields+1] = field; end
    if #fields ~= 13 then Log("ERROR", "Invalid saved encounter state; inspecting NPCs instead."); return false; end
    for i=1,10 do if not tonumber(fields[i]) then return false; end end
    phase, attempt = tonumber(fields[1]), tonumber(fields[2]);
    if phase < 0 or phase > 5 then phase=0; return false; end
    deaths[TALLON_TYPE], deaths[VALLON_TYPE] = fields[3]=="1", fields[4]=="1";
    arrived[TALLON_TYPE], arrived[VALLON_TYPE] = fields[5]=="1", fields[6]=="1";
    cooldownUntil, arenaUntil = tonumber(fields[7]), tonumber(fields[8]);
    guardDeaths[BERIK_TYPE], guardDeaths[GRUNHORK_TYPE] = fields[9]=="1", fields[10]=="1";
    for id in fields[11]:gmatch("%d+") do arenaRestore[tonumber(id)]=true; end
    arenaEmpty = next(arenaRestore) ~= nil;
    copiesSpawned=fields[13]=="1";
    for t, remaining, started in fields[12]:gmatch("(%d+):(%d+):(%d+)") do
        idle[tonumber(t)]={ remaining=tonumber(remaining), started=tonumber(started)~=0 and tonumber(started) or nil };
    end
    return true;
end
local function Schedule(name, delay)
    pending[name] = attempt;
    eq.set_timer(name, delay, encounter);
end
local function Cancel(name)
    pending[name] = nil; eq.stop_timer(name, encounter);
end
local function CancelActions()
    for _,name in ipairs({"doors","brothers_killed","wraiths","respawn","poofadds"}) do Cancel(name); end
end
local function Track(mob)
    if mob and mob.valid then roomSpawns[mob:GetID()] = mob:GetNPCTypeID(); end
end
local function CleanupRoomAdds()
    local list=eq.get_entity_list();
    for id,t in pairs(roomSpawns) do
        local mob=list:GetMobID(id);
        if mob and mob.valid and not mob:IsCorpse() and mob:GetNPCTypeID()==t then mob:Depop(); end
    end
    roomSpawns={};
end
local function CleanupElites()
    local npcList=eq.get_entity_list():GetNPCList(); for npc in npcList.entries do
        if npc.valid and npc:GetSpawnPointID()==0 and npc:GetNPCTypeID()==ELITE_TYPE then npc:Depop(); end
    end
end
local function CleanupPitAdds()
    local npcList=eq.get_entity_list():GetNPCList(); for npc in npcList.entries do
        if npc.valid and npc:GetSpawnPointID()==0 and
            (npc:GetNPCTypeID()==BOAR_TYPE or npc:GetNPCTypeID()==WRAITH_TYPE) then npc:Depop(); end
    end
end
local function ApplyGuardCooldown()
    local remaining=math.max(1, (cooldownUntil-Now())*1000);
    local allOK=true;
    for _,id in ipairs({GRUNHORK_SPAWNID, BERIK_SPAWNID}) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if not spawn or not spawn.valid then
            allOK=false; Notice("guard-"..id,"ERROR","Guard spawnpoint "..id.." is missing; recovery will retry.");
        else
            eq.update_spawn_timer(id, remaining);
            spawn:SetTimer(remaining); -- Explicit Lua timer even if a stale NPC pointer remains.
            spawn:Enable();
            if not spawn:Enabled() then allOK=false; end
        end
    end
    if allOK then
        if phase==4 then RP("The War Room falls silent. The Decorins will return when the Warlord is ready to issue his challenge again."); end
        Log("RESET", string.format("Both guard spawnpoints enabled; cooldown remaining %.1f minutes.",remaining/60000));
    end
    return allOK;
end
local function EnsureUntargetable()
    if Alive(UNTARGETABLE_TYPE) then return true; end
    local mob=eq.spawn_from_spawn2(UNTARGETABLE_SPAWNID);
    if not mob or not mob.valid then
        Notice("placeholder","ERROR","Could not restore untargetable Rallos; recovery will retry."); return false;
    end
    return true;
end
local function HideUntargetable()
    local mob=Alive(UNTARGETABLE_TYPE);
    if mob then eq.stop_all_timers(mob); mob:Depop(); end
end
local function OutOfCouncil(npc)
    return npc:GetX()>820 or npc:GetY()<COUNCIL_MIN_Y or npc:GetY()>COUNCIL_MAX_Y or npc:GetZ()<115;
end
local function Leash(npc, home)
    local x,y,z=npc:GetX(),npc:GetY(),npc:GetZ();
    npc:InterruptSpell();
    npc:WipeHateList();
    npc:GMMove(home[1],home[2],home[3],home[4],true,true);
    -- Keep the requested spell, but enforce a clean encounter reset independently
    -- of cure/dispel eligibility, faction filtering, and dispel probability.
    local applied=npc:SpellOnTarget(BALANCE_NAMELESS,npc);
    if not applied then Log("WARN",npc:GetName().." rejected Balance of the Nameless; explicit effect cleanup will still run."); end
    npc:BuffFadeAll(); -- Full reset removes beneficial buffs as well as debuffs.
    npc:Heal(); -- Heal after recalculating bonuses from the cleared buffs.
    npc:WipeHateList();
    for _,spell in ipairs({{676,"Tashan"},{2885,"Funeral Pyre of Kelador"}}) do
        if npc:FindBuff(spell[1]) then Log("WARN",npc:GetName().." still has "..spell[2].." after explicit effect cleanup; reset needs investigation."); end
    end
    if npc:GetNPCTypeID()==RALLOS_ZEK_TYPE then
        RP("Rallos Zek laughs, shaking the very walls of Drunder! The War Room is the battlefield, not the halls of Drunder!");
    else
        RP(string.format('The voice of %s booms in your mind, threatening to split your skull apart. "Cowardly dog! Weak, cowardly Norrathian! You will face me here, or face me not at all!"',npc:GetCleanName()));
    end
    Log("LEASH",string.format("%s returned home from %.1f, %.1f, %.1f; aggro wiped, all buffs/debuffs cleared, HP restored; Balance of the Nameless applied: %s.",npc:GetName(),x,y,z,tostring(applied)));
end
local function ResetWarlord(npc)
    -- Wiping aggro can invoke combat(false) while a boundary reset is running.
    -- Never heal a dying Warlord or recursively start a second reset.
    if not npc.valid or npc:IsCorpse() or npc:GetHP()<=0 then return; end
    if npc:GetEntityVariable("rallos_resetting")=="1" then return; end
    npc:SetEntityVariable("rallos_resetting","1");
    Leash(npc,{705,0,-290,0});
    npc:SetEntityVariable("rallos_resetting","0");
end
local function Remaining(v)
    return math.max(0,v.remaining-(v.started and (Now()-v.started)*1000 or 0));
end
function FailureTimeout(pvpTimeout)
    if eq.get_zone_guild_id()>1 then return 9000000; end
    return pvpTimeout;
end
local function StartIdle(npc, timeout)
    local t=npc:GetNPCTypeID();
    local previous=idle[t];
    local remaining=previous and Remaining(previous) or timeout;
    idle[t]={remaining=remaining};
    if not npc:IsEngaged() then idle[t].started=Now(); end
    eq.stop_all_timers(npc);
    eq.set_timer("bounds",2000,npc);
    if not npc:IsEngaged() then eq.set_timer("depop",math.max(1,remaining),npc); end
    SaveState();
end
local function PauseIdle(npc)
    local v=idle[npc:GetNPCTypeID()];
    if v and v.started then v.remaining=Remaining(v); v.started=nil; end
    eq.stop_timer("depop"); SaveState();
end
local function ResumeIdle(npc)
    local v=idle[npc:GetNPCTypeID()];
    if v and not v.started then
        v.started=Now(); eq.set_timer("depop",math.max(1,v.remaining)); SaveState();
    end
end
local function IdleExpired(npc)
    local v=idle[npc:GetNPCTypeID()];
    if not v or not v.started then eq.stop_timer("depop"); return false; end
    local remaining=Remaining(v);
    if remaining>0 then eq.set_timer("depop",remaining); return false; end
    return true;
end
function FailEncounter(reason)
    if phase<1 or phase>3 then return; end
    Log("FAIL",reason);
    phase=4; cooldownUntil=Now()+600; cooldownReleased=false;
    RP("The fury of the Warlord subsides. His challenge is withdrawn, and the fallen Decorins prepare to rally once more.");
    CancelActions(); idle={}; SaveState();
    for _,t in ipairs({TALLON_TYPE,VALLON_TYPE,RALLOS_ZEK_TYPE,WARLORD_TYPE}) do
        local mob=Alive(t); if mob then eq.stop_all_timers(mob); mob:Depop(); end
    end
    CleanupRoomAdds(); CleanupPitAdds();
    CleanupElites();
    RespawnArena(); arenaUntil=0;
    EnsureUntargetable(); ApplyGuardCooldown(); SaveState();
end
local function StartAttempt()
    if phase~=0 or not guardDeaths[BERIK_TYPE] or not guardDeaths[GRUNHORK_TYPE] then return; end
    RestoreSupervision();
    attempt=attempt+1; phase=1; expected={}; deaths={}; arrived={}; idle={}; missingSince={}; notices={}; copiesSpawned=false;
    SaveState();
    if not EnsureUntargetable() then FailEncounter("Missing untargetable Rallos at encounter start."); return; end
    for _,id in ipairs({BERIK_SPAWNID,GRUNHORK_SPAWNID}) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if not spawn or not spawn.valid then FailEncounter("Missing door-guard spawnpoint "..id); return; end
        spawn:Disable();
    end
    local tallon=eq.unique_spawn(TALLON_TYPE,31,0,621,-560,158,192);
    if phase~=1 then return; end
    local vallon=eq.unique_spawn(VALLON_TYPE,30,0,594,581,158,192);
    if phase~=1 then return; end
    if not tallon or not tallon.valid or not vallon or not vallon.valid then
        FailEncounter("Could not spawn both event brothers."); return;
    end
    expected[TALLON_TYPE],expected[VALLON_TYPE]=tallon:GetID(),vallon:GetID();
    tallon:SetRunning(true); vallon:SetRunning(true);
    CheckFloorSpawns();
    RP("The air of Drunder grows strangely cold as a rumble shakes through the fortress' walls. The Warlord stirs.");
    RP("Rallos Zek is unbothered by the death of his War Room guards -- he summoned Tallon and Vallon Zek to the War Room to deal with you!");
    Log("PHASE","Both door guards killed; Tallon and Vallon are traveling to the council room.");
end
local function AdvanceBrothers()
    if phase~=1 or not deaths[TALLON_TYPE] or not deaths[VALLON_TYPE] then return; end
    local mob=Alive(UNTARGETABLE_TYPE);
    if not mob then FailEncounter("Untargetable Rallos disappeared before the upstairs transition."); return; end
    phase=2; idle={}; SaveState(); Cancel("brothers_killed");
    local rz=eq.unique_spawn(RALLOS_ZEK_TYPE,0,0,mob:GetX(),mob:GetY(),mob:GetZ(),mob:GetHeading());
    if phase~=2 then return; end
    if not rz or not rz.valid then FailEncounter("Upstairs Rallos failed to spawn."); return; end
    expected[RALLOS_ZEK_TYPE]=rz:GetID();
    HideUntargetable(); -- Encounter timer owner cannot use depop_with_timer.
    RP("A tremor rumbles through the halls of Drunder. Terror wells up inside you as you struggle to keep your footing.");
    RP([[Rallos Zek takes notice at the death of his sons. The Warlord is impressed. "Come then, mortals! Raise your blades against the might of the Warlord!"]]);
    CheckFloorSpawns(); Log("PHASE","Both event brothers confirmed killed; upstairs Rallos spawned.");
end

function CheckFloorSpawns()

	local npc;
	for _, id in ipairs(FLOOR_SPAWNS) do

		npc = eq.get_entity_list():GetSpawnByID(id):GetNPC();
		if ( npc and npc.valid and npc:GetZ() < 118 ) then
			npc:BuffFadeAll();
			if ( npc:IsEngaged() ) then
				npc:WipeHateList();
			end
			npc:GMMove(npc:GetSpawnPointX(), npc:GetSpawnPointY(), npc:GetSpawnPointZ(), npc:GetSpawnPointH());
		end
	end
end

function ControllerTimerEvent(e)
    Notice("legacy-timer-"..e.timer,"WARN","Ignored obsolete controller timer "..e.timer.."; encounter timers own recovery.");
    eq.stop_timer(e.timer);
end

function ControllerSignalEvent(e)
    Notice("legacy-signal-"..e.signal,"WARN","Ignored obsolete controller signal "..e.signal.."; encounter callbacks own transitions.");
end

function UntargetableSpawnEvent(e)
    if phase==2 or phase==3 then
        e.self:Depop();
        Notice("placeholder-active","WARN","Removed untargetable Rallos during an active Rallos fight; encounter state retained.");
    elseif phase==1 then
        Notice("placeholder-brothers","WARN","Untargetable Rallos spawned during the brother phase; encounter state retained.");
    end
end

function DoorGuardDeathEvent(e)
    RestoreSupervision();
    if phase~=0 then Log("WARN","Guard death ignored while encounter is not ready."); return; end
    local t=e.self:GetNPCTypeID(); guardDeaths[t]=true;
    if e.killer and e.killer.valid then killerName=e.killer:GetName(); end
    RP((t==BERIK_TYPE and "Decorin Berik" or "Decorin Grunhork").." falls at the gates of the War Room. The Warlord watches in silence.");
    Log("KILL",e.self:GetName().." killed; waiting for both door guards.");
    SaveState(); Schedule("doors",3000);
end

function DoorGuardSpawnEvent(e)
    RestoreSupervision();
    local t=e.self:GetNPCTypeID();
    if phase==0 and guardDeaths[t] then
        guardDeaths[t]=nil; SaveState();
        Log("RESET",e.self:GetCleanName().." returned to its post; its previous kill no longer counts toward starting the encounter.");
    end
    eq.set_timer("bounds",2000);
end

function DoorGuardTimerEvent(e)
    if e.timer=="bounds" and OutOfCouncil(e.self) then
        Leash(e.self,{e.self:GetSpawnPointX(),e.self:GetSpawnPointY(),e.self:GetSpawnPointZ(),e.self:GetSpawnPointH()});
    end
end

function BrotherDeathEvent(e)
    if phase~=1 then return; end
    local t=e.self:GetNPCTypeID();
    deaths[t]=true; idle[t]=nil; missingSince[t]=nil;
    RP((t==TALLON_TYPE and "Tallon Zek" or "Vallon Zek").." has fallen. The halls of Drunder tremble at the death of a son of War.");
    SaveState(); Log("KILL",e.self:GetName().." confirmed killed.");
    Schedule("brothers_killed",3000);
end

function SpawnRoomAdd(t,x,y,h)
    if phase~=1 then return; end
    local mob=eq.spawn2(t,0,0,x,y,178,h);
    if not mob or not mob.valid then FailEncounter("Failed to spawn room add type "..t); return; end
    Track(mob); mob:SetSpecialAbility(49,1); return mob;
end

function RoomAddTimerEvent(e)
    if (phase==1 or phase==2) and e.timer=="bounds" and roomSpawns[e.self:GetID()]==VALLON_SPAWN_TYPE and OutOfCouncil(e.self) then
        Leash(e.self,BROTHER_HOMES[VALLON_TYPE]);
    end
end

function RoomAddSpawnEvent(e)
    if phase>=1 and phase<=3 and e.self:GetSpawnPointID()==0 and e.self:GetX()>0 and e.self:GetZ()>150 then
        Track(e.self);
        if e.self:GetNPCTypeID()==VALLON_SPAWN_TYPE then e.self:SetEntityVariable("rallos_copy","1"); end
    end
end

function VallonWaypointArrive(e)
	if ( e.wp == 3 and phase == 1 and not arrived[e.self:GetNPCTypeID()] ) then
		arrived[e.self:GetNPCTypeID()]=true; SaveState();
        RP("Vallon Zek enters the War Room and prepares to defend the honor of his father.");
		Log("ARRIVE",e.self:GetName().." reached the council room; travel protection removed.");
		e.self:SetSpecialAbility(24, 0); -- Will Not Aggro off
		e.self:SetSpecialAbility(35, 0); -- No Harm from Players off
		local mob;
		local t = FLAYER_TYPE;
		local y = 108;
		local h = 128;
		local x = { 384, 355, 277, 246 };
		for i = 1, 4 do
			mob = SpawnRoomAdd(t, x[i], y, h);
			if mob and mob.valid then eq.signal(214084, mob:GetID()); end; -- signal flayers so they'll split and not depop
		end
	end
end

function TallonWaypointArrive(e)
	if ( e.wp == 3 and phase == 1 and not arrived[e.self:GetNPCTypeID()] ) then
		arrived[e.self:GetNPCTypeID()]=true; SaveState();
        RP("Tallon Zek enters the War Room and prepares to defend the honor of his father.");
		Log("ARRIVE",e.self:GetName().." reached the council room; travel protection removed.");
		e.self:SetSpecialAbility(24, 0); -- Will Not Aggro off
		e.self:SetSpecialAbility(35, 0); -- No Harm from Players off
		local t = SHADOW_TYPE;
		local y = -91;
		local h = 0;
		local x = { 381, 350, 281, 246 };
		for i = 1, 4 do
			SpawnRoomAdd(t, x[i], y, h);
		end
	end
end

function BrotherSpawnEvent(e)
    if phase~=1 then Notice("unexpected-brother","ERROR","Event brother spawned outside the brother phase; removing it."); e.self:Depop(); return; end
    expected[e.self:GetNPCTypeID()]=e.self:GetID();
    if eq.get_zone_guild_id()==1 and not arrived[e.self:GetNPCTypeID()] then
        e.self:SetSpecialAbility(24,1); e.self:SetSpecialAbility(35,1);
    end
    StartIdle(e.self,FailureTimeout(1200000));
    eq.set_next_hp_event(50); e.self:CastToNPC():SetCastRateDetrimental(75);
    Log("SPAWN",string.format("%s spawned; idle allowance %.1f minutes.",e.self:GetName(),idle[e.self:GetNPCTypeID()].remaining/60000));
end

function BrotherTimerEvent(e)
    if phase~=1 then return; end
    local t=e.self:GetNPCTypeID();
    if e.timer=="bounds" and OutOfCouncil(e.self) and (arrived[t] or e.self:IsEngaged()) then
        Leash(e.self,BROTHER_HOMES[t]);
        if not arrived[t] then
            e.self:UpdateWaypoint(3);
            if t==TALLON_TYPE then TallonWaypointArrive({self=e.self,wp=3});
            else VallonWaypointArrive({self=e.self,wp=3}); end
        end
        ResumeIdle(e.self);
    elseif e.timer=="depop" and IdleExpired(e.self) then
        FailEncounter(e.self:GetName().." exhausted its idle allowance; this is a failure, not a kill.");
    end
end

function VallonHPEvent(e)
    if phase~=1 then return; end
	if ( e.hp_event == 50 and not copiesSpawned ) then
        copiesSpawned=true; SaveState();
        if OutOfCouncil(e.self) then Leash(e.self,BROTHER_HOMES[VALLON_TYPE]); ResumeIdle(e.self); end
		-- vallon adds are similar to the other vallon's, so reusing the type
		local mob = eq.spawn2(VALLON_SPAWN_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), e.self:GetHeading());
		if not mob or not mob.valid then FailEncounter("Vallon copy failed to spawn."); return; end
		Track(mob); mob:CastToNPC():SetBaseHP(55000);
		mob:Heal();
		mob:SetSpecialAbility(16, 1); -- unsnarable
		mob:SetSpecialAbility(12, 1); -- unslowable
		mob:SetSpecialAbility(13, 0); -- make mezable
		
		mob = eq.spawn2(VALLON_SPAWN_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), e.self:GetHeading());
		if not mob or not mob.valid then FailEncounter("Vallon copy failed to spawn."); return; end
		Track(mob); mob:CastToNPC():SetBaseHP(55000);
		mob:Heal();
		mob:SetSpecialAbility(16, 1); -- unsnarable
		CheckFloorSpawns(); -- anti-cheat
	end
end

function RallosSpawnEvent(e)
    if phase~=2 then Notice("unexpected-rallos","ERROR","Upstairs Rallos spawned outside phase 2; removing it."); e.self:Depop(); return; end
    expected[RALLOS_ZEK_TYPE]=e.self:GetID();
    StartIdle(e.self,FailureTimeout(1170000)); eq.set_next_hp_event(98);
    Log("SPAWN","Upstairs Rallos spawned; idle allowance starts when not engaged.");
end

function RallosCombatEvent(e)
    if phase~=2 then return; end
    if e.joined then
        PauseIdle(e.self); eq.set_timer("elites",20000);
        if e.self:GetHPRatio()>98 then eq.set_next_hp_event(98); end
        RP("Rallos Zek raises his axe as flames explode from it! The Warlord has accepted your challenge!");
        Log("ENGAGE","Upstairs Rallos engaged; idle timer stopped.");
    else
        eq.stop_timer("elites"); ResumeIdle(e.self);
        RP("Rallos Zek lowers his blade and waits. The War Room remains his battlefield.");
        Log("DISENGAGE","Upstairs Rallos disengaged; remaining idle timer resumed.");
    end
end

function RallosTimerEvent(e)
    if phase~=2 then return; end
    if e.timer=="bounds" and OutOfCouncil(e.self) then
        Leash(e.self,{500,20,194.125,64}); ResumeIdle(e.self);
    elseif e.timer=="elites" then
        eq.set_timer("elites",50000);
        if e.self:IsEngaged() then
            local a=eq.spawn2(ELITE_TYPE,0,0,1060,581,124,192);
            local b=eq.spawn2(ELITE_TYPE,0,0,1060,-560,124,192);
            if not a or not a.valid or not b or not b.valid then FailEncounter("Elite wave failed to spawn."); end
        end
    elseif e.timer=="depop" and IdleExpired(e.self) then FailEncounter("Upstairs Rallos exhausted its idle allowance."); end
end

function RallosDeathEvent(e)
    if phase==2 then FailEncounter("Upstairs Rallos died before completing the Warlord transition."); end
end

function RallosHPEvent(e)
    if phase~=2 then return; end
    if e.hp_event==98 then
        eq.set_next_hp_event(75); CheckFloorSpawns();
    elseif e.hp_event==75 then
        eq.set_next_hp_event(50); DespawnArena(); CheckFloorSpawns();
        Log("PHASE","Rallos reached 75%; arena spawnpoints disabled for the pit fight.");
    elseif e.hp_event==50 then
        phase=3; idle[RALLOS_ZEK_TYPE]=nil; SaveState();
        local warlord=eq.unique_spawn(WARLORD_TYPE,0,0,705,0,-290,0);
        if phase~=3 then return; end
        if not warlord or not warlord.valid then FailEncounter("Warlord failed to spawn at the 50% transition."); return; end
        expected[WARLORD_TYPE]=warlord:GetID();
        CleanupRoomAdds(); eq.stop_all_timers(e.self);
        RP("Rallos Zek leaps from the War Room into the cleared pit below! The force of his landing shakes the very foundations of Drunder, sending dust and stone crashing from the halls above.");
        RP('Rallos Zek shouts, "Come then! Come! Raise your blades against the Might and Fury of War! Warriors of Drunder! Watch as The Warlord shows you true might and battle!"');
        Log("PHASE","Rallos reached 50%; Warlord spawned in the pit and council-room adds removed.");
        eq.depop();
    end
end

function DespawnArena()
    if arenaEmpty then return; end
    RP([[The warriors of Drunder hear the clash of blades and the thunder of spells from the War Room. Rallos Zek's voice rises above the din: "Stand aside! I will deal with these mortals myself!" They rush into the higher halls, eager to claim a better vantage point and witness their Warlord's fury.]]);
    for _,id in ipairs(ARENA_SPAWNIDS) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if spawn and spawn.valid then
            if spawn:Enabled() then arenaRestore[id]=true; spawn:Disable(); end
        else Notice("arena-"..id,"ERROR","Missing arena spawnpoint "..id); end
    end
    arenaEmpty=true; SaveState();
end

function RespawnArena()
    local remaining={};
    for id in pairs(arenaRestore) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if spawn and spawn.valid then spawn:Enable(); else remaining[id]=true; Notice("arena-"..id,"ERROR","Arena restoration pending for missing spawnpoint "..id); end
    end
    arenaRestore=remaining; arenaEmpty=next(remaining)~=nil; SaveState();
end

function RespawnWraithCorpses()
    for _,id in ipairs(WRAITH_CORPSE_SPAWNIDS) do
        local spawn=eq.get_entity_list():GetSpawnByID(id);
        if not spawn or not spawn.valid then FailEncounter("Missing wraith-corpse spawnpoint "..id); return false; end
        spawn:SetTimer(1); spawn:Enable();
    end
    Log("SPAWN","Five wraith-corpse spawnpoints enabled; spawn timers triggered."); return true;
end

function WarlordSpawnEvent(e)
    if phase~=3 then Notice("unexpected-warlord","ERROR","Warlord spawned outside pit phase; removing it."); e.self:Depop(); return; end
    expected[WARLORD_TYPE]=e.self:GetID();
    if not RespawnWraithCorpses() then return; end
    StartIdle(e.self,FailureTimeout(1200000));
    Log("SPAWN","Warlord ready in the pit.");
end

function WarlordCombatEvent(e)
    if phase~=3 then return; end
    if e.joined then
        PauseIdle(e.self); eq.set_timer("twitch",55000); eq.stop_timer("checkhp");
        RP("The Warlord meets your challenge in the pit of Drunder. The might and fury of War are upon you!");
        Log("ENGAGE","Warlord engaged; idle timer stopped.");
    else
        eq.stop_timer("twitch"); Cancel("wraiths"); ResumeIdle(e.self);
        CleanupPitAdds();
        ResetWarlord(e.self);
        RP("The Warlord calls back his fallen champions and waits for challengers worthy of War.");
        Log("DISENGAGE","Warlord disengaged; pending pit wave canceled, pit adds removed, full reset applied to the living boss, idle timer resumed.");
    end
end

function WarlordTimerEvent(e)
    if phase~=3 then return; end

	if ( e.timer == "bounds" ) then
		if ( e.self:GetX() > 940 or e.self:GetX() < 439 or e.self:GetY() < -400 or e.self:GetY() > 410 or e.self:GetZ() > -250 ) then
		
			if ( e.self:IsEngaged() ) then
				local target = e.self:GetTarget();
				if ( target and target.valid ) then
					RP( "Rallos begins to laugh, causing the earth to rumble around you. 'Enough of this foolishness!  The warlord has better things to do then chase petty mortals all day!'");
					e.self:CastSpell(982, target:GetID());
				end
			end

            ResetWarlord(e.self);
            ResumeIdle(e.self);
		end
	
	elseif ( e.timer == "checkhp" ) then
		if ( e.self:GetHP() == e.self:GetMaxHP() ) then
			eq.stop_timer(e.timer);
			eq.depop_all(BOAR_TYPE);
			eq.depop_all(WRAITH_TYPE);
		end
	
	elseif ( e.timer == "twitch" ) then
		RP( "The corpses of the unworthy begin to twitch and spasm as fallen champions rise again to try and prove their worth to the might and glory of Rallos Zek!");
		Schedule("wraiths",10000);
		
	elseif ( e.timer == "depop" and IdleExpired(e.self) ) then
		FailEncounter("Warlord exhausted its idle allowance.");
	end
end

function WarlordDeathEvent(e)
    if phase~=3 then return; end
    phase=5; idle={}; CancelActions(); cooldownUntil=Now()+SUCCESS_RESPAWN_TIME/1000;
    cooldownReleased=false; arenaUntil=Now()+1800; SaveState();
    CleanupRoomAdds(); CleanupPitAdds(); CleanupElites();
    ApplyGuardCooldown();
    ProjectionEligibility.Spawn(PLANAR_PROJECTION_TYPE,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),0,e.killer);
    RP("Rallos Zek, the Warlord, has fallen! The halls of Drunder echo with cries of rage as the very foundations of the Plane of Tactics tremble and quake as his colossal form crashes to the ground before the might of the Norrathians!");
    Log("SUCCESS","Warlord confirmed killed; guards on 66-hour cooldown, arena restoration in 30 minutes.");
end

function EliteSpawnEvent(e)
    if phase~=2 and phase~=3 then e.self:Depop(); return; end
	eq.set_timer("depop", 1200000);
	eq.set_timer("aggro", 10000);
	eq.set_timer("check", 10000);
end

function EliteTimerEvent(e)
	if ( e.timer == "aggro" ) then
		
		local rz = eq.get_entity_list():GetMobByNpcTypeID(RALLOS_ZEK_TYPE);
		local t;
		if ( not rz or not rz.valid ) then
			rz = eq.get_entity_list():GetMobByNpcTypeID(WARLORD_TYPE);	-- RZTW sometimes gets elites running to him.  happens on Live and AK
		end
		if ( rz and rz.valid ) then
			if ( rz:IsEngaged() ) then
				t = rz:GetHateRandomClient(400);		-- add random hater from RZ's list to elite's list
			end
			e.self:SetRunning(true);
			e.self:MoveTo(rz:GetX(), rz:GetY(), rz:GetZ(), -1, true);
			if ( t and t.valid ) then
				e.self:AddToHateList(t, 20);
				eq.stop_timer(e.timer);
			end
		end
	
	elseif ( e.timer == "check" and phase == 2 ) then
		-- if elite pulled downstairs
		if ( e.self:GetZ() < 118 ) then
			local rz = eq.get_entity_list():GetMobByNpcTypeID(RALLOS_ZEK_TYPE);
			if ( rz and rz.valid ) then
				e.self:GMMove(rz:GetX(), rz:GetY(), rz:GetZ(), 0);
				e.self:WipeHateList();
			end
		end
	
	elseif ( e.timer == "depop" ) then
		eq.depop();
	end
end

function SpawnPitWave()

	if ( phase ~= 3 or not Alive(WARLORD_TYPE) or not Alive(WARLORD_TYPE):IsEngaged() ) then
		return;
	end
	
	local npcList = eq.get_entity_list():GetNPCList();
	local mob, rng;
	local typesMap = {};
	
	for _, t in ipairs(CORPSE_TYPES) do
		typesMap[t] = 1;
	end

	for i = 1, 2 do
		mob = eq.spawn2(BOAR_TYPE, 0, 0, 705, 0, -290, 0);
		if not mob or not mob.valid then FailEncounter("Pit boar failed to spawn."); return; end
		rng = math.random(5, 11);
		mob:SetWalkspeed(rng / 10.0);
		mob:SetRunspeed(rng / 10.0 * 2.5);
	end
	
	for npc in npcList.entries do
	
		if ( npc.valid ) then
		
			if ( typesMap[npc:GetNPCTypeID()] ) then
				mob = eq.spawn2(WRAITH_TYPE, 0, 0, npc:GetX(), npc:GetY(), npc:GetZ()+5, math.random(1, 255));
				if not mob or not mob.valid then FailEncounter("Pit wraith failed to spawn."); return; end
				rng = math.random(5, 11);
				mob:SetWalkspeed(rng / 10.0);
				mob:SetRunspeed(rng / 10.0 * 2.5);
				npc:Depop(true);
			end
		end			
	end
end

function PitAddSpawnEvent(e)
	eq.set_timer("depop", 600000);
	eq.set_timer("move", 10);
	eq.set_timer("bounds", 6000);
end

function PitAddTimerEvent(e)

	if ( e.timer == "move" ) then
		eq.set_timer(e.timer, 6000);
		
		local rz = Alive(WARLORD_TYPE);
		if ( rz and not e.self:IsEngaged() ) then
			e.self:MoveTo(rz:GetX(), rz:GetY(), rz:GetZ(), -1, true);
		end
		
	elseif ( e.timer == "bounds" ) then

		if ( e.self:GetX() > 940 or e.self:GetX() < 439 or e.self:GetY() < -400 or e.self:GetY() > 410 or e.self:GetZ() > -250 ) then
		
			e.self:GMMove(705, 0, -290, 0);
			e.self:SpellOnTarget(BALANCE_NAMELESS, e.self); -- Direct self application avoids group faction filtering.
			e.self:WipeHateList();
			eq.set_timer("move", 10);
		end
	
	elseif ( e.timer == "depop" ) then
		eq.depop();
	end
end

function DepopCombatEvent(e)
    local t=e.self:GetNPCTypeID();
    if t==TALLON_TYPE or t==VALLON_TYPE then
        if phase~=1 then return; end
        if e.joined then PauseIdle(e.self); else ResumeIdle(e.self); end
        local name=t==TALLON_TYPE and "Tallon Zek" or "Vallon Zek";
        RP(name..(e.joined and " meets your challenge. Steel and sorcery clash in the War Room!" or " withdraws from battle and waits for you in the War Room."));
        Log(e.joined and "ENGAGE" or "DISENGAGE",e.self:GetName()..(e.joined and " engaged; idle timer stopped." or " disengaged; remaining idle timer resumed."));
    elseif e.joined then eq.pause_timer("depop"); else eq.resume_timer("depop"); end
end

local function Reattach(npc, timeout)
    expected[npc:GetNPCTypeID()]=npc:GetID();
    StartIdle(npc,timeout);
    local t=npc:GetNPCTypeID();
    if t==RALLOS_ZEK_TYPE then
        eq.signal(t,9001); -- HP event setters need NPC callback ownership.
        if npc:IsEngaged() then eq.set_timer("elites",20000,npc); end
    elseif t==WARLORD_TYPE and npc:IsEngaged() then eq.set_timer("twitch",55000,npc);
    elseif t==TALLON_TYPE or t==VALLON_TYPE then
        if npc:GetY()>=COUNCIL_MIN_Y and npc:GetY()<=COUNCIL_MAX_Y then arrived[t]=true; end
        if arrived[t] then npc:SetSpecialAbility(24,0); npc:SetSpecialAbility(35,0); end
        if t==VALLON_TYPE then eq.signal(t,9001); end
        npc:CastToNPC():SetCastRateDetrimental(75);
    end
end
function BossRecoverySignalEvent(e)
    if e.signal~=9001 or expected[e.self:GetNPCTypeID()]~=e.self:GetID() then return; end
    local t=e.self:GetNPCTypeID();
    if t==RALLOS_ZEK_TYPE and phase==2 then
        local hp=e.self:GetHPRatio();
        if hp<=50 then RallosHPEvent({self=e.self,hp_event=50});
        else eq.set_next_hp_event(hp>98 and 98 or (hp>75 and 75 or 50)); end
    elseif t==VALLON_TYPE and phase==1 and not copiesSpawned and e.self:GetHPRatio()>50 then eq.set_next_hp_event(50); end
end
local function Initialize()
    local saved=LoadState();
    if not saved then
        if Alive(WARLORD_TYPE) then phase=3;
        elseif Alive(RALLOS_ZEK_TYPE) then phase=2;
        elseif Alive(TALLON_TYPE) or Alive(VALLON_TYPE) then phase=1; end
        if phase>0 then attempt=attempt+1; Log("WARN","Adopting an existing encounter without saved kill history; missing brothers will cause recovery."); end
    end
    local npcList=eq.get_entity_list():GetNPCList(); for npc in npcList.entries do
        if npc.valid and npc:GetSpawnPointID()==0 and npc:GetX()>0 and npc:GetZ()>150 and
            (npc:GetNPCTypeID()==FLAYER_TYPE or npc:GetNPCTypeID()==SHADOW_TYPE or npc:GetNPCTypeID()==VALLON_SPAWN_TYPE) then
            Track(npc);
            if npc:GetNPCTypeID()==VALLON_SPAWN_TYPE then npc:SetEntityVariable("rallos_copy","1"); end
        end
    end
    if phase>=1 and phase<=3 then
        if phase==2 or phase==3 then HideUntargetable(); end
        local types=phase==1 and {TALLON_TYPE,VALLON_TYPE} or {phase==2 and RALLOS_ZEK_TYPE or WARLORD_TYPE};
        for _,t in ipairs(types) do
            local npc=Alive(t);
            if npc then Reattach(npc,FailureTimeout(t==RALLOS_ZEK_TYPE and 1170000 or 1200000));
            elseif not deaths[t] then FailEncounter("Reload recovery found a missing phase NPC: "..t); break; end
        end
        if phase==1 and deaths[TALLON_TYPE] and deaths[VALLON_TYPE] then Schedule("brothers_killed",3000); end
    elseif phase==4 or phase==5 then
        EnsureUntargetable(); ApplyGuardCooldown();
    else
        for _,t in ipairs({BERIK_TYPE,GRUNHORK_TYPE}) do
            local npc=Alive(t); if npc then guardDeaths[t]=nil; eq.set_timer("bounds",2000,npc); end
        end
        local a=eq.get_entity_list():GetSpawnByID(BERIK_SPAWNID);
        local b=eq.get_entity_list():GetSpawnByID(GRUNHORK_SPAWNID);
        if a and a.valid and b and b.valid and (not a:Enabled() or not b:Enabled()) then
            phase=1; FailEncounter("No active boss, but door-guard spawnpoints were disabled on initialization.");
        elseif guardDeaths[BERIK_TYPE] and guardDeaths[GRUNHORK_TYPE] then StartAttempt(); end
    end
    initialized=true; SaveState(); Log("LOAD","Recovery script loaded; encounter-owned supervision active every five seconds.");
end
local function Watchdog()
    if not initialized then return; end
    if arenaUntil>0 and Now()>=arenaUntil then
        RespawnArena();
        if not arenaEmpty then
            arenaUntil=0; SaveState();
            RP("The creatures of Drunder return to the pit. The arena stirs once more.");
            Log("RESTORE","Arena spawnpoints restored after victory.");
        end
    elseif phase==4 and arenaEmpty then RespawnArena(); end
    if phase>=1 and phase<=3 then
        if phase==2 or phase==3 then HideUntargetable(); end
        local types=phase==1 and {TALLON_TYPE,VALLON_TYPE} or {phase==2 and RALLOS_ZEK_TYPE or WARLORD_TYPE};
        for _,t in ipairs(types) do
            local mob=Alive(t);
            if deaths[t] then missingSince[t]=nil;
            elseif not mob or (expected[t] and mob:GetID()~=expected[t]) then
                missingSince[t]=missingSince[t] or Now();
                if Now()-missingSince[t]>=MISSING_GRACE then FailEncounter("Supervisor detected missing/replaced phase NPC "..t.." without a recorded kill."); return; end
            else
                missingSince[t]=nil;
                if phase==1 and not arrived[t] and idle[t] and idle[t].started and Now()-idle[t].started>180 then
                    Notice("travel-"..t,"WARN",mob:GetName().." has not reached council-room waypoint 3; check its path/grid. The normal idle deadline remains in effect.");
                end
            end
        end
        if phase==1 and deaths[TALLON_TYPE] and deaths[VALLON_TYPE] then AdvanceBrothers(); end
    elseif phase==4 or phase==5 then
        EnsureUntargetable();
        for _,id in ipairs({BERIK_SPAWNID,GRUNHORK_SPAWNID}) do
            local spawn=eq.get_entity_list():GetSpawnByID(id);
            if not spawn or not spawn.valid then Notice("guard-"..id,"ERROR","Missing guard spawnpoint "..id);
            elseif not spawn:Enabled() then ApplyGuardCooldown(); break; end
            local npc=spawn and spawn.valid and spawn:GetNPC();
            if npc and npc.valid and Now()<cooldownUntil then
                npc:Depop(); spawn:SetTimer(math.max(1,(cooldownUntil-Now())*1000));
                Notice("early-guard-"..id,"WARN","Guard appeared before cooldown expired; cooldown restored.");
            end
        end
        if Now()>=cooldownUntil then
            if not cooldownReleased then
                cooldownReleased=true;
                for _,id in ipairs({BERIK_SPAWNID,GRUNHORK_SPAWNID}) do
                    local spawn=eq.get_entity_list():GetSpawnByID(id);
                    if spawn and spawn.valid and not spawn:NPCPointerValid() then spawn:SetTimer(1); spawn:Enable(); end
                end
            end
            if Alive(BERIK_TYPE) and Alive(GRUNHORK_TYPE) then
                phase=0; guardDeaths={}; deaths={}; arrived={}; expected={}; cooldownUntil=0;
                RP("The Decorins return to their posts. The War Room stands ready for those who would challenge the Warlord again.");
                SaveState(); Log("READY","Both door guards spawned; next encounter can begin.");
            else Notice("guards-pending","WARN","Cooldown expired; waiting for both guard NPCs to spawn. Spawn conditions/server policy may still block them."); end
        end
    end
end
function event_timer(e)
    if e.timer=="initialize" then eq.stop_timer(e.timer); Initialize(); return; end
    if e.timer=="watchdog" then Watchdog(); return; end
    local token=pending[e.timer]; Cancel(e.timer);
    if token~=attempt then return; end
    if e.timer=="doors" then StartAttempt();
    elseif e.timer=="brothers_killed" then AdvanceBrothers();
    elseif e.timer=="wraiths" then SpawnPitWave(); end
end
local function SafeHandler(callback)
    return function(e)
        local ok,err=pcall(callback,e);
        if not ok then
            Log("ERROR","Lua callback failed: "..tostring(err));
            local recovered,recoveryError=pcall(FailEncounter,"Lua callback error; initiating guard recovery.");
            if not recovered then Log("ERROR","Recovery also failed: "..tostring(recoveryError)); end
            if not initialized and e.timer=="initialize" then eq.set_timer("initialize",5000,encounter); end
        end
    end;
end

function event_encounter_load(e)
    encounter=e.encounter;

	eq.register_npc_event("Rallos", Event.timer, CONTROLLER_TYPE, SafeHandler(ControllerTimerEvent));
	eq.register_npc_event("Rallos", Event.signal, CONTROLLER_TYPE, SafeHandler(ControllerSignalEvent));

	eq.register_npc_event("Rallos", Event.spawn, UNTARGETABLE_TYPE, SafeHandler(UntargetableSpawnEvent));
	
	eq.register_npc_event("Rallos", Event.death_complete, BERIK_TYPE, SafeHandler(DoorGuardDeathEvent));
	eq.register_npc_event("Rallos", Event.death_complete, GRUNHORK_TYPE, SafeHandler(DoorGuardDeathEvent));

	eq.register_npc_event("Rallos", Event.death_complete, TALLON_TYPE, SafeHandler(BrotherDeathEvent));
	eq.register_npc_event("Rallos", Event.death_complete, VALLON_TYPE, SafeHandler(BrotherDeathEvent));
	eq.register_npc_event("Rallos", Event.spawn, TALLON_TYPE, SafeHandler(BrotherSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, TALLON_TYPE, SafeHandler(BrotherTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, TALLON_TYPE, SafeHandler(DepopCombatEvent));
	eq.register_npc_event("Rallos", Event.spawn, VALLON_TYPE, SafeHandler(BrotherSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, VALLON_TYPE, SafeHandler(BrotherTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, VALLON_TYPE, SafeHandler(DepopCombatEvent));
	eq.register_npc_event("Rallos", Event.hp, VALLON_TYPE, SafeHandler(VallonHPEvent));
	
	eq.register_npc_event("Rallos", Event.waypoint_arrive, TALLON_TYPE, SafeHandler(TallonWaypointArrive));
	eq.register_npc_event("Rallos", Event.waypoint_arrive, VALLON_TYPE, SafeHandler(VallonWaypointArrive));
	
	eq.register_npc_event("Rallos", Event.spawn, RALLOS_ZEK_TYPE, SafeHandler(RallosSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, RALLOS_ZEK_TYPE, SafeHandler(RallosTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, RALLOS_ZEK_TYPE, SafeHandler(RallosCombatEvent));
	eq.register_npc_event("Rallos", Event.hp, RALLOS_ZEK_TYPE, SafeHandler(RallosHPEvent));
	
	eq.register_npc_event("Rallos", Event.spawn, ELITE_TYPE, SafeHandler(EliteSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, ELITE_TYPE, SafeHandler(EliteTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, ELITE_TYPE, SafeHandler(DepopCombatEvent));

	eq.register_npc_event("Rallos", Event.spawn, WARLORD_TYPE, SafeHandler(WarlordSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, WARLORD_TYPE, SafeHandler(WarlordTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, WARLORD_TYPE, SafeHandler(WarlordCombatEvent));
	eq.register_npc_event("Rallos", Event.death_complete, WARLORD_TYPE, SafeHandler(WarlordDeathEvent));

	eq.register_npc_event("Rallos", Event.spawn, WRAITH_TYPE, SafeHandler(PitAddSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, WRAITH_TYPE, SafeHandler(PitAddTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, WRAITH_TYPE, SafeHandler(DepopCombatEvent));
	eq.register_npc_event("Rallos", Event.spawn, BOAR_TYPE, SafeHandler(PitAddSpawnEvent));
	eq.register_npc_event("Rallos", Event.timer, BOAR_TYPE, SafeHandler(PitAddTimerEvent));
	eq.register_npc_event("Rallos", Event.combat, BOAR_TYPE, SafeHandler(DepopCombatEvent));

    eq.register_npc_event("Rallos",Event.spawn,BERIK_TYPE,SafeHandler(DoorGuardSpawnEvent));
    eq.register_npc_event("Rallos",Event.spawn,GRUNHORK_TYPE,SafeHandler(DoorGuardSpawnEvent));
    eq.register_npc_event("Rallos",Event.timer,BERIK_TYPE,SafeHandler(DoorGuardTimerEvent));
    eq.register_npc_event("Rallos",Event.timer,GRUNHORK_TYPE,SafeHandler(DoorGuardTimerEvent));
    eq.register_npc_event("Rallos",Event.death_complete,RALLOS_ZEK_TYPE,SafeHandler(RallosDeathEvent));
    eq.register_npc_event("Rallos",Event.signal,RALLOS_ZEK_TYPE,SafeHandler(BossRecoverySignalEvent));
    eq.register_npc_event("Rallos",Event.signal,VALLON_TYPE,SafeHandler(BossRecoverySignalEvent));
    eq.register_npc_event("Rallos",Event.spawn,FLAYER_TYPE,SafeHandler(RoomAddSpawnEvent));
    eq.register_npc_event("Rallos",Event.spawn,SHADOW_TYPE,SafeHandler(RoomAddSpawnEvent));
    eq.register_npc_event("Rallos",Event.spawn,VALLON_SPAWN_TYPE,SafeHandler(RoomAddSpawnEvent));
    eq.register_npc_event("Rallos",Event.timer,VALLON_SPAWN_TYPE,SafeHandler(RoomAddTimerEvent));
    eq.set_timer("initialize",1000,encounter);
    eq.set_timer("watchdog",WATCHDOG_MS,encounter);
end

local encounterTimer=event_timer;
event_timer=SafeHandler(encounterTimer);
