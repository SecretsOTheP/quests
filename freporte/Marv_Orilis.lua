function event_say(e)
	if(eq.is_the_shadows_of_luclin_enabled()) then
		if(e.message:findi("hail")) then
			e.self:Say("Yes? I am a very busy man. I assist new necromancers, wizards, magicians, and enchanters that have joined the Dismal Rage. Are you a sorcerer that has [recently joined] us? ");
		elseif(e.message:findi("recently joined")) then
			e.self:Say("Then I welcome you to the path of rage. We sorcerers fulfill a crucial role within the Dismal Rage. Under the guidance of Opal Darkbriar, a founder of our order, we study the darkest aspects of the various sorcerous arts so that we may aid and bring power to others who follow our patron deity, Innoruuk, the Prince of Hate. If you desire I will help you obtain a suit of [protective clothing] suitable for a practitioner of the sorcerous arts. Once you have been properly outfitted, return to me and I will aid you in obtaining a [Staff of Dismal Rage].");
		elseif(e.message:findi("protective clothing")) then
			e.self:Say("You will require this Curing Kit to craft your clothing and robe. The materials required vary depending on the article of clothing you desire to craft. Do you desire to craft a [rage sorcerer cap], [rage sorcerer wristband], [rage sorcerer gloves], [rage sorcerer boots], [rage sorcerer sleeves], [rage sorcerer pantaloons], or [rage sorcerer robe]?");
			e.other:SummonCursorItem(17125); -- Item: Curing Kit
		elseif(e.message:findi("rage sorcerer cap")) then
			e.self:Say("To craft a Rage Sorcerer Cap you will require two [silk thread], gila monster hatchling bile, and a young gila monster skin. Once you have the necessary components combine them in your Curing Kit with this Tattered Cap Pattern.");
			e.other:SummonCursorItem(19555); -- Item: Tattered Cap Pattern
		elseif(e.message:findi("rage sorcerer wristband")) then
			e.self:Say("To craft a Rage Sorcerer Wristband you require a [silk thread], gila monster hatchling bile, and a rattlesnake skin. Once you have the necessary components combine them in your Curing Kit with this Tattered Wristband Pattern.");
			e.other:SummonCursorItem(19558); -- Item: Tattered Wristband Pattern
		elseif(e.message:findi("rage sorcerer gloves")) then
			e.self:Say("To craft Rage Sorcerer Gloves you require two [silk thread], gila monster hatchling bile, two desert spiderling hairs, and a young gilla monster skin. Once you have the necessary components combine them in your Curing Kit with this Tattered Glove Pattern.");
			e.other:SummonCursorItem(19559); -- Item: Tattered Glove Pattern
		elseif(e.message:findi("rage sorcerer boots")) then
			e.self:Say("To craft Rage Sorcerer Boots you require two [silk thread], gila monster hatchling bile, and two ruined coyote pelts. Once you have the necessary components combine them in your Curing Kit with this Tattered Boot Pattern.");
			e.other:SummonCursorItem(19561); -- Item: Tattered Boot Pattern
		elseif(e.message:findi("rage sorcerer sleeves")) then
			e.self:Say("To craft Rage Sorcerer Sleeves you require two [silk thread], young gila monster bile, and two young gilla monster skins. Once you have the necessary components combine them in your Curing Kit with this Tattered Sleeves Pattern.");
			e.other:SummonCursorItem(19557); -- Item: Tattered Sleeve Pattern
		elseif(e.message:findi("rage sorcerer pantaloons")) then
			e.self:Say("To craft Rage Sorcerer Pantaloons you require two [silk thread], young gila monster bile, and four young gila monster skins. Once you have the necessary components combine them in your Curing Kit with this Tattered Leggings Pattern.");
			e.other:SummonCursorItem(19560); -- Item: Tattered Pant Pattern
		elseif(e.message:findi("rage sorcerer robe")) then
			e.self:Say("To craft a Rage Sorcerer Robe you will require three [silk thread], gila monster bile, two gila monster skins, and a desert tarantula hairs. Once you have the necessary components combine them in your Curing Kit with this Tattered Robe Pattern.");
			e.other:SummonCursorItem(11395); -- Item: Tattered Robe Pattern
		elseif(e.message:findi("staff of dismal rage")) then
			e.self:Say("The Dismal Rage has many enemies still here in Freeport that would uncover us and see us destroyed. Lately a wizard of the Arcane Scientists, Yovik Splegle, has been asking questions about Opal Darkbriar. Find this inquisitive wizard and silence him for good. When you have completed the task return to me with the wizards head.");
		end
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 19935})) then
		e.self:Say("Poor, poor Yovik Splegle. Haha! Excellent work, " .. e.other:GetCleanName() .. ". Quickly, fetch me a giant rattlesnake skin and a giant leaf scarab eye along with your Rough Hewn Dismal Staff and I will construct you the Staff of Dismal Rage before your very eyes.");
		e.other:Faction(e.self,271,10,0); -- Faction: Dismal Rage
		e.other:Faction(e.self,281,-1,0); -- Faction: Knights of Truth
		e.other:Faction(e.self,296,2,0); -- Faction: Opal Dark Briar
		e.other:QuestReward(e.self,0,0,0,0,19924); -- Item: Rough Hewn Dismal Staff
	elseif(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 19924,item2 = 19852,item3 = 19936})) then
		e.other:Faction(e.self,271,10,0); -- Faction: Dismal Rage
		e.other:Faction(e.self,281,-1,0); -- Faction: Knights of Truth
		e.other:Faction(e.self,296,2,0); -- Faction: Opal Dark Briar
		e.other:QuestReward(e.self,0,0,0,0,19941,250); -- Item: Staff of Dismal Rage
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
