function event_spawn(e)
	eq.set_timer("kael",1000);
end

function event_timer(e)
	local qglobals = eq.get_qglobals();
	local idolName = "Idol";
	local avatarName = "Avatar";
	idolName = idolName .. eq.get_zone_guild_id();
	avatarName = avatarName .. eq.get_zone_guild_id();
	if(e.timer == "kael") then
	
		if ( qglobals[idolName] and qglobals[idolName] == "1" ) then
			eq.unique_spawn(113341,0,1,1289,1300,-90,259); -- NPC: #The_Idol_of_Rallos_Zek
		end
		
		if ( qglobals[avatarName] and qglobals[avatarName] == "1" ) then
			eq.unique_spawn(113244,0,1,1292,1058,-95,259); -- NPC: The_Avatar_of_War
		end
		
		eq.stop_timer("kael");
	end
	
end
