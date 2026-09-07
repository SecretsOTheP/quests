local CONTROLLER_TYPE = 206197; -- Weapon_Event_Master
local WAVE_TIME = 48000; -- 48 seconds between waves

local CLOCKWORK_DEVICE_TYPE = 206001;
local BEHEMOTH_TYPE = 206046;
local GIWIN_FLAGGER_TYPE = 206203; -- #Giwin_Mirakon
local BEHEMOTH_SPAWNID = 345273;
local FAILURE_RETRY = 600000; -- 10 minutes

local WAVE_SPAWNS = {
	{	-- 12:00
		{ x = 1095, y = 560 },
		{ x = 1155, y = 560 },
		{ x = 1180, y = 600 },
		{ x = 1155, y = 650 },
		{ x = 1065, y = 605 },
		{ x = 1095, y = 650 },
		13, 14	-- grids; if two, is randomly chosen
	},
	{	-- 2:30
		{ x = 835, y = 330 },
		{ x = 850, y = 285 },
		{ x = 750, y = 285 },
		{ x = 770, y = 240 },
		{ x = 775, y = 330 },
		{ x = 835, y = 240 },
		15
	},
	{	-- 4:30
		{ x = 750, y = -285 },
		{ x = 860, y = -285 },
		{ x = 835, y = -330 },
		{ x = 775, y = -330 },
		{ x = 775, y = -240 },
		{ x = 840, y = -240 },
		16
	},
	{	-- 6:00
		{ x = 1065, y = -600 },
		{ x = 1180, y = -600 },
		{ x = 1150, y = -650 },
		{ x = 1155, y = -560 },
		{ x = 1095, y = -560 },
		{ x = 1090, y = -650 },
		17, 18
	},
	{	-- 7:30
		{ x = 1415, y = -330 },
		{ x = 1380, y = -280 },
		{ x = 1475, y = -240 },
		{ x = 1475, y = -330 },
		{ x = 1410, y = -240 },
		{ x = 1500, y = -285 },
		19
	},
	{	-- 10:30
		{ x = 1475, y = 330 },
		{ x = 1415, y = 330 },
		{ x = 1475, y = 240 },
		{ x = 1500, y = 285 },
		{ x = 1405, y = 240 },
		{ x = 1385, y = 285 },
		20
	}
};

local exploders = {};
local woken = false;
local kills = 0;

function ControllerSpawn(e)
	eq.set_timer("wave", WAVE_TIME);
end

function WakeBehemoth()
	if ( not woken and kills >= 10 ) then
		local behe = eq.get_entity_list():GetMobByNpcTypeID(BEHEMOTH_TYPE);
		
		if ( behe and behe.valid ) then
			behe:SetSpecialAbility(24, 0); -- Will Not Aggro off
			behe:SetSpecialAbility(35, 0); -- No Harm from Players off
			behe:SetBodyType(5, false); -- Construct
			
			local roll = math.random(1, 4);
			local spell;
			if ( roll == 1 ) then
				spell = 1080; -- Gas Leak
			elseif ( roll == 2 ) then
				spell = 1081; -- Deathfog IV
			elseif ( roll == 3 ) then
				spell = 1082; -- Biomelt IX
			elseif ( roll == 4 ) then
				spell = 1083; -- Liquid Hydrokill
			end
			behe:CastToNPC():AddAISpell(0, spell, 1, 0, -1, -150);
			
			eq.set_timer("depop", 10800000, behe);
			eq.set_timer("boundscheck", 2000, behe);
			woken = true;
			eq.debug("Behemoth awakened");
		end
	end
end

function ControllerTimer(e)
	if ( e.timer == "wave" ) then
		SpawnWave();
	end
end

function BehemothSpawn(e)
	woken = false;
	kills = 0;
	local controller = eq.get_entity_list():GetMobByNpcTypeID(CONTROLLER_TYPE);
	if (controller and controller.valid) then
		eq.set_timer("wave", WAVE_TIME, controller);
	end
end

