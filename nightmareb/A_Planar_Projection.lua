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
    flags = ProjectionEligibility.Count(e.self);
	local qglobals = eq.get_qglobals(e.other);
	
	if ( ProjectionEligibility.CanFlag(e.self, e.other) ) then

		if ( e.message:findi("hail") ) then 
		
			if ( qglobals.thelin ) then
				if ( qglobals.thelin == "2" and flags < FLAG_LIMIT ) then
					e.other:Message(0, "You recognize the voice in your mind to be Thelin Poxbourne's.  The words echo, 'The cruel hand of Terris no longer shall torment my dreams.  Thank you friends, you are my savior.  Please return to me in the Plane of Tranquility.  I would like to express to you my gratitude.'");
					eq.set_global("thelin", "3", 5, "F");
					e.other:Message(15, "You have received a character flag!");
					flags = flags + 1;
					
					if ( qglobals.cl_terris ) then
						eq.delete_global("cl_terris");
					end
				end
			elseif ( not qglobals.thelin or qglobals.thelin == "1" ) then
				if ( not qglobals.cl_terris and flags <= FLAG_LIMIT ) then
					-- no text for this checklist flag; probably because it wasn't possible to enter the zone without the maze flag when the first made it
					eq.set_global("cl_terris", "1", 5, "F");
					e.other:Message(15, "You have received a new checklist flag!");
					flags = flags + 1;
				end
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
