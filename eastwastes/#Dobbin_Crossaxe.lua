function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Greetings, " .. e.other:GetCleanName() .. ". Thank you for breaking Corbin free!");
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 30162}, 0)) then
		e.self:Say("Thank you, " .. e.other:GetCleanName() .. ". Your deeds will be mentioned to  the Dain. Please take this note from Corbin to Garadain. It may help him to achieve victory over the enemy.");
		e.other:Faction(e.self,406,15); -- Coldain
		e.other:Faction(e.self,405,3); -- Dain Frostreaver IV
		e.other:Faction(e.self,448,-1); -- Kromzek
		e.other:Faction(e.self,419,-7); -- Kromrif
		e.other:QuestReward(e.self,0,0,0,0,1047,5000);
		eq.depop();
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
