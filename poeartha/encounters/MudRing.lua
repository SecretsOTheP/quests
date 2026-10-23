-- note: when testing this script, using #kill on undamaged NPCs could break the event or crash the zone; #damage them instead or cast Destroy

local BLUE_MUDWALKER_TYPE = 218317;
local RED_MUDWALKER_TYPE = 218418;
local RUNNER_TYPE = 218419; -- '_'; the little untargetable golems that run to the temple after red mudwalkers die
local SLUDGE_LURKER_TYPE = 218357;
local MUCK_MUDLET_TYPE = 218358;
local MUDDITE_MUDLING_TYPE = 218361;
local FILTH_GORGER_TYPE = 218359;
local MONSTEROUS_MUDWALKER_TYPE = 218360;
local MERCILESS_MUDSLINGER_TYPE = 218365;
local MUDESPAWN_TYPE = 218394;
local THE_LAST_TYPE = 218085;
local ARBITOR_GUY_TYPE = 218393;
local STONE_GUY_TYPE = 218391;
local MUDDITE_GUY_TYPE = 218390;
local POEELEM3DAY_TYPE = 218412;
local VEGEROG_GUY_TYPE = 218392;

local BLUE_SPAWNIDS = { 365291, 365399, 365409, 365587, 365808, 366045, 366470, 366646, 
						366691,	366737, 366743, 366840, 366891, 366929, 367013, 367097 };

local RED_LOCS = {
	{ 400, 126, 71, 192 },
	{ 304, 30, 71, 0 },
	{ 280, 126, 71, 64 },
	{ 376, 30, 71, 0 },
	{ 400, 102, 71, 192 },
	{ 352, 150, 71, 128 },
	{ 280, 102, 71, 64 },
	{ 352, 30, 71, 0 },
	{ 400, 78, 71,  192 },
	{ 328, 150, 71, 128 },
	{ 280, 78, 71, 64 },
	{ 328, 30, 71, 0 },
	{ 400, 54, 71,  192 },
	{ 304, 150, 71, 128 },
	{ 280, 54, 71, 64 },
	{ 376, 150, 71, 128 },
};
local GORGER_LOCS = {
	{ 397, 149, 71 },
	{ 283, 149, 71 },
	{ 397, 34, 71 },
	{ 283, 34, 71 },
};

local SUCCESS_RESPAWN_TIME = 237600 * 1000; -- 66 hours
local FAILURE_RESPAWN_TIME = 900000; -- 15 minutes
local blueKills, runners, lurkerState = 0, 0, 0;
local runX, runY, runZ;
local reds = {};
local active, terminal, initialized = false, false, false;
local redKills, unlockAt, missingSince = 0, nil, nil;
local encounter;
local generation = 0;
local session = tostring({});
local RUNNER_GRACE = 30; -- Animation may not block a completed red wave forever.
local FailRing;

local function Live(n)
	return n and n.valid and n:GetHP() > 0 and not n:IsCorpse();
end

local function SpawnRequired(typ, x, y, z, h)
	local ok, mob = pcall(eq.spawn2, typ, 0, 0, x, y, z, h);
	if ok and Live(mob) then return mob; end
end

local function Cleanup()
	for _, typ in ipairs({BLUE_MUDWALKER_TYPE, RED_MUDWALKER_TYPE, RUNNER_TYPE,
		SLUDGE_LURKER_TYPE, MUCK_MUDLET_TYPE, MUDDITE_MUDLING_TYPE,
		FILTH_GORGER_TYPE, MONSTEROUS_MUDWALKER_TYPE, MERCILESS_MUDSLINGER_TYPE, MUDESPAWN_TYPE}) do
		eq.depop_all(typ);
	end
	reds = {}; blueKills, runners, lurkerState, redKills = 0, 0, 0, 0;
	unlockAt, missingSince = nil, nil;
end

FailRing = function(reason)
	if terminal then return; end
	terminal, active = true, false;
	Cleanup();
	local elist = eq.get_entity_list();
	for _, id in ipairs(BLUE_SPAWNIDS) do
		eq.update_spawn_timer(id, FAILURE_RESPAWN_TIME);
		local point = elist:GetSpawnByID(id);
		if point and point.valid ~= false then point:Enable(); end
	end
	eq.debug("Mud Ring failed: "..reason.."; cleaned up for a 15-minute retry.");
end;

