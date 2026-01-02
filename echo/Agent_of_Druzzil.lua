-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". If you're looking for your bodies from your encounter in the Fungus Grove, or your encounter with the Burrower or Overfiend, you may wish to look near the Deep zoneline. There seems to be a temporal flux preventing the distribution of corpses to this specific area. Sorry, friend. There are no [free rides] in this world.");
	elseif(e.message:findi("free ride")) then
		e.self:Say("You're rather pathetic. I am not even going to kill you for that one.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
