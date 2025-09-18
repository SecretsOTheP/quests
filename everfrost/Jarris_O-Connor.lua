function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Emote("is fighting his wounds, and does not respond to your inquiry.");
	elseif(e.message:findi("truth")) then
		e.self:Say("The truth is that Marr never left us. I was given this blue, faintly glowing blade by a kind [woman]. A human figure with a massive platinum crown, with a single white gem in her brow. And a beautiful gown. According to her, this blade was forged in the Halls of Honor itself! She was a beauty... almost as if she resembled a goddess. She said we all could still be saved and redeemed in the eyes of Mithaniel because we knew the Truth.");
	elseif(e.message:findi("kerran")) then
		e.self:Say("No sooner than she appeared, a few minutes passed, and I was accosted by a grisly spirit of a Kerran. Or, an undead one at least. I couldn't tell for sure. One moment, he seemed like a friendly face, the next... I woke up, injured, and on a rock, bleeding out, not far from here. I had a few bandages, and tended to my wounds.");
	elseif(e.message:findi("brother")) then
		e.self:Say("My brother, Ervan, is probably expecting firewood Halas still. Go. Tell him, and show him proof that the Truthbringer's light remains in our people, and that Mithaniel Marr did not abandon us.");
	elseif(e.message:findi("druzzil")) then
		e.self:Say("The God of Magic? Perhaps. Then it is true!! It is a sign. Perhaps we Barbarians were destined to be Paladins after all, being of His image. Go, friend. Show my brother the Truth!");
	elseif(e.message:findi("woman")) then
		e.self:Say("I don't know who she was. Might 'ave been a sorcerer. Not of these parts, at any rate. Sorry. You may be more familiar with her than I. Perhaps you might know her name?");
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 14425})) then
		e.self:Say("By Marr's Light! You found my note. Thank the Truthbringer you have arrived. I need you to visit my [brother] in Halas. Bring him this glowing blade that shows evidence of [Truth] and my crumpled note. It will show him that I still live. I am still tending to my [injuries] from my fight with that... [undead Kerran].");
		e.other:QuestReward(e.self,0,0,0,0,998,0);
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 997, item2 = 16476, item3 = 12144, item4 = 13865})) then
		e.other:Message(0, "Jarris begins to speak in a voice that is not his own... 'Thank you, kind spirit. You've passed my trial. Take this for your kindness. Perhaps we shall meet again in the Halls of Honor.' The world stands still for a moment, as he grants you the Soul Fragment of a Barbarian Paladin.");
		e.other:QuestReward(e.self,0,0,0,0,500,0);
		e.other:Message(15, "You can now new game plus into a Barbarian Paladin of Halas that worships either Mithaniel Marr or The Tribunal.");
		e.other:AddCharacterCreateCombinationUnlock(eq.FindClass("paladin"), eq.FindRace("barbarian"), eq.FindDeity("tribunal"), eq.FindCityChoice("halas"), 30, 629.0, 3139.0, 0.0, 0);
		e.other:AddCharacterCreateCombinationUnlock(eq.FindClass("paladin"), eq.FindRace("barbarian"), eq.FindDeity("mithaniel"), eq.FindCityChoice("halas"), 30, 629.0, 3139.0, 0.0, 0);
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
