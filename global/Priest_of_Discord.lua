function event_say(e)
	local is_special_flag_response = false;
	local newgameplus = require("newgameplus");
	local titles = require("title_manager");

	if(e.message:findi("name") or e.message:findi("title")) then
		if (titles.HandleName(e)) then
			return;
		end
	end
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings, " .. e.other:GetCleanName() .. ". Are you a child of Order?  If you have come seeking the path of Discord. I require only that you give me your [Tome of Order and Discord] and I shall show you the way. Only then will you be freed from Order's confining restraints. Or perhaps you wish to [return] to Order.");
		e.other:Message(0, "Should you desire to reshape yourself and transcend the bindings of mortal identity, speak of the [king] or [queen] who lies within. For within Discord, all forms may be remade, and the self can be [reborn].");
		e.other:Message(0, "If you are drawn to the allure of the uncharted, inquire about the secret [challenges] and their hidden [rites]. These are not mere adventures, but tests of your true mettle. Earn your reknown, and you will be known by many [names] across the land.");
	elseif(e.message:findi("tome")) then
		e.self:Say("The Tome of Order and Discord was penned by the seventh member of the Tribunal and has become the key to a life of Discord, in spite of the author's pitiful warnings.  Do you not have one, child of Order?  Would you [like to read] it?");
	elseif(e.message:findi("read")) then
		e.self:Say("Very well. Here you go. Simply return it to me to be released from the chains of Order.");
		e.other:SetPVP(false);
		e.other:SummonCursorItem(18700); -- Item: Tome of Order and Discord
	elseif(e.message:findi("rites")) then 
		if(e.other:IsSelfFound() == 1 or e.other:IsSoloOnly() == 1) then
			e.self:Say("The path to greatness is paved with the rarest of elements. Find those who deal in silver and gold. Secure a piece of such wealth and seek guidance on how to imbue it with arcane energy.");
		else
			e.self:Say("Ah, you tread the common path, where certain secrets remain veiled.");
		end
	elseif (e.message:findi("king")) then
		e.self:Say("Bring me a Vial of Swirling Smoke and this token, and a King you shall be.");
		e.other:Message(15, "Completing this quest will permanently change your gender.");
		e.other:SummonCursorItem(13992); -- 'King'
		return;
		
	elseif (e.message:findi("return")) then
		e.other:SetPVP(false);
		e.self:Say("Very well then, child of Discord. Return to the ways of Order.");
		return;
		
	elseif (e.message:findi("queen")) then
		e.self:Say("Bring me a Vial of Swirling Smoke and this token, and a Queen you shall be.");
		e.other:Message(15, "Completing this quest will permanently change your gender.");
		e.other:SummonCursorItem(13993); -- 'Queen'
		return;

	elseif(e.message:findi("reborn")) then
		newgameplus.HandleReborn(e);
		return;
	end
	if(e.other:GetLevel() == 1) then
		if(e.message:findi("challenges")) then
			-- TODO: Would like to add more flavor here, potentially splitting this into multiple descriptions, one for each challenge mode
			e.self:Say("I can offer you flags for the [solo], [self found], and [hardcore] challenges. You must tell me all of the challenges you wish to embark on in the same sentence. In the [solo] challenge, all external interactions become unavailable - as well as external buffs. In the [self found] challenge you are prevented from interacting with anyone else except others with the same flags of similar level, though you are additionally prevented from trading. There is also the [hardcore] challenge, which will result in your mortal coil being emptied - permanently - on death. You may include all three of these challenges together.");
			e.other:Message(13, "By accepting any of these options, you will immediately be completely reset and sent back to your starting location. This will be irreversible.");
			return;
		end

		if(e.message:findi("solo")) then
			e.self:Say("Very well. You will now play solo, without any friends.");
			e.other:SetSoloOnly(1);
			e.other:SetSelfFound(1);
			is_special_flag_response = true;
		elseif(e.other:IsSoloOnly() == 0 and e.message:findi("self found")) then
			if (e.message:findi("self found classic")) then
				e.other:SetSelfFound(1);
				is_special_flag_response = true;
				e.self:Say("Very well. You will now play through the game using the self found classic ruleset.");
			elseif (e.message:findi("self found flex")) then
				e.other:SetSelfFound(2);
				is_special_flag_response = true;
				e.self:Say("Very well. You will now play through the game using the self found flex ruleset.");
			else
				e.other:Message(15, "You must choose [self found classic] or [self found flex]. Classic is the original ruleset. Flex is the ruleset that allows grouping with normal players.");
				return;
			end
		end
		if(e.message:findi("hardcore")) then
			e.self:Say("Very well. You will now have your character permanently unavailable upon your next death, along with all of their items.");
			e.other:SetHardcore(1);
			is_special_flag_response = true;
		end
				
		if(is_special_flag_response) then
			e.other:ClearPlayerInfoAndGrantStartingItems();
			return;
		end

	elseif (e.other:GetClass() >= 1) then -- Allows non-null players to downgrade challenge flags

		local confirmed = e.message:findi("correct");

		if (e.other:IsSoloOnly() > 0 and e.message:findi("remove solo")) then
			if (confirmed) then
				e.other:SetSoloOnly(0);
				e.other:SetSelfFound(1);
				e.other:Message(15, "Your 'Solo' status has been permanently downgraded to 'Self Found Classic'.");
			else
				e.other:Message(15, "Are you sure? This will permanently downgrade your 'Solo' challenge to 'Self Found Classic'.");
				e.other:Message(15, "Repeat your message with [correct] to continue.");
			end
			return;
		end

		if (e.other:IsSoloOnly() == 0 and e.other:IsSelfFound() == 1 and e.message:findi("remove self found classic")) then
			if (confirmed) then
				e.other:SetSelfFound(2);
				e.other:Message(15, "Your 'Self Found Classic' challenge status has been downgraded to 'Self Found Flex'. You may now group with normal players.");
			else
				e.other:Message(15, "Are you sure? This will permanently downgrade your 'Self Found Classic' challenge to 'Self Found Flex'.");
				e.other:Message(15, "Repeat your message with [correct] to continue.");
			end
			return;
		end

		if (e.other:IsSoloOnly() == 0 and e.other:IsSelfFound() == 2 and e.message:findi("remove self found flex")) then
			if (confirmed) then
				e.other:SetSelfFound(0);
				e.other:Message(15, "Your 'Self Found Flex' challenge has been removed.");
			else
				e.other:Message(15, "Are you sure? This will permanently remove your 'Self Found Flex' status and return your character to normal.");
				e.other:Message(15, "Repeat your message with [correct] to continue.");
			end
			return;
		end

		if (e.other:IsHardcore() == 1 and e.message:findi("remove hardcore")) then
			if (confirmed) then
				e.other:SetHardcore(0);
				e.other:Message(15, "Your 'Hardcore' challenge has been removed.");
			else
				e.other:Message(15, "Are you sure? This will permanently remove your 'Hardcore' status.");
				e.other:Message(15, "Repeat your message with [correct] to continue.");
			end
			return;
		end
	end

	if (e.message:findi("challenge") and e.other:GetLevel() > 1) then
		e.self:Say("Though I can't offer new challenges to a seasoned adventurer, perhaps being [reborn] would interest you... unless you'd like trade in your gender to become a [king] or [queen].");
	end

	if (e.message:findi("challenge") and e.other:GetClass() >= 1) then
		if (e.other:IsHardcore() == 1) then
			e.other:Message(15, "You may [remove hardcore] to change your character to the Softcore ruleset.");
		end
		if (e.other:IsSoloOnly() == 1) then
			e.other:Message(15, "You may [remove solo] to change your character to Self Found Classic ruleset.");
		elseif (e.other:IsSelfFound() == 1) then
			e.other:Message(15, "You may [remove self found classic] to change your character to Self Found Flex ruleset.");
		elseif (e.other:IsSelfFound() == 2) then
			e.other:Message(15, "You may [remove self found flex] to change your character to the Normal ruleset.");
		end
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 18700})) then
		e.self:Say("I see you wish to join us in Discord! Welcome! By turning your back on the protection of Order you are now open to many more opportunities for glory and power. Remember that you can now be harmed by those who have also heard the call of Discord.");
		e.other:SetPVP(true);
		e.other:Ding();
	elseif (item_lib.check_turn_in_nomq(e.self, e.trade, {item1 = 14402, item2 = 13992})) then -- Vial of Swirling Smoke, King
		e.other:PermaGender(0);
	elseif (item_lib.check_turn_in_nomq(e.self, e.trade, {item1 = 14402, item2 = 13993})) then -- Vial of Swirling Smoke, Queen
		e.other:PermaGender(1);
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd and manual edits by Speedz
-- Solo, SF and Hardcore options added by Secrets
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
