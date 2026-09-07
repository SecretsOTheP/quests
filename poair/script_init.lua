-- Raid rings and Xegony run in Guild 2+ and during an active Guild 1 quake.
-- Open world and inactive Guild 1 retain normal trash and individual scripts.
local guild_id = eq.get_zone_guild_id();
if ( guild_id > 1 or (guild_id == 1 and eq.guild_one_raid_window_open()) ) then
	eq.load_encounter("Wind");
	eq.load_encounter("Smoke");
	eq.load_encounter("Mist");
	eq.load_encounter("Dust");
	eq.load_encounter("Xegony");
end
