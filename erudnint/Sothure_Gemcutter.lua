function event_say(e)
	if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
		if(e.message:findi("Hail")) then
			e.self:Say("Nikina Sparlek awaits your arrival inside the Tower of the Craft Keepers. A master enchanter, Nikina has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask her about enchantments.");
		end
	end
end