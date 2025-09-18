function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Good day to you, friend! Tell me, have you [traversed the cold] and the muck to forge through the forsaken tomb of the sleeping dragon? Perhaps you've come across mighty beasts with [prismatic power] beyond imagination?!");
	elseif(e.message:findi("traversed the cold")) then
		e.self:Say("Aha! I knew you looked like a daring and intrepid adventurer! I've been looking for someone like yourself who has made it through that wretched place alive. I haven't had the privelege of coming across any that have had any [proof] they've been there though, so I'm a little skeptical when someone says they have been there, as you can rightly imagine.");
	elseif(e.message:findi("proof")) then
		e.self:Say("What proof? Well, let's see. . . Perhaps you can provide me with some kind of trinket that came from the prismatic dragon himself? I'd be most interested in a scale if you were able to get ahold of one.");
	elseif(e.message:findi("prismatic power")) then
		e.self:Say("Well, I have heard stories of a dragon who was after a prismatic scale and the key to enter the tomb as proof that the sleeping beast had been released. When he took them from the daring adventurers, he destroyed the key because he didn't want those people to return to the tomb. I have no idea why he did this, but if you were one of those unlucky few, please return to me the trinket he gave you and I'll return to you the key to regain entrance to that place.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 2698}, 0)) then -- Essence Lens
		e.other:QuestReward(e.self,0,0,0,0,27265); -- Sleeper's Key
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2699}, 0)) then -- Essence Mace
		e.other:QuestReward(e.self,0,0,0,0,27265); -- Sleeper's Key
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2700}, 0)) then -- Essence Blade
		e.other:QuestReward(e.self,0,0,0,0,27265); -- Sleeper's Key
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2748}, 0)) then -- Essence Pearl
		e.other:QuestReward(e.self,0,0,0,0,27265); -- Sleeper's Key
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2842}, 0)) then -- Essence Ring
		e.other:QuestReward(e.self,0,0,0,0,27265); -- Sleeper's Key
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