local function TryUnlock()
	if not active or not unlockAt or redKills ~= 16 then return; end
	local elist = eq.get_entity_list();
	if elist:IsMobSpawnedByNpcTypeID(BLUE_MUDWALKER_TYPE) or elist:IsMobSpawnedByNpcTypeID(RED_MUDWALKER_TYPE) then return; end
	if runners < 64 and os.time() < unlockAt then return; end
	local lurker = elist:GetNPCByNPCTypeID(SLUDGE_LURKER_TYPE);
	if not Live(lurker) then FailRing("Sludge Lurker missing after the red wave"); return; end
	-- Use the normal activation handler directly; do not depend on a queued signal.
	LurkerSignal({self=lurker, signal=1});
	eq.debug("Mud Ring unlocked Sludge Lurker after 16 confirmed red kills; runners arrived: "..runners);
	unlockAt = nil;
	eq.depop_all(RUNNER_TYPE);
end

function event_timer(e)
	if e.timer ~= "mud_watchdog" then return; end
	local elist = eq.get_entity_list();
	if not initialized then
		initialized = true;
		-- A reload cannot reconstruct kill credit safely. Recover instead of granting a clear.
		if not active and blueKills == 0 then
			for _, typ in ipairs({MUDESPAWN_TYPE, SLUDGE_LURKER_TYPE, RED_MUDWALKER_TYPE, RUNNER_TYPE,
				MUCK_MUDLET_TYPE, FILTH_GORGER_TYPE, MONSTEROUS_MUDWALKER_TYPE, MERCILESS_MUDSLINGER_TYPE}) do
				if elist:IsMobSpawnedByNpcTypeID(typ) then FailRing("orphaned event after script load"); return; end
			end
		end
	end
	if not active then return; end
	local missing = not elist:IsMobSpawnedByNpcTypeID(MUDESPAWN_TYPE);
	if unlockAt or redKills < 16 then
		missing = missing or not elist:IsMobSpawnedByNpcTypeID(SLUDGE_LURKER_TYPE);
		for _, id in pairs(reds) do
			if not Live(elist:GetMob(id)) then missing = true; end
		end
	end
	if missing then
		missingSince = missingSince or os.time();
		if os.time() - missingSince >= RUNNER_GRACE then FailRing("required event NPC disappeared without a kill"); end
		return;
	end
	missingSince = nil;
	TryUnlock();
end

function BlueDeath(e)
	eq.set_timer("mud_watchdog", 5000, encounter);
	if active or e.self:GetEntityVariable("mud_blue_counted") == "1" then return; end
	e.self:SetEntityVariable("mud_blue_counted", "1");
	if blueKills == 0 then
		terminal = false; generation = generation + 1;
		redKills, runners, lurkerState = 0, 0, 0;
		unlockAt, missingSince = nil, nil;
	end
	blueKills = blueKills + 1;
	
	local elist = eq.get_entity_list();
	local loc, mob;
	
	for i = 1, 16 do
		if ( not reds[i] ) then
			loc = RED_LOCS[i];
			mob = SpawnRequired(RED_MUDWALKER_TYPE, loc[1], loc[2], loc[3], loc[4]);
			if not Live(mob) then FailRing("red mudwalker failed to spawn"); return; end
			reds[i] = mob:GetID();
			mob:SetEntityVariable("mud_red_id", tostring(reds[i]));
			mob:SetEntityVariable("mud_generation", session..":"..generation);
			break;
		end
	end
	
	if ( blueKills >= 16 and not elist:IsMobSpawnedByNpcTypeID(BLUE_MUDWALKER_TYPE) ) then
	
		-- Every required red must exist; disappearance never counts as a kill.
		for i = 1, 16 do
			if not reds[i] or not Live(elist:GetMob(reds[i])) then FailRing("incomplete red wave"); return; end
		end
		active = true;
		blueKills, runners, lurkerState = 0, 0, 0;
		mob = SpawnRequired(MUDESPAWN_TYPE, 338, 88, 68.625, 0);
		if not Live(mob) then FailRing("timeout controller failed to spawn"); return; end

		mob = SpawnRequired(SLUDGE_LURKER_TYPE, 339, 92, 81.751, 0);
		if not Live(mob) then FailRing("Sludge Lurker failed to spawn"); return; end
		mob:SetSpecialAbility(24, 1); -- Will Not Aggro
		mob:SetSpecialAbility(25, 1); -- Immune to Aggro
		mob:SetSpecialAbility(35, 1); -- No Harm from Players
		mob:SetBodyType(11, false);	-- NoTarget
		
		for _, id in ipairs(BLUE_SPAWNIDS) do
			elist:GetSpawnByID(id):Disable();
			elist:GetSpawnByID(id):SetTimer(7200000);
		end
		
		for i, id in ipairs(reds) do
			mob = elist:GetMob(id);
			eq.stop_timer("depop", mob);
			mob:SetSpecialAbility(24, 0); -- Will Not Aggro off
			mob:SetSpecialAbility(25, 0); -- Immune to Aggro off
			mob:SetSpecialAbility(35, 0); -- No Harm from Players off
			mob:SetBodyType(24, false);	-- Summoned
		end
		
		eq.zone_emote(0, "The last of the mud walkers has been slain. A loud roar is heard from the center of the muddite temple as the Sludge Lurker comes into being.");
		eq.debug("Mud Ring started");
	end
