-- Vallon Zek Planar Projection

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
	
	if ( ProjectionEligibility.CanFlag(e.self, e.other) ) then

		if ( e.message:findi("hail") and flags < FLAG_LIMIT ) then 
		
			local qglobals = eq.get_qglobals(e.other);
			local zeks = tonumber(qglobals.zeks) or 0;
			
			if ( zeks == 2 or zeks == 4 ) then
				e.other:Message(0, "You realize that the image is a projection of Maelin Starpyre's thoughts.  His thoughts enter into your own.  'The pack of notes you now possess from Vallon, bring them to me.  I would like to more closely study them'");
				if ( zeks == 2 ) then -- no VZ or TZ flag
					eq.set_global("zeks", "3", 5, "F"); -- 3 means just VZ flagged
				elseif ( zeks == 4 ) then -- 4 means has TZ flag; does not have VZ flag
					eq.set_global("zeks", "5", 5, "F"); -- 5 means VZ and TZ flagged
				end
				e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
				
				if ( qglobals.cl_vallon ) then
					eq.delete_global("cl_vallon");
				end
			elseif ( zeks < 2 and not qglobals.cl_vallon ) then
				e.other:Message(0, "The Planar Projection seems to flicker in and out of existence.  It seems to be impressed by the defeat of Vallon Zek.");
				eq.set_global("cl_vallon", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
