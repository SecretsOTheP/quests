-- Tallon Zek Planar Projection

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
	
	if ( ProjectionEligibility.CanFlag(e.self, e.other) ) then

		if ( e.message:findi("hail") and flags < FLAG_LIMIT ) then 

			local qglobals = eq.get_qglobals(e.other);
			local zeks = tonumber(qglobals.zeks) or 0;

			if ( zeks == 2 or zeks == 3 ) then
				e.other:Message(0, "You realize that the image is a projection of Maelin Starpyre's thoughts.  His thoughts enter into your own.  'The pack of notes you now possess from Tallon, bring them to me.  I would like to more closely study them'");
				if ( zeks == 2 ) then -- no VZ flag
					eq.set_global("zeks", "4", 5, "F"); -- 4 means just TZ flagged
				elseif ( zeks == 3 ) then -- 3 means has VZ flag; does not have TZ flag
					eq.set_global("zeks", "5", 5, "F"); -- 5 means VZ and TZ flagged
				end
				e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
				
				if ( qglobals.cl_tallon ) then
					eq.delete_global("cl_tallon");
				end
			elseif ( zeks < 2 and not qglobals.cl_tallon ) then
				e.other:Message(0, "The Planar Projection seems to flicker in and out of existence.  It seems to be impressed by the defeat of Tallon Zek.");
				eq.set_global("cl_tallon", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
