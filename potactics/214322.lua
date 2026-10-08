-- Rallos Zek Planar Projection

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
			
			if ( zeks == 6 ) then
				e.other:Message(0, "Maelin Starpyre's thoughts enter into your own.  'The singed parchment of Rallos lies in his dead hand.  Bring it back to me I will translate them using the Cipher of Druzzil.'");
				eq.set_global("zeks", "7", 5, "F");
				e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
				
				if ( qglobals.cl_rallos ) then
					eq.delete_global("cl_rallos");
				end
			elseif ( zeks < 6 and not qglobals.cl_rallos ) then
				e.other:Message(0, "The Planar Projection seems to flicker in and out of existence.  It seems to be impressed by the defeat of Rallos Zek.");
				eq.set_global("cl_rallos", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
