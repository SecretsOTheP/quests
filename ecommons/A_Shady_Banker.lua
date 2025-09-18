function event_say(e)
	if(e.message:findi("its all ogre now") and e.other:Admin() > 0) then
		local entity_list = eq.get_entity_list()
		local clients = entity_list:GetClientList()

		if clients ~= nil then
			for client in clients.entries do
				client:SetRace(10);
				--client:WearChange(1, 11, 4278255398);
				--client:SetRace(47);
				--client:SpellFinished(3185, client);
				--client:WearChange(1, 0, 4278255398);
			end
		end
	elseif(e.message:findi("gettin froaky with it") and e.other:Admin() > 0) then
		local entity_list = eq.get_entity_list()

		-- Iterate through all clients in the entity list
		local clients = entity_list:GetClientList()
		if clients ~= nil then
			for client in clients.entries do
				-- Cast the spell on the client
				client:SetRace(26);
				--client:WearChange(7, 250, 0);
				--client:WearChange(8, 250, 0);
			end
		end
	end
end
