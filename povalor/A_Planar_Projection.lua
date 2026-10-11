local FLAG_LIMIT = 72;

local flags = 0;
local ProjectionEligibility = require("projection_eligibility");

function event_signal(e)
    ProjectionEligibility.OnSignal(e);
end

function event_spawn(e)
    ProjectionEligibility.OnSpawn(e.self, 1200);
	flags = 0;
	eq.set_timer("depop", 1200000); -- 20 minutes
end

function event_timer(e)
	if ( e.timer == "depop" ) then
		eq.depop();
	end
end

function event_say(e)
    if ProjectionEligibility.ShowStatus(e, FLAG_LIMIT) then return; end
    flags = ProjectionEligibility.Count(e.self);
	local qglobals = eq.get_qglobals(e.other);
	
	if ( ProjectionEligibility.CanFlag(e.self, e.other) ) then

		if ( e.message:findi("hail") ) then 
		
			if ( not qglobals.aerindar and qglobals.mavuin and qglobals.mavuin == "3" and flags < FLAG_LIMIT ) then
				e.other:Message(0, "The Planar Projection's thoughts enter your own.  'You have done well. You will now be able to enter the Halls of Honor.'");
				eq.set_global("aerindar", "1", 5, "F");
				-- this projection doesn't give a flag message
				--e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
