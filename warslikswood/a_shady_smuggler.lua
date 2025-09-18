function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Well met!");
	elseif(e.message:findi("Smuggler")) then
		e.self:Say("Me? A smuggler? What would give you that idea?!");
	elseif(e.message:findi("Heartsting")) then
		e.self:Say("Heartsting venom you say? That could be very valuable if extracted properly...");
	elseif(e.message:findi("reagents")) then
		e.self:Say("You're looking for spell reagents? What kind? An exotic fire beetle eye mayhaps?!");
	elseif(e.message:findi("fire beetle eye")) then
		e.self:Say("Oh, of course I have fire beetle eyes! I'd even happily trade you one, for say... two of your scarab eyes?");
	end	
end

function event_trade(e)
	local item_lib = require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 851})) then -- Heartsting Extraction	
		e.self:Say("Aaahah! Thank you for delivering this. I've been waiting for this for a while. Oh, you want your goods, of course! Here you go, make sure this gets delivered to your masters.");
		e.other:QuestReward(e.self,{itemid = 849, exp = 1000});	-- Smuggled Shipment
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 13847, item2 = 13847})) then -- 2x Scarab Eye
		e.self:Say("Perfect! Beautiful specimens. The eggheads back home will love researching these!");
		e.other:QuestReward(e.self,{itemid = 10307});	-- Fire Beetle Eye
	else
		item_lib.return_items(e.self, e.other, e.trade)
	end
end