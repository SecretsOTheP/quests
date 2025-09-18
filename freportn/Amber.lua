function event_say(e)
	if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
		if(e.message:findi("Hail")) then
			e.self:Say("Glyssa Sonshaw awaits your arrival outside the Academy of Arcane Science. A master enchanter, Glyssa has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask her about enchantments.");
		end
	end
end