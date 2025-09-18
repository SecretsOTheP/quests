function event_say(e)
	if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
		if(e.message:findi("Hail")) then
			e.self:Say("Kinool Goldsinger awaits your arrival in the mystical confines of the Keepers of the Art in Southern Felwithe. A master enchanter, Kinool has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask him about enchantments.");
		end
	end
end
