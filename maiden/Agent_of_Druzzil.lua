-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". If you're looking for your bodies from your encounter in the Akheva Ruins, or your encounter with Doomshade, you may wish to look near the Dawnshroud Peaks tunnel. There seems to be a temporal flux preventing the distribution of corpses to this specific area. Did you happen to find the shade with a big [Lute]?");
	elseif(e.message:findi("Lute")) then
		e.self:Say("You will find no 'phat lute' here.");
		e.self:CastSpell(982,e.other:GetID(),0,1);
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
