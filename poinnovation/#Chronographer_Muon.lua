local Quintessence = require("quintessence_progression");

local MAELIN_TYPE = 206209;

function event_say(e)

	local qglobals = eq.get_qglobals(e.other);
	if ( e.message:findi("hail") or e.message:findi("yes") ) then
		Quintessence.Complete(e.other, qglobals);
	end
	
	if ( qglobals.zebuxoruk == "2" and Quintessence.HasQuintessence(e.other) ) then -- Quintessence of Elements
	
		if ( e.message:findi("hail") ) then
			e.other:Message(0, "Chronographer Muon tells you, 'Acquisition of power completed.  Would you like to be transported to the time-projection chamber?'");
			
		elseif ( e.message:findi("yes") ) then
			e.other:Message(0, "Chronographer Muon tells you, 'Compliance.'");
			e.other:MovePC(206, 291, -860, -1850, 64*2);
			eq.unique_spawn(MAELIN_TYPE, 0, 0, 763, -837, -1887.122, 184);
		end
	else
	
		if ( e.message:findi("hail") ) then
			e.other:Message(0, "Chronographer Muon tells you, 'Greeting acknowledged.  I have no use for you at this time.  Good bye.'");
		end
	end
end
