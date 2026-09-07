eq.load_encounter("Maze");

local guild_id = eq.get_zone_guild_id();
if ( guild_id > 1 or (guild_id == 1 and eq.guild_one_raid_window_open()) ) then
	eq.load_encounter("Mujaki");
end
