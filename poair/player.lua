local authorizations = {};
local AUTHORIZATION_SECONDS = 300;

local function GetAuthorizationKey(client)
	local raid = client:GetRaid();
	if ( raid and raid.valid ) then
		return "raid:" .. raid:GetID();
	end

	local group = client:GetGroup();
	if ( group and group:GroupCount() > 0 ) then
		return "group:" .. group:GetID();
	end

	return nil;
end

local function Authorize(client)
	local key = GetAuthorizationKey(client);
	if ( key ) then
		authorizations[key] = eq.clock() + AUTHORIZATION_SECONDS;
	end
end

local function HasAuthorization(client)
	local key = GetAuthorizationKey(client);
	return key and authorizations[key] and eq.clock() < authorizations[key];
end

function MoveGroup(zone, client, dist, x, y, z, h)
	local group = client:GetGroup();
	local raid = client:GetRaid();

	if ( group and group:GroupCount() > 0 ) then
		for i = 0, 5 do
			local member = group:GetMember(i):CastToClient();

			if ( member.valid ) then
				if ( member:CalculateDistance(client:GetX(), client:GetY(), client:GetZ()) < dist ) then
					member:MovePC(zone, x, y, z, h*2);
					if ( member:GetPet().valid ) then
						if ( member:GetPet():Charmed() ) then
							member:GetPet():BuffFadeByEffect(22); -- charm
						else
							member:GetPet():GMMove(x, y, z, 0);
						end
					end
					eq.get_entity_list():RemoveFromHateLists(member);
				end
			end
		end
		
	elseif ( raid and raid.valid ) then
		local raidGroupID = raid:GetGroup(client:GetName());
		local member;
		for i = 0, 71 do
			member = raid:GetMember(i);
			
			if ( member and member.valid and raid:GetGroup(member:GetName()) == raidGroupID ) then
			
				if ( member:CalculateDistance(client:GetX(), client:GetY(), client:GetZ()) < dist ) then
					member:MovePC(zone, x, y, z, h*2);
					if ( member:GetPet().valid ) then
						if ( member:GetPet():Charmed() ) then
							member:GetPet():BuffFadeByEffect(22); -- charm
						else
							member:GetPet():GMMove(x, y, z, 0);
						end
					end
					eq.get_entity_list():RemoveFromHateLists(member);
				end
			end
		end		
	else
		client:MovePC(zone, x, y, z, h*2);
		
		if ( client:GetPet().valid ) then
			if ( client:GetPet():Charmed() ) then
				client:GetPet():BuffFadeByEffect(22); -- charm
			else
				client:GetPet():GMMove(x, y, z, 0);
			end
		end
		eq.get_entity_list():RemoveFromHateLists(client);
	end
end

function event_click_door(e)
	local door_id = e.door:GetDoorID();

	if ( door_id == 1 ) then -- Xegony rainbow
		local has_key = e.self:GetItemIDAt(0) == 28638; -- Wind Etched Key

		if ( has_key ) then
			Authorize(e.self);
		end

		if ( has_key or HasAuthorization(e.self) or e.self:GetGM() ) then
			e.self:MovePC(215, -617, 5, 1450, 64 * 2);

			if ( e.self:GetPet().valid ) then
				if ( e.self:GetPet():Charmed() ) then
					e.self:GetPet():BuffFadeByEffect(22); -- charm
				else
					e.self:GetPet():GMMove(-617, 5, 1450, 0);
				end
			end

			eq.get_entity_list():RemoveFromHateLists(e.self);
		end
	end	
end
