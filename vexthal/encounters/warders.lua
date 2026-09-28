local WARDER_TYPES = {
	[158444] = 158418			-- Kaas_Thox_Xi_Ans_Dyek, _Akhevan_Warder
};

local DISABLED_TYPES = {
	[158409] = true,			-- __Akhevan_Warder
	[158405] = true,			-- ___Akhevan_Warder
	[158399] = true,			-- ____Akhevan_Warder
	[158393] = true				-- _____Akhevan_Warder
};

function BossDeathEvent(e)

	local npcList = eq.get_entity_list():GetNPCList();

	if (npcList) then
		for npc in npcList.entries do
			if (npc.valid and npc:GetNPCTypeID() == WARDER_TYPES[e.self:GetNPCTypeID()]) then
				npc:Depop(true);
			end
		end
	end
end

function DisabledTypeSpawn(e)
	e.self:Depop(false);
end

function event_encounter_load(e)

	for bossType, warderType in pairs(WARDER_TYPES) do
		eq.register_npc_event("warders", Event.death, bossType, BossDeathEvent);
	end

	for npcType, _ in pairs(DISABLED_TYPES) do
		eq.register_npc_event("warders", Event.spawn, npcType, DisabledTypeSpawn);
	end
end
