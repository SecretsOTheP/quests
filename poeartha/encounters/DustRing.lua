local progress = require("earth_ring_progress");

local WARDER_TYPE = 218022;
local DEVOTEE_TYPE = 218366;
local TRIUMVIRATE_TYPE = 218367;
local TRIUMVIRATE2_TYPE = 218421;
local PERFECTED_TYPE = 218413;
local PROTECTOR_TYPE = 218414;
local FOLLOWER_TYPE = 218415;
local ELEMDESPAWN_TYPE = 218397;
local STONE_GUY_TYPE = 218391;
local ARBITOR_GUY_TYPE = 218393;
local MUDDITE_GUY_TYPE = 218390;
local POEELEM3DAY_TYPE = 218412;
local VEGEROG_GUY_TYPE = 218392;
local THE_CREATURE_TYPE = 218059;

local SUCCESS_RESPAWN_TIME = 237600 * 1000; -- 66 hours
local FAILURE_RESPAWN_TIME = 900000; -- 15 minutes
local WARDER_SPAWNID = 366233; -- dusty warder

local DEVOTEE_LOCS = {
	{ 22, -430, 33, 0 },
	{ -84, -660, 33, 0 },
	{ 89, -657, 33, 0 },
	{ 106, -651, 33, 192 },
	{ 106, -612, 33, 192 },
	{ 98, -461, 33, 128 },
	{ -44, -458, 33, 128 },
	{ -10, -430, 33, 0 },
	{ -123, -575, 33, 192 },
	{ -10, -689, 33, 128 },
	{ 170, -585, 15, 64 },
	{ 170, -534, 13, 64 },
	{ 31, -396, 13.75, 0 },
	{ -18, -396, 13.375, 0 },
	{ -157, -585, 16, 192 },
	{ -19, -724, 13.1, 128 },
	{ 31, -724, 13.8, 128 },
	{ -82, -458, 33, 128 },
	{ -94, -503, 33, 64 },
	{ -94, -610, 33, 64 },
	{ 53, -657, 33, 0 },
	{ 105, -515, 33, 192 },
	{ 105, -480, 33, 192 },
	{ 55, -461, 33, 128 },
	{ 136, -575, 33, 64 },
	{ 136, -544, 33, 64 },
	{ 22, -689, 33, 128 },
	{ -157, -535, 13, 192 },
	{ -123, -544, 33, 192 },
	{ -94, -467, 33, 64 },
	{ -94, -647, 33, 64 },
	{ -45, -660, 33, 0 },
};
local TRIUMVIRATE_LOCS = {
	{ -17, -535, 35.5, 94 },
	{ -17, -585, 35.5, 31 },
	{ 28, -560, 35.5, 189 },
};

local triKills, bossWave, devoteeKills = 0, 0, 0;
local bossTriumvirates = 0;
local bossTimer;

local FailRing;
local terminal = false;
local guard = require("earth_ring_guard").new("DustRing", {DEVOTEE_TYPE, TRIUMVIRATE_TYPE, TRIUMVIRATE2_TYPE, PERFECTED_TYPE, PROTECTOR_TYPE, FOLLOWER_TYPE, ELEMDESPAWN_TYPE}, function(reason) FailRing(reason); end);
-- Public failure text deliberately excludes raw errors, IDs and progress counters.
local function FailureMessage(reason)
    local text = tostring(reason);
    local message;
    if text:find("98-minute", 1, true) then
        message = "The allotted time has passed. The Rathe's summons is withdrawn, and the temple's guardians unravel into dust.";
    elseif text:find("orphaned", 1, true) or text:find("untracked", 1, true) then
        message = "The temple's interrupted trial cannot be resumed. The ancient will binding its guardians releases them into drifting dust.";
    elseif text:find("timeout controller", 1, true) or text:find("type=218397", 1, true) then
        message = "The ancient command sustaining the temple's trial has faded. Its guardians lose their earthen shapes and settle into dust.";
    elseif text:find("failed to spawn", 1, true) or text:find("spawn failed", 1, true) or text == "incomplete red wave" then
        message = "The temple's ancient summons stirs the dust, but a guardian fails to take form. The trial cannot continue.";
    elseif text:find("missing", 1, true) or text == "red mudwalker expired without a kill" then
        message = "A temple guardian loses its shape before its defeat, scattering into dust. The trial cannot continue.";
    else
        message = "The ancient will sustaining the temple's trial falters unexpectedly. Its guardians loosen into soil and grit as the summons falls silent.";
    end
    return message.." The Dust Ring has reset; you may attempt it again in 15 minutes.";
end

