function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "S`Dahg says, 'Nice'");
	elseif(e.message:findi("nice")) then
		e.other:SummonCursorItem(32001);
	end
end
