-- Keep ordinary ring mobs in the open world without allowing their raid
-- encounters to start. Guild 2+ retains all four rings, while Guild 1 only
-- receives them during an enabled raid window.
local guild_id = eq.get_zone_guild_id();
if ( guild_id > 1 or (guild_id == 1 and eq.guild_one_raid_window_open()) ) then
	eq.load_encounter("StoneRing");
	eq.load_encounter("MudRing");
	eq.load_encounter("VineRing");
	eq.load_encounter("DustRing");
end

eq.load_encounter("Traps");
