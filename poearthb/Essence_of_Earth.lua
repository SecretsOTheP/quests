local FLAG_LIMIT = 72;

local flags = 0;
local ProjectionEligibility = require("projection_eligibility");

function event_signal(e)
    ProjectionEligibility.OnSignal(e);
end

function event_spawn(e)
    ProjectionEligibility.OnSpawn(e.self, 1200);
	eq.set_timer("depop", 1200000);
	flags = 0;
end

function event_combat(e)
    ProjectionEligibility.OnCombat(e.self, e.joined);
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function event_timer(e)
	if ( e.timer == "depop" ) then
		eq.depop();
	end
end

function event_say(e)
    if ProjectionEligibility.ShowStatus(e, FLAG_LIMIT) then return; end
    flags = ProjectionEligibility.Count(e.self);
    if flags >= FLAG_LIMIT then eq.depop(); return; end

	if ( ProjectionEligibility.CanFlag(e.self, e.other) and e.message:findi("hail") ) then
		
		if ( not e.other:HasItem(29146) and not e.other:HasItem(29165) ) then -- Mound of Living Stone, Quintessence of Elements
			e.other:SummonCursorItem(29146); -- Item: Mound of Living Stone
			flags = flags + 1;
		end
		
		if ( flags >= FLAG_LIMIT ) then
			eq.depop();
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
