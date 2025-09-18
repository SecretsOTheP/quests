function event_say(e)
	if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
		if(e.message:findi("Hail")) then
			e.self:Say("Drizm J`Axx awaits your arrival in Neriak Commons. A master enchanter, Drizm has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask him about enchantments.");
		end
	end
end