end

function RemoveFromReds(id)
	for i = 1, 16 do
		if ( reds[i] and reds[i] == id ) then
			reds[i] = nil;
			return true;
		end
	end
	return false;
end

function RedSpawn(e)
	eq.set_timer("depop", 7200000);
end

function RedTimer(e)
	if ( e.timer == "depop" ) then
		if active then FailRing("red mudwalker expired without a kill"); return; end
		RemoveFromReds(e.self:GetID());
		eq.depop();
	end
end

function RedDeath(e)
	if not active or e.self:GetEntityVariable("mud_generation") ~= session..":"..generation then return; end
	local id = tonumber(e.self:GetEntityVariable("mud_red_id"));
	if not id or not RemoveFromReds(id) then return; end
	redKills = redKills + 1;
	runX, runY, runZ = e.self:GetX(), e.self:GetY(), e.self:GetZ();
	for i = 1, 4 do
		local ok = pcall(eq.spawn2, RUNNER_TYPE, 0, 0, runX + math.random(-10, 10), runY + math.random(-10, 10), runZ, 0);
		if not ok then eq.debug("Mud Ring runner spawn failed; confirmed red kill retained."); end
	end
	if redKills == 16 then unlockAt = os.time() + RUNNER_GRACE; end
	TryUnlock();
end

function RunnerSpawn(e)
	if not active then e.self:Depop(); return; end
	e.self:SetEntityVariable("mud_generation", session..":"..generation);
	e.self:SetRunning(true);
	e.self:MoveTo(339, 92, 81.751, -1, true);
end

function RunnerWaypointArrive(e)
	if not active or e.self:GetEntityVariable("mud_generation") ~= session..":"..generation
		or e.self:GetEntityVariable("mud_arrived") == "1" then return; end
	e.self:SetEntityVariable("mud_arrived", "1");
	runners = runners + 1;
	e.self:Depop();
	TryUnlock();
end

function LurkerSpawn(e)
	if ( lurkerState == 0 ) then
		eq.set_next_hp_event(80);
		
	elseif ( lurkerState == 1 ) then
		e.self:SetHP(math.floor(e.self:GetMaxHP() * 0.80));
		eq.set_next_hp_event(60);
	
	elseif ( lurkerState == 2 ) then
		e.self:SetHP(math.floor(e.self:GetMaxHP() * 0.60));
		eq.set_next_hp_event(40);
	
	elseif ( lurkerState == 3 ) then
		e.self:SetHP(math.floor(e.self:GetMaxHP() * 0.40));
		eq.set_next_hp_event(20);
		
	elseif ( lurkerState == 4 ) then
		e.self:SetHP(math.floor(e.self:GetMaxHP() * 0.20));
	end
end

function LurkerSignal(e)
	if ( e.signal == 1 ) then
		e.self:SetSpecialAbility(24, 0); -- Will Not Aggro off
		e.self:SetSpecialAbility(25, 0); -- Immune to Aggro off
		e.self:SetSpecialAbility(35, 0); -- No Harm from Players off
		e.self:SetBodyType(24, false);	-- Summoned
		
		e.self:SetRunning(true);
		e.self:MoveTo(runX, runY, runZ, -1, true);
	end
end

