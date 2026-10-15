function event_spawn(e)
	-- Also handle the reward form loading after an existing entry form.
	eq.depop_with_timer(207028);
	eq.set_timer("depop", 43200000);
end

function event_timer(e)
	eq.depop();
end
