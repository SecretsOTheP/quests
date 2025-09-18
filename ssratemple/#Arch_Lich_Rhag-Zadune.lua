-- Last of the arch lich rhag`zadune cycle

function event_death_complete(e)
	local lichName = "Lich";
	lichName = lichName .. eq.get_zone_guild_id();
	eq.delete_global(lichName);
end
