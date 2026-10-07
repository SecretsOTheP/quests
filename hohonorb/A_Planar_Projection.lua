local FLAG_LIMIT = 72 * 2;

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
	
	if ( e.message:findi("hail") and ProjectionEligibility.CanFlag(e.self, e.other) and flags <= FLAG_LIMIT ) then

		if ( not qglobals.mmarr and not qglobals.cipher ) then
		
			if ( qglobals.hohtrials and qglobals.hohtrials == "111" ) then
				e.other:Message(0, "The Planar Projection's thoughts enter your own.  'You have done well, now receive the knowledge that Mithaniel Marr once held!'  You look down at your arms to see a set of unintelligible runes being burnt into your arms.  The pain is terrible and searing.  Suddenly the sensation is gone and the runes slowly fade.  Also among your possessions you find a small tattered book as old as the ages.  You recognize it as something that Maelin might be able to translate.");
				eq.set_global("mmarr", "1", 5, "F");
				e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
				
				if ( qglobals.cl_mmarr ) then
					eq.delete_global("cl_mmarr");
				end
			elseif ( not qglobals.cl_mmarr ) then
				e.other:Message(0, "The Planar Projection's thoughts enter your own.  'You have done well, however you are not ready to understand the Knowledge gained for defeating Mithaniel Marr.  Once you have learned more this knowledge will be revealed to you.'");
				eq.set_global("cl_mmarr", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
		
		if ( not qglobals.zebuxoruk and not qglobals.mmarr_book ) then
		
			if ( qglobals.hohtrials and qglobals.hohtrials == "111" ) then
				eq.set_global("mmarr_book", "1", 5, "F");
				flags = flags + 1;
				
				if ( qglobals.cl_mmarr_book ) then
					eq.delete_global("cl_mmarr_book");
				end
			elseif ( not qglobals.cl_mmarr_book ) then
				eq.set_global("cl_mmarr_book", "1", 5, "F");
				flags = flags + 1;
			end		
		end		
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
