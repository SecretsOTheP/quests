function event_spawn(e)
	eq.set_timer("ww",3600000);
end

function event_timer(e)
	eq.unique_spawn(68340,0,0,1376,2943,53.5,110); -- NPC: Giant Werewolf -- Halloween Event
	eq.zone_emote(15,"a loud roar is heard in the distance, everything goes eerily silent...");
	eq.set_sky(5);
end

function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Beware, traveller!! There has been increased sightings of lycanthropes in this area. This time of year, the sky glows flame-orange and the [beasts] become more active. We've also heard reports of a [planar disturbance] that is causing lycanthropes to emerge in higher than usual quantities.");
	elseif(e.message:findi("beast")) then
		e.self:Say("They are known to attack almost anything they see, I've even heard [reports] of a single werewolf wiping out an entire bandit camp!");
	elseif(e.message:findi("report")) then
		e.self:Say("I am a scout sent by the renowned werewolf hunting clan known as The Fangbreakers. We're testing a new [poison] that contains strong acids that severely weakens and kills werewolves.");
	elseif(e.message:findi("poison")) then
		e.self:Say("I tracked down a fearsome one on my way here and shot it with a poison-tipped arrow. Because of the size of the beast, I'm afraid it wasn't enough to kill it. It [escaped].");
	elseif(e.message:findi("escape")) then
		e.self:Say("If you see it lumbering around, please approach with caution! If it has already died, return to me with a blood sample so that we may analyze it to improve our concoction. I will also use the blood to imbue one of our staves that you can keep as a reward. If, someday, we are to consider you an ally, please talk to me for a [reward].");
	elseif(e.message:findi("planar disturbance")) then
		e.self:Say("We've seen increased activities by the [Bloodsabers] of Qeynos around the same time this all began. Rumor has it that extraplanar entities are leaking out of these planar pockets. If you're feeling brave, I would recommend investigating. With enough blood, your efforts will be rewarded. Strong creatures are rumored to lurk within. Just as we have with the werewolves, I will also use the blood to imbue one of our staves that you can keep as a reward.");
	elseif(e.message:findi("bloodsabers")) then
		e.self:Say("Normally, a few necromancers aren't much and we're able to dispatch of them. However, those we've seen were acting erratically, almost worshipping a book on a pedestal, chanting praise for both the God of Disease... and, strangely, for the God of Magic, Druzzil Ro. We sent a few scouts into the anomaly looking for the worshippers, and they haven't returned, either.");
	elseif(e.message:findi("reward") and e.other:GetFactionValue(e.self) >= 1900) then
		e.self:Say("Praise Tunare! I am so glad you were able to help us repel the threats from the Plaguebringer and their minions. We obtained this bridle from a Paladin suffering an ailment whom was chanting strangely about a person named Marnek. We aren't sure if it's cursed, but it is yours to have. Something tells me this bridle is tied directly to the Planar excursion, and won't last long.");
		e.other:SummonCursorItem(31492); -- Item: Ghostly Bridle
	elseif(e.message:findi("reward") and e.other:GetFactionValue(e.self) < 1900) then
		e.self:Say("While we admire your efforts, you aren't someone we consider an ally yet. Please contribute more to the research.");
	end
end

function event_trade(e)
	local item_lib =require("items");
	
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 2662})) then -- Arterial Blood
		e.self:Emote("holds up a staff and applies the blood to the top of the weapon, turning it dark red. 'Thank you! I hope it wasn't too much trouble to finish off. This weapon should prove most effective against other lycanthropes and magical creatures that you may run across. Good luck!");
		e.other:QuestReward(e.self,0,0,0,0,6048,5000); -- Item: Darkwood Staff
		e.other:Faction(e.self,20000,50,0); -- Faction: Oakwynd Twins
	end
	item_lib.return_items(e.self, e.other, e.trade)
end