function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Emote("Hail, and well met, friend. I am Gwelian Wyn, Wild Spirit of the Faydark. My daughter went out to play with the tree spirits near Felwithe. She's been out on a trip. I haven't heard from her in a bit. Could you check on her? There have been reports of strange magical energy brewing in the area.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 505})) then
		e.self:Emote("gasps. W-what... Oh. This- this shard feels...' Gwelian pauses for a moment, and sees visions of every animal at once. This causes her to be mentally consumed for a moment.");
		e.other:Message(15, "An animalistic echo rings through your head. 'Thank you for putting an end to Khati's plans, mortal. I am Sahteb Mahlni, the animalistic spirit.' This mortal woman was my manifestation to warn Norrath of Khati Sha. Khati Sha was the Animist of the Vah Shir. He became corrupted when he was taken from his time and consumed the spirits of Norrathians across time and space. Druzzil Ro can no longer be trusted. You mortals alone can stop her. I do not have long. Please, for your help, accept my blessing.'");
		e.other:AddCharacterCreateCombinationUnlock(eq.FindClass("beastlord"), eq.FindRace("wood elf"), eq.FindDeity("tunare"), eq.FindCityChoice("kelethin"), 54, 64, 192, 33, 0);
	
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