function LurkerHpEvent(e)
	if not active then return; end
	local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
	local xt = { 25, 25, 25, 0, 0, 0, 0, -25, -25, -25 };
	local yt = { 25, 0, -25, 25, 10, -10, -25, 25, 0, -25 };
	
	for i = 1, 10 do
		eq.spawn2(MUCK_MUDLET_TYPE, 0, 0, x + xt[i], y + yt[i], z, 0);
	end

	eq.get_entity_list():MessageClose(e.self, true, 200, 0, "Massive gobs of mud fly everywhere as the huge creature of mud explodes. The gobs of mud coalesce into smaller mud creatures.");
	eq.depop();
end

function MudletSpawn(e)
	eq.set_timer("depop", 300000);
end

function MudletCombat(e)
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function MudletTimer(e)
	if ( e.timer == "depop" ) then
		eq.depop_all(MUCK_MUDLET_TYPE);
	end
end

function MudletDeath(e)
	if not active then return; end
	if ( not eq.get_entity_list():IsMobSpawnedByNpcTypeID(MUCK_MUDLET_TYPE) ) then
		lurkerState = lurkerState + 1;
		eq.spawn2(SLUDGE_LURKER_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ() + 10, 0);
	end
end

function LurkerDeath(e)
	if not active then return; end
	runX, runY, runZ = e.self:GetX(), e.self:GetY(), e.self:GetZ();
	local mob;

	eq.get_entity_list():MessageClose(e.self, true, 200, 0, "More mud flies everywhere, coalescing into mud creatures gorged with filth.");

	for i, loc in ipairs(GORGER_LOCS) do
		mob = eq.spawn2(FILTH_GORGER_TYPE, 0, 0, loc[1], loc[2], loc[3], 0);
		mob:SetRunning(true);
		mob:CastToNPC():MoveTo(runX, runY, runZ, -1, true);
	end
end

function GorgerDeath(e)
	if not active then return; end
	runX, runY, runZ = e.self:GetX(), e.self:GetY(), e.self:GetZ();
	local elist = eq.get_entity_list();

	if ( not elist:IsMobSpawnedByNpcTypeID(FILTH_GORGER_TYPE) ) then
	
		local mob;
		local t = MONSTEROUS_MUDWALKER_TYPE;
		
		if ( not elist:IsMobSpawnedByNpcTypeID(MUDDITE_GUY_TYPE) ) then
			t = MERCILESS_MUDSLINGER_TYPE;
		end
		mob = eq.spawn2(t, 0, 0, 339, 92, 77, 0);
		mob:SetRunning(true);
		mob:CastToNPC():MoveTo(runX, runY, runZ, -1, true);
		
		elist:MessageClose(elist:GetMobByNpcTypeID(THE_LAST_TYPE), true, 400, 0, "The last of the filthy mud men fall to the ground motionless.  Suddenly a monstrous creature of mud forms from the remains of all the other mud men!");
	end
end

function MonsterousSpawn(e)
	eq.set_timer("adds", 60000);
	eq.pause_timer("adds");
end

function MonsterousCombat(e)
	if ( e.joined ) then
		eq.resume_timer("adds");
		eq.set_timer("drophate", 1000);
	else
		eq.pause_timer("adds");
		eq.stop_timer("drophate");
		
		-- this is to mimic certain behavior Sony's servers had/has.  NPCs aggroed a long time sometimes warp home or
		-- some distance away in the direction of home and heal somewhat when they hate list wipe.  The exact logic to this
		-- behavior is unknown.  Bosses with the tank hate list drop mechanic need this in order to not trivialize the
		-- encounter using mem blur.  This is a crude solution that works well enough
		local ratio = e.self:GetHPRatio();
		if ( ratio < 50 or math.random(100) > ratio ) then
			e.self:GMMove(e.self:GetGuardPointX(), e.self:GetGuardPointY(), e.self:GetGuardPointZ(), e.self:GetSpawnPointH());
			e.self:SetHP(e.self:GetHP() + math.floor(e.self:GetMaxHP() * 0.3));
		end
	end
end

function MonsterousTimer(e)
	if ( e.timer == "drophate") then
	
		if ( math.random() < 0.03333 ) then -- averages to once per 30 seconds
			local target = e.self:GetTarget();
			if ( target and target.valid ) then
				local hate = e.self:GetHateAmount(target);

				if ( hate > 0 ) then
					e.self:SetHate(target, math.max(1, math.floor(hate * 0.01)));
					eq.debug(e.self:GetName().." reduced hate on "..target:GetName().." to 1%", 2);
				end
			end
		end
		
	elseif ( e.timer == "adds" ) then
		local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
		
		for i = 1, 10 do
			eq.spawn2(MUDDITE_MUDLING_TYPE, 0, 0, x + math.random(-50, 50), y + math.random(-50, 50), z, 0);
		end
	end
