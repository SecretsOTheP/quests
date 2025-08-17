-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". If you're looking for your bodies from your competitive encounter in the Estate of Unrest, you may wish to look near the island to the north. There seems to be a flux of energy preventing the distribution of corpses to this specific area.");
	elseif(e.message:findi("bod")) then
		e.self:Say("Yes, the ones near the island. It's a bit of a swim. Were you expecting something [else]?");
	elseif(e.message:findi("else")) then
		e.self:Say("Oh, do you mean THIS???");
		e.self:CastSpell(982,e.other:GetID(),0,1);
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
