local MAX_KEYS = 72;

local keys;
local ProjectionEligibility = require("projection_eligibility");

function event_signal(e)
    ProjectionEligibility.OnSignal(e);
end

function event_spawn(e)
    ProjectionEligibility.OnSpawn(e.self, 1200);
	eq.set_timer("depop", 1200000); -- 20 minutes
	keys = 0;
end

function event_timer(e)
	eq.depop();
end

function event_combat(e)
    ProjectionEligibility.OnCombat(e.self, e.joined);
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function event_say(e)
    if ProjectionEligibility.ShowStatus(e, MAX_KEYS) then return; end
    keys = ProjectionEligibility.Count(e.self);
	local qglobals = eq.get_qglobals(e.other);

	if ( ProjectionEligibility.CanFlag(e.self, e.other) ) then

		if ( e.message:findi("hail") ) then 
		
			if ( not qglobals.earthb_key and keys < MAX_KEYS ) then

				e.self:Say("Your will must be strong "..e.other:GetName()..". Seek council with the council of twelve if you so wish.");
				eq.set_global("earthb_key", "1", 5, "F");
				e.other:Message(15, "You have received a character flag!");

				keys = keys + 1;
				if ( keys == MAX_KEYS ) then
					eq.depop();
				end
			end
		end
	end
    ProjectionEligibility.SaveCount(e.self, keys);
end
