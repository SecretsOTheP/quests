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

		if ( e.message:findi("hail") and flags < FLAG_LIMIT and not qglobals.saryrn and not qglobals.cipher ) then 
		
			if ( qglobals.tylis and qglobals.tylis == "2" ) then
			
					e.other:Message(0, "The Planar Projection's thoughts enter your own.  'You have done well, now receive the knowledge that Saryrn once held!'  You look down at your arms to see a set of unintelligible runes being burnt into your arms.  The pain is terrible and searing.  Suddenly the sensation is gone and the runes slowly fade.");
					eq.set_global("saryrn", "1", 5, "F");
					e.other:Message(15, "You have received a character flag!");
					flags = flags + 1;
					
					if ( qglobals.cl_saryrn ) then
						eq.delete_global("cl_saryrn");
					end
					
			elseif ( not qglobals.cl_saryrn  ) then
				e.other:Message(0, "The Planar Projection seems to flicker in and out of existence.  It seems to be impressed and grateful for the death of Saryrn.");
				eq.set_global("cl_saryrn", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
