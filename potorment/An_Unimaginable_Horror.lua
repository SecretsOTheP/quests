function event_death(e)
	eq.depop_with_timer(207028); -- Baraguj_Szuul
	eq.unique_spawn(207319, 0, 0, 5, -1041, -26.25, 0); -- #Baraguj_Szuul
	eq.spawn2(207321, 0, 0, -805, 962, -1644, 0); -- An_unseen_entity
end

function event_death_complete(e)
	-- Baraguj's stomach is a separate pocket below the main zone. Include its
	-- upper rooms; the Keeper's area and corpses elsewhere in Torment stay put.
	-- Keep the list owner alive while iterating its borrowed entries.
	local corpseList = eq.get_entity_list():GetCorpseList();
	if ( corpseList ) then
		for corpse in corpseList.entries do
			if ( corpse.valid and corpse:IsPlayerCorpse()
				and corpse:GetX() >= -1300 and corpse:GetX() <= -550
				and corpse:GetY() >= 800 and corpse:GetY() <= 1120
				and corpse:GetZ() < -600
			) then
				-- Torment's graveyard is at zone-in. This preserves the current
				-- guild instance, including guests, or open world as appropriate.
				corpse:MoveToInstanceGraveyard();
			end
		end
	end
end
