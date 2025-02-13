function event_say(e)
	if(eq.is_the_shadows_of_luclin_enabled()) then
		if(e.message:findi("hail")) then
			e.self:Say("A pleasure to make your acquaintance " .. e.other:GetCleanName() .. ". I am Kaya Cloudfoot, first Paladin of the Storm Reapers. I traveled long ago when I was just a wee sprout to the city of Qeynos far to the west. It was there I grew under the tutelage of the Knights of Thunder, a noble order of paladins loyal to Karana, the Storm Lord. I have returned now to Rivervale to teach interested young halflings the ways of a Knight of the Storm Reapers so that we may defend Karanas people and lands from the [evil forces] that would see it destroyed.");
		elseif(e.message:findi("evil forces")) then
			e.self:Say("There are many problems and creatures that trouble Karanas people through out Norrath and threaten our otherwise peaceful ways of life. Our common folk here in Rivervale are troubled by the wicked Teir`Dal, the Death Fist Orcs, and the Goblins of Clan Runnyeye and Pickclaw. It is the calling and duty of a Knight of the Storm Reapers to defend the common folk from these enemies of Rivervale. Are you willing to [defend the commoners]?");
		elseif(e.message:findi("commoners")) then
			e.self:Say("You have made an honorable decision, " .. e.other:GetCleanName() .. ". First you will need to be outfitted in a suit of armor to protect you from the weapons of our foes. Seek Jimji Bottletoe here in Rivervale and give him this letter. Jimji will instruct you further on acquiring a suit of armor worthy of a new Knight of the Storm Reapers. When you have been outfitted in your Bravefoot Armor return to me and I shall prepare you for your [next task].");
			e.other:SummonCursorItem(19628); -- Item: Letter to Jimji Bottletoe
		elseif(e.message:findi("next task")) then
			e.self:Say("The Teir'Dal, or Dark Elves that reside in the underground city of Neriak to the east beyond the Commonlands have long been a bane to us Storm Reapers. Many of our Druids have fallen attempting to hold back the tide of hate and destruction that has taken hold on the Nektulos Forest and threatens the surrounding lands. It was also the Teir`Dals patron God, Innorruuk, who caused the [Curse of Bloody Kithicor]. Are you ready to [face the Teir'Dal] and bloody your hands for the protection of your Shire and our commoners humble way of life?");
		elseif(e.message:findi("curse of bloody kithicor")) then
			e.self:Say("There was a great war that was fought not long ago between the Teir'Dal, and their evil minions, and the armies of Felwithe, Qeynos, Freeport, and Kaladim. In the Kithicor Woods the Daughter of Innoruuk, Lanys T'Vyl, and her minions fought against the chosen of Tunare, Firiona Vie, and her most loyal allies. The evil God of Hate, Innoruuk, intervened every living creature in the Kithicor Woods instantly fell dead as a great rift to the Plane of Hate appeared in the sky. Since that time, when night falls on the Kithicor Woods blood seeps from the trees and ground and the hateful dead hunt any living being who dares to trespass in the woods that ended their lives.");
		elseif(e.message:findi("face the teir")) then
			e.self:Say("Some days ago one of our Storm Reapers, a ranger by the name of Botim Bonker, ventured into the Kithicor Forest at daybreak on a routine patrol and never returned. That night his bloodied tunic was found hanging on a fence post of Tagglefoots Farm. The blood was dried and many hours old. We believe that he was slain during the day and that deduction coupled with the fact the undead of Kithicor do not leave the woods nor possess the intelligence or means to sneak into Rivervale and leave the tunic where it would surely be found by fellow Storm Reapers led us to believe they were not responsible. We believe it was the work of the Teir'Dal. Search the Kithicor Woods by daylight and punish the Teir'Dal responsible. Return with the villains severed hands as proof of his death.");
		end
	end
end

function event_trade(e)
	local item_lib = require("items");

	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 18431})) then -- Halfling Paladin Note
		e.self:Say("Karana smiles upon you young " .. e.other:GetCleanName() .. "! Take this tunic to keep you warm through the storms you must face. There is evil encroaching upon the lands of Karana's faithful. The wicked minions of Bertoxxulous and the Teir'Dal children of Hate corrupt the lands to the west and east, and the Deathfist Clan of Orcs are waging war on this region while destoying the wilderness for lumber and stone. It is Karana's will that we defend our lands and way of life from these evil threats.");
		e.other:Faction(e.self,355,100,0); -- +Storm Reapers
		e.other:Faction(e.self,286,10,0); -- +Mayor Gubbin
		e.other:Faction(e.self,292,15,0); -- +Merchants of Rivervale
		e.other:Faction(e.self,324,-15,0); -- -Unkempt Druids
		e.other:QuestReward(e.self,0,0,0,0,13541,100); -- Jumjum Sack Tunic*
	elseif(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 19688})) then
		e.self:Say("Take this Dull Bravefoot Short Sword to the forge at Tagglefoots farm and sharpen it with a sharpening stone. It may take several attempts if you are unfamiliar with the process. Once that is done present the blade and a large snake skin to Bodbin Gimple and he will put the finishing touches on the sword.");
		e.other:Faction(e.self,355,10,0); -- +Storm Reapers
		e.other:Faction(e.self,286,1,0); -- +Mayor Gubbin
		e.other:Faction(e.self,292,1,0); -- +Merchants of Rivervale
		e.other:Faction(e.self,324,-1,0); -- -Unkempt Druids
		e.other:QuestReward(e.self,0,0,0,0,19625,10); -- Item: Dull Bravefoot Short Sword
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-- END of FILE Zone:rivervale  ID:19049 -- Kaya_Cloudfoot
