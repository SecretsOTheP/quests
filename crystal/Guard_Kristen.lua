function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("It looks like we have ourselves another visitor. This here is Froststone. The last Coldain stronghold on this icy rock.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end