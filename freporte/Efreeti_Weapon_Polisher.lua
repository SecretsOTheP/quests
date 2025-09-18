function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "The weapon polisher glances at you while polishing an Efreeti horn, 'Ho, hum. A slave to an Efreeti is never done. Master Dojorn has entrusted me to polish specific [equipment] he's acquired.'");
	elseif(e.message:findi("equipment")) then
		e.other:Message(0,"If you are a disciple of Sky and need your Efreeti War Horn, Standard, Ring, or Spear polished, I am the tradesmith for you. Please hand these and I will polish, sharpen, or fit them free of charge. Return them to me should you wish to reverse the adjustments.");
	end
end


function event_trade(e)
	local item_lib = require("items");
	-- Sharpen Items
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 20831})) then -- Efreeti War Spear
		e.self:Say("Excellent. Please accept this Sharpened Efreeti Spear in return.");
		e.other:QuestReward(e.self,0,0,0,0,30774);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 20763})) then -- Golden Efreeti Ring
		e.self:Say("Excellent. Please accept this Golden Efreeti Band in return.");
		e.other:QuestReward(e.self,0,0,0,0,30771);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 20830})) then -- Efreeti War Horn
		e.self:Say("Excellent. Please accept this Polished Efreeti Horn in return.");
		e.other:QuestReward(e.self,0,0,0,0,30773);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 20817})) then -- Efreeti Standard
		e.self:Say("Excellent. Please accept this Sharpened Efreeti Standard in return.");
		e.other:QuestReward(e.self,0,0,0,0,30772);
	-- Restore items
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 30774})) then -- Sharpened Efreeti Spear
		e.self:Say("Excellent. Please accept this Efreeti War Spear in return.");
		e.other:QuestReward(e.self,0,0,0,0,20831);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 30771})) then  -- Golden Efreeti Band
		e.self:Say("Excellent. Please accept this Golden Efreeti Ring in return.");
		e.other:QuestReward(e.self,0,0,0,0,20763);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 30773})) then -- Polished Efreeti Horn
		e.self:Say("Excellent. Please accept this Efreeti War Horn in return.");
		e.other:QuestReward(e.self,0,0,0,0,20830);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 30772})) then -- Sharpened Efreeti Standard
		e.self:Say("Excellent. Please accept this Efreeti Standard in return.");
		e.other:QuestReward(e.self,0,0,0,0,20817);
	end
	item_lib.return_items(e.self, e.other, e.trade)
end