FailRing = function(reason)
    if terminal then return; end
    local phaseName = devoteeKills < 37 and "Dust devotees" or (triKills < 3 and "Triumvirate of Soil" or "Final guardian");
    local context = string.format("Phase: %s | Devotee kills: %d/37 | Triumvirate kills: %d/3 | Boss wave: %d | Boss Triumvirates awaiting kills: %d", phaseName, devoteeKills, triKills, bossWave, bossTriumvirates);
    terminal = true; guard:stop();
    for _,typ in ipairs({DEVOTEE_TYPE, TRIUMVIRATE_TYPE, TRIUMVIRATE2_TYPE, PERFECTED_TYPE, PROTECTOR_TYPE, FOLLOWER_TYPE, ELEMDESPAWN_TYPE}) do eq.depop_all(typ); end
    triKills, devoteeKills, bossWave = 0, 0, 0;
    bossTriumvirates = 0;
    local elist = eq.get_entity_list();
    for _,id in ipairs({WARDER_SPAWNID}) do
        eq.update_spawn_timer(id, FAILURE_RESPAWN_TIME);
        elist:GetSpawnByID(id):Enable();
    end
    eq.zone_emote(13, FailureMessage(reason));
    eq.debug("[EarthRing:Dust] FAIL "..context.." reason="..tostring(reason).."; cleanup complete; retry=15m");
end

function event_timer(e)
    guard:tick(e);
end

function WarderDeath(e)

	if guard.active or not guard:once(e.self) then return; end
	terminal = false; guard:start();
	triKills, devoteeKills = 0, 0;
	bossTriumvirates = 0;
	
	local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
	local xOffset = { 60, -60, 60, -60, -60 };
	local yOffset = { 60, 60, -60, -60, -50 };
	local moveX = { -251, -267, -261, -237, -232 };
	local moveY = { -1319, -1330, -1348, -1354, -1328 };
	
	for i = 1, 5 do
		guard:spawn(DEVOTEE_TYPE, 0, 0, x + xOffset[i], y + yOffset[i], z+5, 0):CastToNPC():MoveTo(moveX[i], moveY[i], -33, 0, true);
	end
	
	for i, loc in ipairs(DEVOTEE_LOCS) do
		guard:spawn(DEVOTEE_TYPE, 0, 0, loc[1], loc[2], loc[3], loc[4]);
	end
	
	local mob;
	for i, loc in ipairs(TRIUMVIRATE_LOCS) do
		mob = guard:spawn(TRIUMVIRATE_TYPE, 0, 0, loc[1], loc[2], loc[3], loc[4]);
		mob:SetSpecialAbility(24, 1); -- Will Not Aggro
		mob:SetSpecialAbility(25, 1); -- Immune to Aggro
		mob:SetSpecialAbility(35, 1); -- No Harm from Players
		mob:SetBodyType(11, false);	-- NoTarget
	end
	
	guard:spawn(ELEMDESPAWN_TYPE, 0, 0, 28, -560, 28.625, 0);
	eq.zone_emote(13, "An ancient command rolls through the temple as the dusty warder bursts into grit. Three streams of earth sweep toward its halls, and the remaining dust rises as devotees of the Rathe.");
	eq.debug("Dust ring active");
end

function DevoteeDeath(e)
	if not guard:dead(e.self) then return; end
	devoteeKills = devoteeKills + 1;
	progress.announce(devoteeKills, 37,
		"The devotees' earthen forms break beneath your blows, spilling grit across the temple. Those still standing hold their shapes beneath the Rathe's unyielding will.",
		"Only a few dust devotees remain before the temple, their forms scoured thin. The Triumvirate waits in silence beyond the drifting ruin.");
	if ( devoteeKills == 37 ) then

		local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();		
		local npcList = eq.get_entity_list():GetNPCList();
		
		for npc in npcList.entries do
	
			if ( npc.valid and npc:GetNPCTypeID() == TRIUMVIRATE_TYPE ) then
				npc:SetSpecialAbility(24, 0); -- Will Not Aggro off
				npc:SetSpecialAbility(25, 0); -- Immune to Aggro off
				npc:SetSpecialAbility(35, 0); -- No Harm from Players off
				npc:SetBodyType(24, false);	-- Summoned
				
				npc:SetRunning(true);
				npc:MoveTo(x, y, z, -1, true);
			end
		end
		
		eq.zone_emote(13, "The last dust devotee breaks apart. Bound by the Rathe's will, the Triumvirate of Soil advances to pass judgment.");
	end
end

