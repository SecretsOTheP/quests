function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Emote("bows deeply. 'I have been expecting you, " .. e.other:GetCleanName() .. ". The waters have foretold your arrival. I am High Priest Omat Vastsea of the Triumvirate missionaries. Please feel free to enjoy the quiet solitude of this inn.'");
	elseif(e.message:findi("Triumvirate")) then
		e.self:Say("The Triumvirate of Water are: E'ci, the mistress of ice; Tarew Marr, the lord of water; and Povar, the formless master of vapor and mist. We Triumvirate missionaries are granted great divinatory powers and wisdom through our devotion to the Triumvirate and must defend the waters of Norrath from the ravages of the Tyrant of Fire, Fennin Ro.");
	elseif(e.message:findi("Fennin Ro")) then
		e.self:Say("The Tyrant of Fire, Fennin Ro, is the merciless lord of fire in all its forms. The rivalry between the tyrant and the Triumvirate is as old as the gods themselves and is an eternal battle. We witness the struggle every moment of our lives as the Oasis of Marr succumbs to the heat of the surrounding desert and is replenished by the swelling of the Lifire River. That fragile balance between the elements must be maintained but the Plasmatic Priesthood threatens that balance.");
	elseif(e.message:findi("plasmatic priesthood")) then
		e.self:Say("The Plasmatic Priesthood are worshipers of the Tyrant of Fire, but they have been driven mad by their fanaticism and have forgotten the importance of the balance. In their madness they would set the whole world aflame, leaving nothing but lifeless ash.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 28047},0)) then --Ornate Sea Shell
		e.self:Say("So, you are a friend of Natasha's? That is good to see. She is a very wise and gifted woman. The Riptide goblins have adopted a new king but are still in a vulnerable state until his subjects accept his rule. The Plasmatic Priesthood is aware of the weakened state of the Riptides and has convinced the Fire Peak goblins to strike against them. Although I do not agree with the mannerisms or actions of any goblin clan, such a war would be detrimental to all who are caught in its path. Lord Gimblox of the Fire Peak clan has been meeting with a member of the Plasmatic Priesthood in the Temple of Solusek Ro. Locate the Plasmatic Priest, hand him this statue to hinder his powers, then eliminate him and bring me his robe.");
		e.other:QuestReward(e.self,0,0,0,0,28051); --Coral Statue of Tarew
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 1299},0)) then --Blood Soaked Plasmatic Priest Robe
		e.self:Say("You have proven yourself to be one who is willing to take responsibility for his own actions. Such a trait is desired by all deities to be present in their faithful. I pray that you had the wisdom to slay Lord Gimblox as well as the Plasmatic Priest in order to prevent further advancement in the incursion against the Riptides. Priestess Natasha awaits inside the inn for Lord Gimblox's ring, make haste for she is a busy women and will depart soon.");
		e.other:QuestReward(e.self,0,0,0,0,28049,100000); --Orb of Frozen Water
		eq.unique_spawn(96080,0,0,-2198,-11601,76,192); --Natasha Whitewater
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 18170, item2 = 28017})) then --A Singed Scrol (overkind bathezid), Sceptre of Ixiblat Ferl
		e.self:Say("I commend you on your success over the fire elemental lord, Ixiblat Fer. The fact that the Plasmatic Priesthood has mustered up the power to summon such a being means drastic actions must be taken to stop the fanatic cult of Fennin Ro. I wonder what kind of favor Zordak Ragefire performed for the sarnak summoners to convince them to assist in the ritual that brought forth Ixiblat Fer. The dragon Iksar hybrid abominations are not beings who ally with others easily. All I have seen in my divinations of the High Plasmatic Priest are riddles, and signs that the one who slays him may be awarded an Orb of the Triumvirate. If you are the one whom my visions foretell, then seek Zordak Ragefire and bring me his heart.");
		e.other:QuestReward(e.self,0,0,0,0,28048,100000); --Orb of Clear Water
		eq.unique_spawn(96080,0,0,-2198,-11601,76,192); --Natasha Whitewater
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 28019})) then--Zordak Ragefire's Heart (combined after the death of zordakalicus in SF)
		e.self:Say("I see now that Zordak Ragefire and the exiled elder dragon Zordakalicus were the same being. That explains how he resisted our attempts to divine his affairs and past. Each of these orbs I have granted you represents one of the Triumvirate. Jhassad Oceanson awaits on the shore below to perform the ritual that will merge the orbs into a single Orb of the Triumvirate and summon an avatar from the Plane of Water. Present the Orb of the Triumvirate to the Avatar of Water when it arrives and allow your destiny to be unraveled.");
		e.other:QuestReward(e.self,0,0,0,0,28050,100000); --Orb of Vapor
		eq.unique_spawn(96074,0,0,-1781,-11959,14.3,1); --Jhassad Oceanson
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 28050})) then -- Orb of Vapor (to respawn Jhassad Oceanson in case of depop)
		e.self:Say("Jhassad Oceanson awaits on the shore below to perform the ritual that will merge the orbs into a single Orb of the Triumvirate and summon an avatar from the Plane of Water. Present the Orb of the Triumvirate to the Avatar of Water when it arrives and allow your destiny to be unraveled.");
		e.other:QuestReward(e.self,0,0,0,0,28050); --Orb of Vapor
		eq.unique_spawn(96074,0,0,-1781,-11959,14.3,1); --Jhassad Oceanson
	elseif(item_lib.check_turn_in(e.self, e.trade, {item1 = 28023})) then -- Orb of the Triumvirate (to respawn Avatar of Water in case of depop)	
		e.self:Say("The Avatar of Water approaches. You must hand him the Orb of the Triumvirate and it will be decided if it is your destiny to wield the Nem Ankh Sprinkler.");
		e.other:QuestReward(e.self,0,0,0,0,28023); -- Orb of the Triumvirate
		eq.unique_spawn(96086,21,0,-1886,-11661,1,192); --Avatar of Water
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd and manual edits by Speedz
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
