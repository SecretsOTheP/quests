local ProjectionEligibility = require("projection_eligibility");

local PLANAR_PROJECTION_TYPE = 205156;

function event_death_complete(e)
	ProjectionEligibility.Spawn(PLANAR_PROJECTION_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0,e.killer);
end
