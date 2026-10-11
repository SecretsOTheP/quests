local FlaggingTravel = require("flagging_travel");

function event_spawn(e)
	FlaggingTravel.Start(e.self, 209136);
end

function event_timer(e)
	FlaggingTravel.OnTimer(e);
end