end

function EventSuccess(e)
	if not active or terminal then return; end
	active, terminal = false, true;
	Cleanup();
	eq.debug("Mud Ring completed");
	
	eq.depop_all(MUDESPAWN_TYPE);
	if ( e.self:GetNPCTypeID() == MONSTEROUS_MUDWALKER_TYPE ) then
		eq.depop_with_timer(MUDDITE_GUY_TYPE);
	end
	
	local elist = eq.get_entity_list();
	-- Save each trigger's cooldown before enabling it for the next attempt.
	for _, id in ipairs(BLUE_SPAWNIDS) do
		eq.update_spawn_timer(id, SUCCESS_RESPAWN_TIME);
		elist:GetSpawnByID(id):Enable();
	end
	
	for i = 1, 16 do
		reds[i] = nil;
	end
	
	eq.signal(ARBITOR_GUY_TYPE, 2);
end

function DespawnSpawn(e)
	eq.set_timer("depop", 5880000);
end

function DespawnTimer(e)
	if e.timer == "depop" then
		FailRing("98-minute event timeout");
		eq.depop();
	end
end

function event_encounter_load(e)
	encounter = e.encounter;
	eq.set_timer("mud_watchdog", 5000, encounter);

	eq.register_npc_event("MudRing", Event.death_complete, BLUE_MUDWALKER_TYPE, BlueDeath);
	
	eq.register_npc_event("MudRing", Event.spawn, RED_MUDWALKER_TYPE, RedSpawn);
	eq.register_npc_event("MudRing", Event.timer, RED_MUDWALKER_TYPE, RedTimer);
	eq.register_npc_event("MudRing", Event.death_complete, RED_MUDWALKER_TYPE, RedDeath);

	eq.register_npc_event("MudRing", Event.spawn, RUNNER_TYPE, RunnerSpawn);
	eq.register_npc_event("MudRing", Event.waypoint_arrive, RUNNER_TYPE, RunnerWaypointArrive);
	
	eq.register_npc_event("MudRing", Event.spawn, SLUDGE_LURKER_TYPE, LurkerSpawn);
	eq.register_npc_event("MudRing", Event.signal, SLUDGE_LURKER_TYPE, LurkerSignal);
	eq.register_npc_event("MudRing", Event.hp, SLUDGE_LURKER_TYPE, LurkerHpEvent);
	eq.register_npc_event("MudRing", Event.death_complete, SLUDGE_LURKER_TYPE, LurkerDeath);
	
	eq.register_npc_event("MudRing", Event.spawn, MUCK_MUDLET_TYPE, MudletSpawn);
	eq.register_npc_event("MudRing", Event.timer, MUCK_MUDLET_TYPE, MudletTimer);
	eq.register_npc_event("MudRing", Event.death_complete, MUCK_MUDLET_TYPE, MudletDeath);
	
	eq.register_npc_event("MudRing", Event.death_complete, FILTH_GORGER_TYPE, GorgerDeath);
	
	eq.register_npc_event("MudRing", Event.spawn, MONSTEROUS_MUDWALKER_TYPE, MonsterousSpawn);
	eq.register_npc_event("MudRing", Event.combat, MONSTEROUS_MUDWALKER_TYPE, MonsterousCombat);
	eq.register_npc_event("MudRing", Event.timer, MONSTEROUS_MUDWALKER_TYPE, MonsterousTimer);
	eq.register_npc_event("MudRing", Event.death_complete, MONSTEROUS_MUDWALKER_TYPE, EventSuccess);
	eq.register_npc_event("MudRing", Event.spawn, MERCILESS_MUDSLINGER_TYPE, MonsterousSpawn);
	eq.register_npc_event("MudRing", Event.combat, MERCILESS_MUDSLINGER_TYPE, MonsterousCombat);
	eq.register_npc_event("MudRing", Event.timer, MERCILESS_MUDSLINGER_TYPE, MonsterousTimer);
	eq.register_npc_event("MudRing", Event.death_complete, MERCILESS_MUDSLINGER_TYPE, EventSuccess);
	
	eq.register_npc_event("MudRing", Event.spawn, MUDESPAWN_TYPE, DespawnSpawn);
	eq.register_npc_event("MudRing", Event.timer, MUDESPAWN_TYPE, DespawnTimer);

end
