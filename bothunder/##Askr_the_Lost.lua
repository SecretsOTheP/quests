local FlaggingTravel = require("flagging_travel");

function event_say(e)
	if not FlaggingTravel.CanUse(e.self) then return; end
	if ( e.message:findi("hail") ) then 
		e.self:Say("Well done "..e.other:GetName()..".  You have succeed where I have failed, but now comes the most dangerous peril the Bastion holds.  The final level of Torden holds the restless spirit of the Rainkeeper himself.  You must find a way to free him from his tormented sleep.  His dreams and visions have coalesced into a dark shade of himself which controls the full fury of the [Storm].");
		
	elseif ( e.message:findi("what storm") ) then
		e.self:Say("The spirit of chaos itself guards the chamber where Karana sleeps.  Chaos will most certain protect the embodiment of his tortured conscious as if it were the Rainkeeper himself.  I am afraid that there is no assistance that I can offer in the task laid out before you aside from opening the vortex to Chaos and offer you Karana's blessing.");
		eq.unique_spawn(209158, 0, 0, -1110, -1735, 1740, 0); -- A_Chaotic_Vortex
	end
end

function event_spawn(e)
	FlaggingTravel.Start(e.self, 209136);
end

function event_timer(e)
	FlaggingTravel.OnTimer(e);
end