function TriumvirateDeath(e)
	if devoteeKills ~= 37 or not guard:dead(e.self) then return; end
	triKills = triKills + 1;
	progress.announce(triKills, 3,
		"Two of the Triumvirate crumble beneath your assault. The last stands firm, soil and grit bound by the Rathe's unyielding will.");
	
	if ( triKills == 3 ) then
		local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
		
		local t = PERFECTED_TYPE;
		
		if ( not eq.get_entity_list():IsMobSpawnedByNpcTypeID(POEELEM3DAY_TYPE) ) then
			t = FOLLOWER_TYPE;
		end
		local mob = guard:spawn(t, 0, 0, 6, -560, 37.376, 128);
		mob:SetRunning(true);
		mob:CastToNPC():MoveTo(x, y, z, -1, true);
		
		eq.zone_emote(13, "The last of the Triumvirate sinks into loose earth. The temple trembles beneath an ancient command as its final defender takes form.");
	end
end

function TriumvirateSpawn(e)
	if ( triKills < 3 ) then	-- the ones that spawn from the Perfected Warder do not turn into tornados apparently
		eq.set_timer("invis", 60000);
		eq.pause_timer("invis");
	end
end

function TriumvirateCombat(e)
	if ( e.joined ) then
		eq.resume_timer("invis");
	else
		eq.pause_timer("invis");
		eq.stop_timer("drophate");
		if ( e.self:GetRace() == 233 ) then
			e.self:SetRace(209);
			e.self:ChangeSize(12);
		end
	end
end

function TriumvirateTimer(e)
	if ( e.timer == "drophate") then

		if ( math.random() < 0.1 ) then -- averages to once every 10 seconds
			local target = e.self:GetTarget();
			if ( target and target.valid ) then
				local hate = e.self:GetHateAmount(target);

				if ( hate > 0 ) then
					e.self:SetHate(target, math.max(1, math.floor(hate * 0.01)));
					eq.debug(e.self:GetName().." reduced hate on "..target:GetName().." to 1%", 2);
				end
			end
		end
		
	elseif ( e.timer == "invis" ) then
		if ( e.self:GetRace() == 209 ) then
			e.self:SetRace(233);		-- this turns them into hard-to-see dust tornados
			e.self:ChangeSize(12);
		else
			e.self:SetRace(209);
			e.self:ChangeSize(12);
		end
		eq.set_timer("drophate", 1000);
	end
end

function BossSpawn(e)
	if ( math.random(2) == 1 ) then
		bossTimer = "protectors";
	else
		bossTimer = "triumvirates";
	end

	eq.set_timer(bossTimer, 60000);
	eq.pause_timer(bossTimer);
	bossWave = 0;
end

function BossCombat(e)
	if not guard:owns(e.self) then return; end
	if ( e.joined ) then
		eq.resume_timer(bossTimer);
		eq.set_timer("drophate", 1000);
		if ( bossTriumvirates == 0 ) then
			bossWave = 0;
		end
	else
		eq.pause_timer(bossTimer);
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

function BossTimer(e)
	if not guard:owns(e.self) then return; end

	if ( e.timer == "drophate") then

		if ( math.random() < 0.05 ) then -- averages to once every 20 seconds
			local target = e.self:GetTarget();
			if ( target and target.valid ) then
				local hate = e.self:GetHateAmount(target);

				if ( hate > 0 ) then
					e.self:SetHate(target, math.max(1, math.floor(hate * 0.01)));
					eq.debug(e.self:GetName().." reduced hate on "..target:GetName().." to 1%", 2);
				end
			end
		end
		
		-- force them to kill triumvirates before boss
		if ( e.self:GetHPRatio() < 49 and bossTriumvirates > 0 ) then
			e.self:SetHP(e.self:GetMaxHP() / 2);
		end
		
	elseif ( e.timer == "protectors" ) then
	
		bossWave = bossWave + 1;
		
		local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
		local xOffset = { 60, -60, 60, -60 };
		local yOffset = { 60, 60, -60, -60 };
		local j = 1;
		
		for i = 1, (bossWave + 2) do
			eq.spawn2(PROTECTOR_TYPE, 0, 0, x + xOffset[j], y + yOffset[j], z+5, 0):CastToNPC():MoveTo(x, y, z, -1, true);
			j = j + 1;
			if ( j > 4 ) then
				j = 1;
			end
		end
		
	elseif ( e.timer == "triumvirates" ) then
	
		bossWave = bossWave + 1;
		local x, y, z = e.self:GetX(), e.self:GetY(), e.self:GetZ();
		
		if ( bossWave == 1 ) then
		
			for i, loc in ipairs(TRIUMVIRATE_LOCS) do
				local mob = guard:spawn(TRIUMVIRATE2_TYPE, 0, 0, loc[1], loc[2], loc[3], loc[4]);
				bossTriumvirates = bossTriumvirates + 1;
				mob:CastToNPC():MoveTo(x, y, z, -1, true);
			end
			eq.zone_emote(13, "Three earthen forms rise at the temple's summons, their bodies bound by an ancient command. They advance to uphold the defender's judgment.");
		
		else
		
			local npcList = eq.get_entity_list():GetNPCList();			
			for npc in npcList.entries do
		
				if ( npc.valid and npc:GetNPCTypeID() == TRIUMVIRATE2_TYPE and not npc:IsEngaged() ) then
					npc:SetRunning(true);
					npc:MoveTo(x, y, z, -1, true);
				end
			end
		end
	end
