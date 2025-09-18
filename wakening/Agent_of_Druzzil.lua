-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". If you're looking for your bodies from your encounter with the Lord Yelinak or the encounter with the manifestation of the God of Nature Herself, Tunare, you may wish to look near the zone-in to Skyshrine. There seems to be a temporal flux preventing the distribution of corpses to this specific area. If you have no [bodies], I could maybe assist with that. Just ask.");
	elseif(e.message:findi("bod")) then
		e.self:Say("Oh, you can't find your body? Allow me to make one.");
		e.self:CastSpell(982,e.other:GetID(),0,1);
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
