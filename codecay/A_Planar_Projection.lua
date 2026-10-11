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

		if ( e.message:findi("hail") and flags < FLAG_LIMIT ) then 
		
			if ( not qglobals.bertox_key ) then
                ProjectionEligibility.Notice(e.self, "bertox_key_" .. e.other:CharacterID(), "REJECT: " .. e.other:GetName() .. " lacks bertox_key.");
				return;
			end
			
			local fuirstel = tonumber(qglobals.fuirstel or 0);
			
			if ( fuirstel == 3 ) then
				e.other:Message(0, "Milyk Fuirstel's thoughts enter into your own.  'Bertoxxulous is slain, for this my brother and I are forever in your debt.  Please, when you have the opportunity come visit me in the Plane of Tranquility.  I would like to thank you face to face.'");
				eq.set_global("fuirstel", "4", 5, "F");
				e.other:Message(15, "You have received a character flag!");
				flags = flags + 1;
				
				if ( qglobals.cl_bertox ) then
					eq.delete_global("cl_bertox");
				end
				
			elseif ( not qglobals.cl_bertox and fuirstel < 3 ) then
				e.other:Message(0, "The Planar Projection seems to flicker in and out of existence.  It seems joyous that Bertoxxulous has been slain.");
				e.other:Message(15, "You have received a new checklist flag!");
				eq.set_global("cl_bertox", "1", 5, "F");
				flags = flags + 1;
			end			
		end
	end
    ProjectionEligibility.SaveCount(e.self, flags);
end
