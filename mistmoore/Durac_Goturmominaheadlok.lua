function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Sup nerds, you should feel blessed to be in the presence of such a Necro. I know i'm the [light] of your life, babe.");
	elseif(e.message:findi("light")) then
		e.other:Message(15, "A light forms in your hand, in memory of Durac of <Tranquility>.");
		e.other:SummonCursorItem(10292);
	end
end
