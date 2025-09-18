-- On death, spawns the Idol of Rallos Zek

function event_death_complete(e)
	local idolName = "Idol";
	idolName = idolName .. eq.get_zone_guild_id();
	e.self:Shout("Protect the Idol of Zek!");
	eq.set_global(idolName,"1",7,"F");
	eq.unique_spawn(113341,0,1,1289,1300,-90,259); -- NPC: #The_Idol_of_Rallos_Zek
end

function event_combat(e)

	if (e.joined) then
		eq.signal(113131, 1); -- NPC: Armor_of_Zek
	end
end
