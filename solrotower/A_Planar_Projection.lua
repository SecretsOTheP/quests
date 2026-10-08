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

		-- this will need to be removed if the 85/15 thing gets implemented
		if ( not qglobals.sol_room or qglobals.sol_room ~= "11111" ) then			
			return;
		end
		
		if ( e.message:findi("hail") and flags < FLAG_LIMIT and (not qglobals.pofire or qglobals.pofire ~= "2") ) then 
		
			if ( qglobals.pofire and qglobals.pofire == "1" and qglobals.zeks and qglobals.zeks == "7" ) then
			
					e.other:Message(0, "Miak the Searedsoul's thoughts enter into your own.  'That is it!  The portal into the Plane of Fire lies within the Lava Well of Ro.  You must now fall into this well to gain access into that plane.  I will make adjustments to the Plane of Tranquility portal so that you can access that Element from here as well.'");
					eq.set_global("pofire", "2", 5, "F");
					e.other:Message(15, "You have received a character flag!");
					flags = flags + 1;
					
					if ( qglobals.cl_solusek ) then
						eq.delete_global("cl_solusek");
					end
					
			elseif ( not qglobals.cl_solusek  ) then
				e.other:Message(0, "The Planar Projection flickers in and out of existence.  It seems to be impressed by the defeat of Solusek Ro.");
				eq.set_global("cl_solusek", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