end

function BossTriumvirateDeath(e)
	if not guard:dead(e.self) then return; end
	bossTriumvirates = bossTriumvirates - 1;
	progress.announce(3 - bossTriumvirates, 3,
		"Two of the three earthen guardians break apart, their binding strength spent. One remains to uphold the temple's judgment.");
	if bossTriumvirates == 0 then
		eq.zone_emote(13, "The last earthen guardian crumbles into loose earth. The strength they lent the temple's defender falls away with the settling grit.");
	end
end

function EventSuccess(e)
	if triKills ~= 3 or not guard:dead(e.self) then return; end
	if bossTriumvirates > 0 then
		FailRing("required boss Triumvirate kills missing when final guardian died");
		return;
	end
	terminal = true; guard:stop();
	eq.debug("Dust ring completed");
	eq.depop_all(PROTECTOR_TYPE);
	eq.depop_all(TRIUMVIRATE2_TYPE);

	eq.depop_all(ELEMDESPAWN_TYPE);
	-- The warder's saved respawn is the ring cooldown, including after a restart.
	eq.update_spawn_timer(WARDER_SPAWNID, SUCCESS_RESPAWN_TIME);
	if ( e.self:GetNPCTypeID() == PERFECTED_TYPE ) then
		eq.depop_with_timer(POEELEM3DAY_TYPE);
	end
	
	eq.signal(ARBITOR_GUY_TYPE, 4);
	eq.zone_emote(13, "The temple's final defender breaks apart, and the ancient force binding its earthen body falls silent. The trial of the Dust Ring is complete.");
end

function DespawnSpawn(e)
	eq.set_timer("depop", 5880000);
end

function DespawnTimer(e)
    if e.timer == "depop" and (not guard.active or guard:owns(e.self)) then
        FailRing("98-minute controller timeout"); eq.depop();
    end
end

function event_encounter_load(e)
	guard:arm(e.encounter);

	eq.register_npc_event("DustRing", Event.death_complete, WARDER_TYPE, guard:wrap(WarderDeath));

	eq.register_npc_event("DustRing", Event.death_complete, DEVOTEE_TYPE, guard:wrap(DevoteeDeath));

	eq.register_npc_event("DustRing", Event.death_complete, TRIUMVIRATE_TYPE, guard:wrap(TriumvirateDeath));
	eq.register_npc_event("DustRing", Event.spawn, TRIUMVIRATE_TYPE, guard:wrap(TriumvirateSpawn));
	eq.register_npc_event("DustRing", Event.combat, TRIUMVIRATE_TYPE, guard:wrap(TriumvirateCombat));
	eq.register_npc_event("DustRing", Event.timer, TRIUMVIRATE_TYPE, guard:wrap(TriumvirateTimer));
	eq.register_npc_event("DustRing", Event.death_complete, TRIUMVIRATE2_TYPE, guard:wrap(BossTriumvirateDeath));

	eq.register_npc_event("DustRing", Event.spawn, PERFECTED_TYPE, guard:wrap(BossSpawn));
	eq.register_npc_event("DustRing", Event.combat, PERFECTED_TYPE, guard:wrap(BossCombat));
	eq.register_npc_event("DustRing", Event.timer, PERFECTED_TYPE, guard:wrap(BossTimer));
	eq.register_npc_event("DustRing", Event.death_complete, PERFECTED_TYPE, guard:wrap(EventSuccess));
	eq.register_npc_event("DustRing", Event.spawn, FOLLOWER_TYPE, guard:wrap(BossSpawn));
	eq.register_npc_event("DustRing", Event.combat, FOLLOWER_TYPE, guard:wrap(BossCombat));
	eq.register_npc_event("DustRing", Event.timer, FOLLOWER_TYPE, guard:wrap(BossTimer));
	eq.register_npc_event("DustRing", Event.death_complete, FOLLOWER_TYPE, guard:wrap(EventSuccess));

	eq.register_npc_event("DustRing", Event.spawn, ELEMDESPAWN_TYPE, guard:wrap(DespawnSpawn));
	eq.register_npc_event("DustRing", Event.timer, ELEMDESPAWN_TYPE, guard:wrap(DespawnTimer));

end
