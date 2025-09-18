-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("BZZT... Greetings, " .. e.other:GetCleanName() .. ". This book leads to the Quarm is War (Battle of the Best) event. I am legally and contractually obligated to inform you that I am NOT the Goddess of Magic, Druzzil Ro. I am but a gnomish automaton set up to function like her.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
