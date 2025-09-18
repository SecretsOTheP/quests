function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("so two monks and two rogues walk into a bar.... one asks for a [light]");
	elseif(e.message:findi("light")) then
		e.other:Message(15, "A light forms in your hand, in memory of Caducaeus of <Savage>.");
		e.other:SummonCursorItem(10292);
	end
end
