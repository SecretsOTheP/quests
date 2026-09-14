local function can_control(e)
	if (eq.get_rule("Quarm:EnableGuildInstanceRespawnControl") ~= "true") then
		e.self:Say("Hmm. No, no... the temporal weave is quite stubborn at the moment. Best not tug at it.");
		return false;
	end
	if (e.other:GuildID() < 2) then
		e.self:Say("Ah, but you have no guild-bound realities for me to meddle with! What exactly would you have me alter?");
		return false;
	end
	if (e.other:GuildRank() < 1) then
		e.self:Say("Temporal meddling on this scale requires a bit of authority. Bring me one of your guild's leaders or officers.");
		return false;
	end
	return true;
end

function event_say(e)
	if (e.message:findi("hail")) then
		if (not can_control(e)) then return; end
		local state = e.other:GetGuildInstanceRespawnsEnabled() and "moving along at its natural pace" or "drawn out into a much slower passage";
		e.self:Say("Ah! You can feel it too, can't you? Each of your guild's little realities is tied to the same temporal thread, and at present that thread is " .. state .. ". With a careful adjustment, I can [slow down] the timeline or [restore] the timeline to normal.");
	elseif (e.message:findi("slow down")) then
		if (can_control(e) and e.other:SetGuildInstanceRespawnsEnabled(false)) then
			e.self:Say("There we are... just a gentle pull on the thread. Time will now linger across your guild's instances, and creatures that fall from this point forward will take far longer to return.");
		end
	elseif (e.message:findi("restore")) then
		if (can_control(e) and e.other:SetGuildInstanceRespawnsEnabled(true)) then
			e.self:Say("And... released! The temporal thread settles back into its proper rhythm. Creatures that fall from this point forward will once again return as they normally would.");
		end
	end
end
