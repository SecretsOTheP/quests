function event_say(e)
	if(e.message:findi("hail")) then
	    e.self:Say("We are [aware] of your presence, fleshling.");
	elseif(e.message:findi("aware")) then
	    e.self:Say("We are those who have been in hiding. We are those who have been in waiting. We are those who await the return of our [Master].");
	elseif(e.message:findi("master")) then
	    e.self:Say("Our Master? Surely all know of our Master now. It was he who was sleeping. It is he who is now freed. We give him honor, loyalty, and our lives. Jaled'Dar, first of our order, set in motion the events that freed our Master. But the Master has departed quickly, perhaps to challenge the Mother herself, such is his power. We wish to aid our Master, but we fear he is not aware that we exist, for his last memory of Wyrmkind was one of treachery and defeat. We believe we know [where he has gone], but we do not know how to reach him.");
	elseif(e.message:findi("where")) then
	    e.self:Say("We believe that he is in a far distant plane, beyond the powers of even the mightiest dragon to reach. He goes places only Veeshan herself was able to visit. We believe he searches for our long departed Mother, to challenge her for rule of the very heavens. If only we had some means of reaching him, we would give him all our aid! We doubt your pitiful mammal brain is capable of devising a plan where we have failed, but we will listen to your chatter, such is our desperation.");
	elseif(e.message:findi("prismatic dragon scale")) then
		e.self:Say("You have a scale? A scale from Kerafyrm himself? His long slumber, or the battles after he was freed, must have weakened him a great deal! One such as our master does not shed. If this is true, and you possess what you say, there is hope for us. With his scale, we can create a focus which gives us a chance to locate him in the far ether. But wait! If you have his scale, you must have been in his tomb! You are the ones who were responsible for freeing him, yes? If this is so, we owe you a debt, for carrying out Jaled'Dar's Plan. Give us the scale and we shall reward you well. We also require the key Jaled'Dar crafted for you to enter the tomb. His tomb is a holy place, and the likes of you should not be allowed to further defile it. We shall not compromise, the key and the scale.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 27329}, 0)) then -- Prismatic Dragon Scale
		e.self:Say("Thank you for returning this to us. Here is your reward, imbued with the essence of a fool who held one of the keys to our Masters prison. If you are unhappy with your reward, return it to us and perhaps we can give you something more appropriate. ");
		e.other:QuestReward(e.self,0,0,0,0,2698); -- Essence Lens
		e.other:Faction(e.self,1526,10);
		e.other:Faction(e.self,430,10);
		e.other:Faction(e.self,304,10);
		e.other:Faction(e.self,448,-30);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2698}, 0)) then -- Essence Lens
		e.other:QuestReward(e.self,0,0,0,0,2699); -- Essence Mace
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2699}, 0)) then -- Essence Mace
		e.other:QuestReward(e.self,0,0,0,0,2700); -- Essence Blade
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2700}, 0)) then -- Essence Blade
		e.other:QuestReward(e.self,0,0,0,0,2748); -- Essence Pearl
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2748}, 0)) then -- Essence Pearl
		e.other:QuestReward(e.self,0,0,0,0,2842); -- Essence Ring
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 2842}, 0)) then -- Essence Ring
		e.self:Say("Make up your mind meddlesome creature.");
		e.other:QuestReward(e.self,0,0,0,0,2698); -- Essence Lens
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
