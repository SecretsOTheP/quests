function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Emote("woofs!");
	elseif(e.message:findi("who's a good boy")) then
		e.other:Message(15, "A light forms in your hand, in memory of Harley.");
		e.other:SummonCursorItem(10292);
	end
end
