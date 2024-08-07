function event_say(e)
	if(eq.is_the_shadows_of_luclin_enabled()) then
		if(e.message:findi("hail")) then
			e.self:Say("Welcome to Surefall Glade, " .. e.other:GetCleanName() .. ", the home of the Jaggedpine Treefolk. I help teach young druids the ways of our people. We have worshipers of both Karana, the Storm Lord, and Tunare, the All Mother, living here in the glade. If you are a new druid I will help you obtain a [suit of clothing] that will offer comfort and protection while working in the wilds and help protect you from the weapons of the Gnolls that wish to take these lands.");
		elseif(e.message:findi("suit of clothing")) then
			e.self:Say("You must use this specially prepared Curing Kit to craft the clothing. Each article of clothing requires different materials for its construction. Do you plan on crafting Pine Druid [Gloves], Pine Druid [Boots], a Pine Druid [Bracer], a Pine Druid [Cap], Pine Druid [Leggings], Pine Druid [Sleeves], or a Pine Druid [Tunic]? When you have been outfitted and are ready I will tell you of a [task] that you can assist with.");
			e.other:SummonCursorItem(17125); -- Item: Curing Kit
		elseif(e.message:findi("glove")) then
			e.self:Say("To craft Pine Druid Gloves you require two [silk thread], ruined gnoll leather gloves, two giant field rat whiskers, and a large king snake skin. Once you have the necessary components combine them in your Curing Kit with this Tattered Glove Pattern.");
			e.other:SummonCursorItem(19559); -- Item: Tattered Glove Pattern
		elseif(e.message:findi("boot")) then
			e.self:Say("To craft Pine Druid Boots you require two [silk thread], ruined gnoll leather boots, two giant field rat whiskers, and a large whiskered bat fur. Once you have the necessary components combine them in your Curing Kit with this Tattered Boot Pattern.");
			e.other:SummonCursorItem(19561); -- Item: Tattered Boot Pattern
		elseif(e.message:findi("bracer")) then
			e.self:Say("To craft an Pine Druid Bracer you require a [silk thread], a ruined gnoll leather bracer, and a giant field rat whiskers. Once you have the necessary components combine them in your Curing Kit with this Tattered Wristband Pattern.");
			e.other:SummonCursorItem(19558); -- Item: Tattered Wristband Pattern
		elseif(e.message:findi("cap")) then
			e.self:Say("To craft a Pine Druid Cap you require two [silk thread], a ruined gnoll leather cap, a large whiskered bat fur, and a large field rat pelt. Once you have the necessary components combine them in your Curing Kit with this Tattered Cap Pattern.");
			e.other:SummonCursorItem(19555); -- Item: Tattered Cap Pattern
		elseif(e.message:findi("legging")) then
			e.self:Say("To craft Pine Druid Leggings you require three [silk thread], ruined gnoll leather leggings, two large whiskered bat furs, and a giant field rat pelt. Once you have the necessary components combine them in your Curing Kit with this Tattered Pant Pattern.");
			e.other:SummonCursorItem(19560); -- Item: Tattered Pant Pattern
		elseif(e.message:findi("sleeve")) then
			e.self:Say("To craft Pine Druid Sleeves you require two [silk thread], ruined gnoll leather sleeves, two large whiskered bat furs, and a giant field rat pelt. Once you have the necessary components combine them in your Curing Kit with this Tattered Sleeves Pattern.");
			e.other:SummonCursorItem(19557); -- Item: Tattered Sleeve Pattern
		elseif(e.message:findi("tunic")) then
			e.self:Say("To craft a Pine Druid Tunic you require four [silk thread], a ruined gnoll leather tunic, a giant whiskered bat fur, and a giant field rat pelt. Once you have the necessary components combine them in your Curing Kit with this Tattered Tunic Pattern.");
			e.other:SummonCursorItem(19556); -- Item: Tattered Tunic Pattern
		elseif(e.message:findi("silk thread")) then
			e.self:Say("Silk thread is created from two spiderling silks woven together in a sewing kit or loom.");
		elseif(e.message:findi("task")) then
			e.self:Say("We druids seek to live in harmony with nature, taking only what we need from the land and the creatures that inhabit it. Although the City of Qeynos is a noble place, there are people in the city that do not share our reverence for nature and poach the animals of the Karanas needlessly. Even worse than these poachers, whom the rangers of the Jaggedpine Treefolk constantly seek to deter, are the despicable worshipers of Bertoxxulous that hide in the sewers and catacombs of Qeynos. These wicked individuals are known as the [Bloodsabers].");
		elseif(e.message:findi("bloodsabers")) then
			e.self:Say("The Bloodsabers are responsible for a number of atrocities including the spreading of the diseases which have been inflicting the wolves and bears of the Qeynos Hills and the recent poisoning of the farmers fields in the Plains of Karana. Recently we have discovered that a Bloodsaber defiler has been attempting to poison the waters of Surefall Glade. Find this individual and deal with him accordingly, I doubt that this individual will surrender willingly. If need be eliminate them and bring me their head.");
		end
	else
		if(e.message:findi("hail")) then
			e.self:Say("Welcome to Surefall Glade, " .. e.other:GetCleanName() .. ", the home of the Jaggedpine Treefolk. I help teach young druids the ways of our people. We have worshipers of both Karana, the Storm Lord, and Tunare, the All Mother, living here in the glade.");	
		end
	end
end

function event_trade(e)
	local item_lib = require("items");

	if(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 20268})) then
		e.self:Say("It is a shame that some people decide to throw away their humanity with the worship of evil deities. Your actions have saved the lives of many creatures that rely on the waters of this glade. Take this Rusty Pine Druid Scimitar and sharpen it in a forge with a sharpening stone. It may take you several attempts if you are unfamiliar with the process. Once that is done return to me with the Sharpened Pine Druid Scimitar, a Gnoll Fang, and a Large King Snake Skin.");
		-- Confirmed Live Experience and Faction
		e.other:Faction(e.self,272,10,0); -- Jaggedpine Treefolk
		e.other:Faction(e.self,302,2,0); -- Protectors of Pine
		e.other:Faction(e.self,343,1,0); -- QRG Protected Animals
		e.other:Faction(e.self,324,-2,0); -- Unkempt Druids
		e.other:Faction(e.self,262,1,0); -- Guards of Qeynos
		e.other:QuestReward(e.self,{itemid = 20258,exp = 1000}); -- Item: Rusty Pine Druid Scimitar
	elseif(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 20259,item2 = 13915,item3 = 19945})) then
		e.self:Emote("fashions a grip from the large king snake skin, attaches the gnoll fang to the heel of the swords hilt, and polishes the blade of the sword with a luminescent green polish. 'Here is your new weapon young druid. May it serve you well.'");
		-- Confirmed Live Experience and Faction
		e.other:Faction(e.self,272,5,0); -- Jaggedpine Treefolk
		e.other:Faction(e.self,302,1,0); -- Protectors of Pine
		e.other:Faction(e.self,343,1,0); -- QRG Protected Animals
		e.other:Faction(e.self,324,-1,0); -- Unkempt Druids
		e.other:Faction(e.self,262,1,0); -- Guards of Qeynos
		e.other:QuestReward(e.self,{itemid = 20265,exp = 1000}) -- Item: Pine Druid Scimitar
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
