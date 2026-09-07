local MINI_TYPES = {
	210027, -- Zertuken_the_Unyielding
	210033, -- Solnebk_the_Unruly
	210032, -- Pendubk_the_Turbulent
	210028, -- Paruek_the_Strong
	210026, -- Laruken_the_Rigid
	210029, -- Faruek_the_Bold
}
local MINI_MEDALLIONS = {
	[210026] = 28783, -- Laruken: Kelek`Vor
	[210027] = 28783, -- Zertuken: Kelek`Vor
	[210028] = 28765, -- Paruek: Srerendi
	[210029] = 28765, -- Faruek: Srerendi
	[210032] = 28780, -- Pendubk: Krendic
	[210033] = 28780, -- Solnebk: Krendic
}
local STORM_TYPE = 210467; -- a_tumultuous_storm

function MiniSpawnEvent(e)
	local medallion = MINI_MEDALLIONS[e.self:GetNPCTypeID()];
	local maximum = (eq.get_zone_guild_id() == 1) and 2 or 3;
	for i = 1, math.random(1, maximum) do
		e.self:AddItem(medallion, 1);
	end
end

function MiniTimerEvent(e)
	if ( e.timer == "storms" ) then
		local x = e.self:GetX() + math.random(-75, 75);
		local y = e.self:GetY() + math.random(-75, 75);
		local z = e.self:GetZ() + 5;
		local rng = math.random(7, 10);
		
		for i = 1, rng do
			eq.spawn2(STORM_TYPE, 0, 0, x, y, z, 0);
		end
	end
end

function MiniCombatEvent(e)
	if ( e.joined ) then
		eq.set_timer("storms", 60000);
	else
		eq.stop_timer("storms");
	end
end

function StormSpawnEvent(e)
	eq.set_timer("depop", 9000);
end

function StormTimerEvent(e)
	eq.depop();
end

function event_encounter_load(e)

	for _, id in ipairs(MINI_TYPES) do
		eq.register_npc_event("MiniBosses", Event.spawn, id, MiniSpawnEvent);
		eq.register_npc_event("MiniBosses", Event.timer, id, MiniTimerEvent);
		eq.register_npc_event("MiniBosses", Event.combat, id, MiniCombatEvent);
	end
	eq.register_npc_event("MiniBosses", Event.spawn, STORM_TYPE, StormSpawnEvent);
	eq.register_npc_event("MiniBosses", Event.timer, STORM_TYPE, StormTimerEvent);
end
