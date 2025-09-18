-- On death, spawns the Avatar of War

function event_death_complete(e)
	local qglobals = eq.get_qglobals();
	local idolName = "Idol";
	local avatarName = "Avatar";
	idolName = idolName .. eq.get_zone_guild_id();
	avatarName = avatarName .. eq.get_zone_guild_id();
	eq.set_global(avatarName,"1",7,"F");
	eq.delete_global(idolName);
	eq.unique_spawn(113244,0,1,1292,1058,-95,259); -- NPC: The_Avatar_of_War
end
