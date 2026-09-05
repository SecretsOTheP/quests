local GUARANTEED_LOOT = {
	[209070] = { 17168, 3 }, -- Laef Windfall: Ring of Torden
	[209071] = { 17168, 3 }, -- Gaukr Sandstorm: Ring of Torden
	[209072] = { 17168, 3 }, -- Oreen Wavecrasher: Ring of Torden
	[209082] = { 17168, 3 }, -- Hreidar Lynhillig: Ring of Torden
	[209016] = { 17169, 1 }, -- Brynju Thunderclap: Unadorned Symbol of Torden
	[209059] = { 17169, 1 }, -- Auliffe Chaoswind: Unadorned Symbol of Torden
	[209060] = { 17169, 1 }, -- Eindride Icestorm: Unadorned Symbol of Torden
	[209061] = { 17169, 1 }, -- Kuanbyr Hailstorm: Unadorned Symbol of Torden
	[209142] = { 17169, 1 }, -- Ekil Thundercall: Unadorned Symbol of Torden
	[209146] = { 17169, 1 }, -- Hibdin Cyclone: Unadorned Symbol of Torden
	[209147] = { 17169, 1 }, -- Jolur Sandstorm: Unadorned Symbol of Torden
	[209148] = { 17169, 1 }, -- Oljin Stormtide: Unadorned Symbol of Torden
};

local COMPONENT_LOOT = {
	[209001] = 9421, [209004] = 9421, [209011] = 9421, -- Sandstorm Gem
	[209007] = 9422, [209009] = 9422, [209064] = 9422, -- Lightning Gem
	[209014] = 9423, [209018] = 9423, [209055] = 9423, [209062] = 9423, -- Blizzard Gem
	[209000] = 9424, [209002] = 9424, [209051] = 9424, [209162] = 9424, -- Tornado Gem
	[209015] = 9429, [209040] = 9429, [209041] = 9429, -- Sandstorm Sphere
	[209013] = 9430, [209019] = 9430, [209020] = 9430, -- Lightning Sphere
	[209043] = 9431, [209044] = 9431, [209133] = 9431, [209134] = 9431, [209161] = 9431, -- Blizzard Sphere
	[209048] = 9432, [209050] = 9432, [209135] = 9432, -- Tornado Sphere
};

function ProgressionLootSpawn(e)
	local npc_type = e.self:GetNPCTypeID();
	local guaranteed = GUARANTEED_LOOT[npc_type];

	if ( guaranteed ) then
		for i = 1, guaranteed[2] do
			e.self:AddItem(guaranteed[1], 1);
		end
	end

	local component = COMPONENT_LOOT[npc_type];
	if ( component and math.random(100) <= 25 ) then
		e.self:AddItem(component, 1);
	end
end

function event_encounter_load(e)
	for npc_type, _ in pairs(GUARANTEED_LOOT) do
		eq.register_npc_event("ProgressionLoot", Event.spawn, npc_type, ProgressionLootSpawn);
	end

	for npc_type, _ in pairs(COMPONENT_LOOT) do
		eq.register_npc_event("ProgressionLoot", Event.spawn, npc_type, ProgressionLootSpawn);
	end
end
