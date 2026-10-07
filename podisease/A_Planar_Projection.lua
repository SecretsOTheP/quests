-- Note: Grummus seems to grant two flags.  The Seer shows both new text ("open before your might")
-- and updated text ("found a small ward to protect") after flagging from him.
-- One flag allows access to CoD and the other is just a continuation of the Fuirstel series.

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
	
	if ( ProjectionEligibility.CanFlag(e.self, e.other) and flags <= FLAG_LIMIT ) then

		if ( e.message:findi("hail") ) then 
		
			if ( qglobals.fuirstel ) then
				if ( qglobals.fuirstel == "1" ) then
					e.other:Message(0, "You recognize the sound of the voice echoing in your mind to be Milyk Fuirstel's.  He tells you before fading, 'I beg of you, return to me with the ward that now envelops your body.  This etheric energy is the only thing that can stop this plague that has been placed upon me.'");
					eq.set_global("fuirstel", "2", 5, "F");
					e.other:Message(15, "You have received a character flag!");
					flags = flags + 1;
					
					if ( qglobals.cl_grummus ) then
						eq.delete_global("cl_grummus");
					end
				end			
			else
				if ( not qglobals.cl_grummus ) then
					e.other:Message(0, "The Planar Projection tells you, 'Now that Grummus has fallen, you must pass into the plane of Bertoxxulous. Deep inside of this castle you will find a room with a large decaying pipe. Push it out of the way and jump into the very plague that is Bertoxxulous' home. Be wary in your travels, for his pestilence shall consume you.'");
					eq.set_global("cl_grummus", "1", 5, "F");
					e.other:Message(15, "You have received a new checklist flag!");
					flags = flags + 1;
				end
			end
			
			if ( not qglobals.grummus ) then
				eq.set_global("grummus", "1", 5, "F");
				flags = flags + 1;
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
