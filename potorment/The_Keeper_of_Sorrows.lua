local FlaggingTravel = require("flagging_travel");

function event_death_complete(e)
	local deadline = os.time() + 1800; -- both Tylis copies share thirty minutes from this kill
	-- Start the original database spawn's cooldown at the same time as before.
	-- A temporary copy keeps the earned route open without postponing that timer.
	local entrance = eq.get_entity_list():GetMobByNpcTypeID(207014);
	local position;
	if entrance and entrance.valid then
		position = {entrance:GetX(), entrance:GetY(), entrance:GetZ(), entrance:GetHeading()};
	end
	eq.depop_with_timer(207014); -- Tylis_Newleaf
	if position then
		local copy = eq.spawn2(207014, 0, 0, unpack(position));
		if copy and copy.valid then
			copy:SetBodyType(1, false); -- Maareq's earned release remains usable.
			FlaggingTravel.StartFixed(copy, deadline);
		end
	end
	local rescued = eq.spawn2(207318, 0, 0, -176, 368, -764.8, 0); -- #Tylis_Newleaf
	FlaggingTravel.StartFixed(rescued, deadline);
end
