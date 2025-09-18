function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Welcome to our home of the finest jewelers in all of Norrath.");
		if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
			e.self:Say("Esdia Moeba awaits your arrival in South Qeynos. A master enchanter, she has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask her about enchantments.");
		end
	elseif(e.message:findi("Tayla")) then
		e.self:Say("I know nothing.");
	end
end