function SpawnWave()
	local loc, grid, mob;
	for _, t in ipairs(WAVE_SPAWNS) do
		loc = math.random(1, 6);
		if ( #t == 8 ) then
			grid = t[math.random(7, 8)];
		else
			grid = t[7];
		end
		mob = eq.spawn2(CLOCKWORK_DEVICE_TYPE, grid, 0, t[loc].x, t[loc].y, 75, 0);
		--eq.get_entity_list():OpenDoorsNear(mob:CastToNPC());
	end
end

function BehemothCombat(e)
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function BehemothTimer(e)
	if ( e.timer == "boundscheck" ) then
		if ( e.self:GetX() > 1215 or e.self:GetX() < 1033 or e.self:GetY() > 120 or e.self:GetY() < -120 ) then
			e.self:GMMove(e.self:CastToNPC():GetSpawnPointX(), e.self:CastToNPC():GetSpawnPointY(), e.self:CastToNPC():GetSpawnPointZ(), e.self:CastToNPC():GetSpawnPointH());
			e.self:CastSpell(3230, e.self:GetID()); -- Balance of the Nameless
			e.self:WipeHateList();
			e.self:Heal();
		end
	elseif ( e.timer == "depop" ) then
		local controller = eq.get_entity_list():GetMobByNpcTypeID(CONTROLLER_TYPE);
		if (controller and controller.valid) then
			eq.stop_timer("wave", controller);
		end
		eq.depop_all(CLOCKWORK_DEVICE_TYPE);
		eq.get_entity_list():GetSpawnByID(BEHEMOTH_SPAWNID):SetTimer(FAILURE_RETRY);
		eq.depop();
		woken = false;
	end
end

function BehemothDeathComplete(e)
	local controller = eq.get_entity_list():GetMobByNpcTypeID(CONTROLLER_TYPE);
	if (controller and controller.valid) then
		eq.stop_timer("wave", controller);
	end
	eq.depop_all(CLOCKWORK_DEVICE_TYPE);
	eq.debug("Behemoth defeated; stopped waves and depopped remaining clockwork devices", 1);
	eq.spawn2(GIWIN_FLAGGER_TYPE, 0, 0, 1013, 0, 2.1, 193);
	eq.signal(GIWIN_FLAGGER_TYPE, e.killer:GetID()); -- e.killer for death_complete is somebody with kill rights, not death blow
	woken = false;
end

function BlowUp(e)
	e.self:CastSpell(2321, e.self:GetID());
	eq.set_timer("depop", 100);
end

function DeviceWaypointArrive(e)
	if ( e.self:GetX() > 1069 and e.self:GetX() < 1176
		and e.self:GetY() < 38 and e.self:GetY() > -39
		and (e.self:GetY() > 30 or e.self:GetY() < -30)
	)  then
		eq.set_timer("boom", 2000);
	end
end

function DeviceTimer(e)
	if ( e.timer == "boom" ) then
		eq.stop_timer("boom");
		if ( e.self:IsEngaged() ) then
			exploders[e.self:GetID()] = true;
			return
		end
		BlowUp(e);
	elseif ( e.timer == "depop" ) then
		eq.depop();
	end
end

function DeviceCombat(e)
	if ( not e.joined and exploders[e.self:GetID()] ) then
		exploders[e.self:GetID()] = nil;
		BlowUp(e);
	end
end

function DeviceDeath(e)
	kills = kills + 1;
	if (kills == 10) then
		eq.debug("Behemoth reached 10 qualifying kills; awakening immediately", 1);
		WakeBehemoth();
	end
	if ( exploders[e.self:GetID()] ) then
		exploders[e.self:GetID()] = nil;
	end
end

function event_encounter_load(e)
	eq.register_npc_event("Behemoth", Event.spawn, CONTROLLER_TYPE, ControllerSpawn);
	eq.register_npc_event("Behemoth", Event.timer, CONTROLLER_TYPE, ControllerTimer);

	local controller = eq.get_entity_list():GetMobByNpcTypeID(CONTROLLER_TYPE);
	if (controller and controller.valid) then
		eq.set_timer("wave", WAVE_TIME, controller);
		eq.debug("Behemoth controller found and timers initialized", 1);
	end

	eq.register_npc_event("Behemoth", Event.spawn, BEHEMOTH_TYPE, BehemothSpawn);
	eq.register_npc_event("Behemoth", Event.combat, BEHEMOTH_TYPE, BehemothCombat);
	eq.register_npc_event("Behemoth", Event.timer, BEHEMOTH_TYPE, BehemothTimer);
	eq.register_npc_event("Behemoth", Event.death_complete, BEHEMOTH_TYPE, BehemothDeathComplete);

	eq.register_npc_event("Behemoth", Event.timer, CLOCKWORK_DEVICE_TYPE, DeviceTimer);
	eq.register_npc_event("Behemoth", Event.combat, CLOCKWORK_DEVICE_TYPE, DeviceCombat);
	eq.register_npc_event("Behemoth", Event.death, CLOCKWORK_DEVICE_TYPE, DeviceDeath);
	eq.register_npc_event("Behemoth", Event.waypoint_arrive, CLOCKWORK_DEVICE_TYPE, DeviceWaypointArrive);
end
