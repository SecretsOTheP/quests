local function can_control(e)
	if (eq.get_rule("Quarm:EnableGuildInstanceRespawnControl") ~= "true") then
		e.other:Message(0,"The Timekeeper of Druzzil Ro tells you, 'Hmm. No, no... the temporal weave is quite stubborn at the moment. Best not tug at it.");
		return false;
	end

	if (e.other:GuildID() < 2) then
		e.other:Message(0,"The Timekeeper of Druzzil Ro tells you, 'Ah, but you have no guild-bound realities for me to meddle with! What exactly would you have me alter?");
		return false;
	end

	if (e.other:GuildRank() < 1) then
		e.other:Message(0,"The Timekeeper of Druzzil Ro tells you, 'Temporal meddling on this scale requires a bit of authority. Bring me one of your guild's leaders or officers.");
		return false;
	end

	return true;
end

function event_say(e)
	if (e.message:findi("hail")) then
		if (not can_control(e)) then
			return;
		end

		if (e.other:GetGuildInstanceRespawnsEnabled()) then
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'Your guild's thread moves at its natural pace. In the Planes beyond Tranquility, you may enter your own Planar Thread without gathering your companions. But outsiders have no place within its weave. Their presence could fracture the thread, with consequences reaching far beyond these Planes. I cannot allow them to join you. If you wish to bring allies, I can [slow down] the timeline. You must then gather your companions under a worthy leader, and fallen creatures will take far longer to return. Passage into each Plane must still be earned, however. And the Plane of Time follows laws that even I dare not disturb."
			);
		else
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'Time moves slowly within your guild's Planar Thread. You must gather your companions under a worthy leader to enter, and allies from beyond your guild may walk beside you. I can [restore] its natural rhythm, allowing your guild's members to venture forth without gathering their companions. But outsiders have no place within that restored Thread. Their presence could tear its fragile weave, with consequences reaching far beyond these Planes. I must send any who remain to safety before that can happen. Passage into each Plane must still be earned, however. And the Plane of Time follows laws that even I dare not disturb."
			);

		end

	elseif (e.message:findi("slow down")) then
		if (not can_control(e)) then
			return;
		end

		if (e.other:SetGuildInstanceRespawnsEnabled(false)) then
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'There we are... just a gentle pull on the thread. There... steady now. Time moves more slowly within your guild's Planar Thread, and creatures that fall from this point forward will take far longer to return. Its weave can now bear the presence of your allies. Gather your companions under a worthy leader, and you may venture forth together."
			);
		else
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'Easy now! The thread is still settling from the last adjustment. Return when the temporal weave has had time to rest."
			);
		end

	elseif (e.message:findi("restore")) then
		if (not can_control(e)) then
			return;
		end

		if (e.other:SetGuildInstanceRespawnsEnabled(true)) then
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'And... released! The temporal thread settles back into its proper rhythm. Creatures that fall from this point forward will once again return as they normally would. In the Planes beyond Tranquility, your guild may now walk its own Planar Thread without gathering companions. Those who do not belong to it must leave before their presence tears its fragile weave. I shall send them to safety."
			);
		else
			e.other:Message(0,
				"The Timekeeper of Druzzil Ro tells you, 'Easy now! The thread is still settling from the last adjustment. Return when the temporal weave has had time to rest."
			);
		end
	end
end