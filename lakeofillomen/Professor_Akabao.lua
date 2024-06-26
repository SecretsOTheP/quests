-- Part of quest for Veeshan's Peak key
function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Salutations, traveler! I dont get many visitors in these isolated regions. Have you come to learn of the ancient tribes of the Iksar?");
	elseif(e.message:findi("tribes")) then
		e.self:Say("There were five tribes of Iksars that rose from the ashes of the Shissar Empire and founded their kingdoms on the continent of Kunark. Three of the tribes were extinguished many years later by the Kunzar tribe which is the tribe that the current Iksar are descendant from. I focus my studies on learning of the extinct tribe of Kylong.");
	elseif(e.message:findi("kylong")) then
		e.self:Say("The Kylong were a mountain dwelling tribe of Iksar that strove for esoteric knowledge. They had vast libraries of ancient magical tomes that had been acquired from the Shissar sorcerers, and strove to understand and put the rituals documented in the tomes to practical use. When the Kunzar armies marched upon the Kylong, the three greatest Kylong mystics shattered the Medallion of Kylong, a holy relic of their tribe, and fled their mountain homes in order to prevent the Kunzar from reassembling the Medallion of Kylong.");
	elseif(e.message:findi("medallion")) then
		e.self:Say("I have been attempting to learn of the destinations of the three Kylong leaders that held the fragments of the medallion. I know only that they sought shelters to hide and continue the practice of their mystical arts In order to one day return their tribe to it's former glory. Their remains may exist beneath some of the fortresses that are centers of Iksar and Sarnak necromancy. I have seen indications that some of the tomes within those fortresses are in fact the very tomes once cherished by the Kylong. Should you manage to recover the broken pieces of the Medallion of Kylong bring them to me so that I may restore the ancient artifact.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	local text = "Are you daft? How can I reconstruct the medallion of the Kylong without all three pieces?!";	
	
	if(item_lib.check_turn_in_nomq(e.self, e.trade, {item1 = 19962, item2 = 19963, item3 = 19964},1,text)) then
		e.self:Say("For ages this medallion has been scattered across these inhospitable lands, I had just about given up hope of locating the pieces and rebuilding this piece of Iksar history. You may keep it. It is enough to know that I have done my part to restore such an artifact to the people of Norrath.");
		e.other:QuestReward(e.self,0,0,0,0,19955,1000);
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-- Quest by mystic414
-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd and manual edits by Speedz
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
