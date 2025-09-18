function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("I miss my chickens. What I would give to have one more moment with them. They really brought [light] into my life.");
	elseif(e.message:findi("light")) then
		e.other:Message(15, "A light forms in your hand, in memory of Speedz of The Al'Kabor Project.");
		e.other:SummonCursorItem(10292);
	end
end
