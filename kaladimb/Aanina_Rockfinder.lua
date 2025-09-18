function event_say(e)
	if(e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1) then
		if(e.message:findi("Hail")) then
			e.self:Say("Kinool Goldsinger awaits your arrival in the mystical confines of the Keepers of the Art in Felwithe. A master enchanter, Kinool has the power to weave spells that bind the essence of magic to your silver and gold. Go forth and ask him about enchantments.");
		end
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 20879})) then
		e.self:Say("Ah, nice of you to come and pick this up for Ganelorn! I know he is a busy fellow. I certainly hope that his girlfriend will like this gift.");
		e.other:QuestReward(e.self,{itemid = 20880}); -- Item: A Gift
	end
end

-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd and manual edits by Speedz
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
