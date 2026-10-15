function event_spawn(e)
	if (e.self:GetNPCTypeID() ~= 207028) then
		return;
	end

	-- The reward form owns this stage until it dies or despawns. Defer the
	-- entry form through its normal spawn timer, preserving guild Slow Down.
	if (eq.get_entity_list():IsMobSpawnedByNpcTypeID(207319)) then
		eq.depop_with_timer();
	end
end
