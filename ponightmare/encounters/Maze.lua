local GOVERNOR_TYPE = 204458; -- Maze_Checker
local THELIN_OUTSIDE_TYPE = 204070; -- Thelin_Poxbourne
local THELIN_INSIDE_TYPE = 204486; -- Thelin_Poxbourne
local TERRIS_TYPE = 204483; -- Terris_Thule
local NIGHTMARISH_TYPE = 204487; -- nightmarish_construct

local BLOODTHIRSTY_TYPE = 204463; -- a_bloodthirsty_raven
local ABHORRENT_TYPE = 204476; -- an_abhorrent_nightstalker
local SINISTER_TYPE = 204472; -- a_sinister_nightstalker
local THULIAN_TYPE = 204473; -- a_thulian_nightstalker
local AGGRESSOR_TYPE = 204477; -- an_aggressor_arachnid
local CONSTRUCT_TYPE = 204464; -- a_construct_of_nightmares
local MOB_TYPES = { BLOODTHIRSTY_TYPE, ABHORRENT_TYPE, SINISTER_TYPE, THULIAN_TYPE, AGGRESSOR_TYPE, CONSTRUCT_TYPE };

local THELIN_SPAWNIDS = { 346002, 346001, 346000 }; -- note: this order is important; starts top to bottom
local BOUNDARIES = {
	{ t = 6550, l = -4000, r = -5100, b = 5550 },
	{ t = 5550, l = -4000, r = -5100, b = 4550 },
	{ t = 4550, l = -4000, r = -5100, b = 3500 }
};
local PORT_COORDS = {
	{ x = -4466, y = 5642, z = 5 },		-- Maze Sending1 1159
	{ x = -4466, y = 4642, z = 5 },		-- Maze Sending2 1160
	{ x = -4466, y = 3642, z = 5 }		-- Maze Sending3 1161
};

--[[
		States:
			0 = Maze available for use
			1 = A group ported up but didn't start it
			2 = Thelin is wandering
			3 = Boss spawned; Thelin accepting dagger blade shard from boss
			4 = Thelin and Terris dialog complete; hailing Thelin ports you out
			5 = Waiting for cleanup to allow reuse
]]
local instance = {
	{ rid = 0, ports = 0, state = 0, wait_checks = 0, wait_until = 0, members = {}, ids = {}, terris = nil },
	{ rid = 0, ports = 0, state = 0, wait_checks = 0, wait_until = 0, members = {}, ids = {}, terris = nil },
	{ rid = 0, ports = 0, state = 0, wait_checks = 0, wait_until = 0, members = {}, ids = {}, terris = nil }
};


local routingLoaded=false;
local ARRIVAL_GRACE=60;
local function Now() return os.time();end
local function InRoom(client,i)
    return client and client.valid and client:GetY()<BOUNDARIES[i].t and client:GetY()>BOUNDARIES[i].b and
        client:GetX()<BOUNDARIES[i].l and client:GetX()>BOUNDARIES[i].r;
end
local function Character(client) return client:CharacterID();end
local function Seats(i)
    local n=0;for _ in pairs(instance[i].members) do n=n+1;end;instance[i].ports=n;return n;
end
local function MazeLog(i,kind,message)
    local room=instance[i];
    local text=string.format("[Maze guild=%s room=%d raid=%d state=%d seats=%d] [%s] %s",
        tostring(eq.get_zone_guild_id()),i,room.rid,room.state,Seats(i),kind,message);
    eq.debug(text);
    for client in eq.get_entity_list():GetClientList().entries do
        if client.valid and client:GetGM() then client:Message(15,text);end
    end
end
local function MazeRP(i,message)
    for client in eq.get_entity_list():GetClientList().entries do
        if client.valid and (instance[i].members[Character(client)] or (client:GetGM() and InRoom(client,i))) then
            client:Message(13,message);
        end
    end
end
local DAGGER_RP={
    [26]="Thelin recovers the dagger hilt. Terris Thule's laughter drifts through the hedges as her servants close in around you.",
    [46]="A shard of the dagger glints in Thelin's trembling hands. The shadows stir, angered by another piece slipping from Terris's grasp.",
    [57]="Thelin lifts the upper half of the broken blade. A cold whisper passes through the maze: \"You will never escape my dream.\"",
    [71]="Thelin finds the dagger's handle. The hedges writhe as fresh horrors gather to tear his hope away.",
    [88]="Thelin raises a small gem from the tangled roots. Its faint light draws a furious cry from the darkness beyond the hedges.",
    [99]="The dagger's final tip rests in Thelin's hands. His nightmare shudders as Terris summons the last of her guardians."
};
local function SaveRouting(i,npc)
    local room=instance[i];
    if not npc or not npc.valid or npc:GetNPCTypeID()~=THELIN_INSIDE_TYPE or npc:GetSpawnPointID()~=THELIN_SPAWNIDS[i] then npc=GetThelinInTrial(i);end
    if not npc or not npc.valid then return;end
    local entries={};for id,t in pairs(room.members) do
        entries[#entries+1]=string.format("%d:%d:%d",id,t.pending_until or 0,t.arrived and 1 or 0);
    end
    table.sort(entries);
    local ids={};for _,id in ipairs(room.ids) do ids[#ids+1]=tostring(id);end
    npc:SetEntityVariable("maze_routing_v1",table.concat({"v1",room.rid,room.state,room.wait_until or 0,
        table.concat(entries,","),table.concat(ids,","),room.terris and room.terris:GetID() or 0},"|"));
end
local function Pending(i)
    for _,t in pairs(instance[i].members) do if not t.arrived and (t.pending_until or 0)>Now() then return true;end end
    return false;
end
local function Occupied(i)
    for client in eq.get_entity_list():GetClientList().entries do
        -- An explicitly admitted GM can test a maze alone; observers do not reserve it.
        if InRoom(client,i) and (not client:GetGM() or instance[i].members[Character(client)]) then return true;end
    end
    return false;
end
local function Reconcile(i)
    local room=instance[i];local clients={};local changed=false;
    for client in eq.get_entity_list():GetClientList().entries do if client.valid then clients[Character(client)]=client;end end
    for id,t in pairs(room.members) do
        if InRoom(clients[id],i) then
            if not t.arrived or t.pending_until~=0 then t.arrived=true;t.pending_until=0;changed=true;end
        elseif not t.arrived and (t.pending_until or 0)<=Now() then room.members[id]=nil;changed=true;
        elseif t.arrived and room.state==1 then room.members[id]=nil;changed=true;end
    end
    Seats(i);if changed then SaveRouting(i);end
end
local function EnsureRouting()
    if routingLoaded then return;end
    routingLoaded=true;
    for i=1,3 do
        local npc=GetThelinInTrial(i);
        if npc then
            local text=npc:GetEntityVariable("maze_routing_v1");local fields={};
            for value in ((text or "").."|"):gmatch("(.-)|") do fields[#fields+1]=value;end
            if #fields==7 and fields[1]=="v1" and tonumber(fields[2]) and tonumber(fields[3]) and
                tonumber(fields[3])>=0 and tonumber(fields[3])<=5 and tonumber(fields[4]) then
                local room=instance[i];room.rid=tonumber(fields[2]);room.state=tonumber(fields[3]);room.wait_until=tonumber(fields[4]);room.members={};room.ids={};
                for id,untilTime,arrived in fields[5]:gmatch("(%d+):(%d+):([01])") do
                    room.members[tonumber(id)]={pending_until=tonumber(untilTime),arrived=arrived=="1"};
                end
                for id in fields[6]:gmatch("%d+") do
                    local mob=eq.get_entity_list():GetNPCByID(tonumber(id));
                    if mob and mob.valid and mob:GetNPCTypeID()==NIGHTMARISH_TYPE and InRoom(mob,i) then room.ids[#room.ids+1]=tonumber(id);end
                end
                local terrisId=tonumber(fields[7]) or 0;
                if terrisId>0 then
                    local mob=eq.get_entity_list():GetNPCByID(terrisId);
                    if mob and mob.valid and mob:GetNPCTypeID()==TERRIS_TYPE and InRoom(mob,i) then room.terris=mob;end
                end
                Reconcile(i);MazeLog(i,"LOAD","Restored room ownership and unique character reservations from Thelin.");
            elseif ClientInTrial(i) then
                -- Legacy/unverified occupied rooms cannot be silently reassigned to new groups.
                local room=instance[i];room.state=5;room.members={};local owner=nil;
                for client in eq.get_entity_list():GetClientList().entries do
                    if InRoom(client,i) and not client:GetGM() then
                        local raid=client:GetRaid();local rid=raid and raid.valid and raid:GetID() or 0;
                        room.members[Character(client)]={pending_until=0,arrived=true};
                        if owner==nil then owner=rid;elseif owner~=rid then owner=0;end
                    end
                end
                room.rid=owner or 0;SaveRouting(i,npc);
                MazeLog(i,"WARN","Occupied maze has no verified routing history; retaining its occupants/raid and blocking new entry until it clears.");
            end
            if instance[i].state>0 then
                local governor=eq.get_entity_list():GetMobByNpcTypeID(GOVERNOR_TYPE);
                if governor and governor.valid then eq.set_timer("check",10000,governor);end
            end
        end
    end
end
local function Assignment(members)
    local selected=0;
    for _,member in ipairs(members) do
        local id=Character(member);
        for i=1,3 do
            if instance[i].members[id] then
                if selected>0 and selected~=i then return 0,"Your companions are already assigned to different dreams. Return to Thelin together before trying again.";end
                selected=i;
            end
        end
    end
    return selected;
end
local function Needed(i,members)
    local n=0;for _,m in ipairs(members) do if not instance[i].members[Character(m)] then n=n+1;end end;return n;
end
local function Deny(client,i,message)
    client:Message(13,"Thelin Poxbourne tells you, '"..message.."'");
    if i>0 then MazeLog(i,"DENY",client:GetName()..": "..message);end
end

function GetInstanceFromSpawnID(spawnId)
	local i;
	
	if ( THELIN_SPAWNIDS[1] == spawnId ) then
		i = 1;
	elseif ( THELIN_SPAWNIDS[2] == spawnId ) then
		i = 2;
	elseif ( THELIN_SPAWNIDS[3] == spawnId ) then
		i = 3;
	end
	return i;
end

function GetThelinInTrial(i)
        local npcList = eq.get_entity_list():GetNPCList();

        if ( npcList ) then
                for npc in npcList.entries do
                        if ( npc.valid and npc:GetID()~=0 and npc:GetHP()>0 and not npc:IsCorpse() and npc:GetNPCTypeID()==THELIN_INSIDE_TYPE and npc:GetSpawnPointID() == THELIN_SPAWNIDS[i] ) then
                                return npc;
                        end
                end
        end
        return nil;
end

function ClientInTrial(trialNum)
	local clientList = eq.get_entity_list():GetClientList();

	if ( clientList ) then
		for client in clientList.entries do
			if ( client.valid and client:GetY() < BOUNDARIES[trialNum].t
				and client:GetY() > BOUNDARIES[trialNum].b
				and client:GetX() < BOUNDARIES[trialNum].l
				and client:GetX() > BOUNDARIES[trialNum].r
			) then
				if ( not client:GetGM() ) then
					return true;
				end
			end
		end
	end
	return false;
end

function CheckRemoveFromTrial(trialNum, limit, zone, x, y, z, h)
	local clientList = eq.get_entity_list():GetClientList();
	local n = 0;

	if ( clientList ) then
		for client in clientList.entries do
			if ( client.valid and client:GetY() < BOUNDARIES[trialNum].t
				and client:GetY() > BOUNDARIES[trialNum].b
				and client:GetX() < BOUNDARIES[trialNum].l
				and client:GetX() > BOUNDARIES[trialNum].r
			) then
				if ( not client:GetGM() ) then
					n = n + 1;
					if ( n > limit ) then
						client:MovePC(zone, x, y, z, h*2);
						if ( client:GetPet().valid and not client:GetPet():Charmed() ) then
							client:GetPet():GMMove(x, y, z, 0);
						end
						if ( limit > 0 ) then
							eq.debug(client:GetName().." removed from trial because client limit of "..limit.." exceeded");
						end
						n = n - 1;
					end
				end
			end
		end
	end
end

function RemoveFromTrial(i, zone, x, y, z, h, message)
	local clientList = eq.get_entity_list():GetClientList();

	if ( clientList ) then
		for client in clientList.entries do
			if ( client.valid and not client:GetGM()
				and client:GetY() < BOUNDARIES[i].t
				and client:GetY() > BOUNDARIES[i].b
				and client:GetX() < BOUNDARIES[i].l
				and client:GetX() > BOUNDARIES[i].r
			) then
				if ( message ) then
					client:Message(0, message);
				end
				client:MovePC(zone, x, y, z, h*2);
				if ( client:GetPet().valid and not client:GetPet():Charmed() ) then
					client:GetPet():GMMove(x, y, z, 0);
				end
			end
		end
	end
end

function MoveFailedTrialCorpses(i)
	local liveZone = eq.get_zone_guild_id() == -1;
	local corpseList = eq.get_entity_list():GetCorpseList();
	if ( corpseList ) then
		for corpse in corpseList.entries do
			if ( corpse.valid and corpse:IsPlayerCorpse()
				and corpse:GetY() < BOUNDARIES[i].t
				and corpse:GetY() > BOUNDARIES[i].b
				and corpse:GetX() < BOUNDARIES[i].l
				and corpse:GetX() > BOUNDARIES[i].r
			) then
				if ( liveZone ) then
					corpse:MoveToGraveyard();
				else
					corpse:MoveToInstanceGraveyard();
				end
			end
		end
	end
end

-- Snapshot eligible members before moving the speaker: MovePC changes their position.
function GetMazeGroup(client, dist)
	local members,seen = {},{};
	local group = client:GetGroup();
	local raid = client:GetRaid();
	local x, y, z = client:GetX(), client:GetY(), client:GetZ();
	local function add(member)
		if ( member and member.valid and member:CalculateDistance(x, y, z) < dist ) then
            local id=Character(member);
            if id>0 and not seen[id] then seen[id]=true;table.insert(members,member);end
		end
	end
	if ( raid and raid.valid ) then
		local groupID = raid:GetGroup(client:GetName());
		-- Ungrouped raid members must not bring every other ungrouped member.
		if ( groupID < 0 or groupID >= 12 ) then
			add(client);
		else
			for i = 0, 71 do
				local member = raid:GetMember(i);
				if ( member and member.valid and raid:GetGroup(member:GetName()) == groupID ) then
					add(member);
				end
			end
		end
	elseif ( group and group.valid and group:GroupCount() > 0 ) then
		for i = 0, 5 do
			add(group:GetMember(i):CastToClient());
		end
	else
		add(client);
	end
	return members;
end

function MoveMazeGroup(members, zone, x, y, z, h)
	for _, member in ipairs(members) do
		member:MovePC(zone, x, y, z, h*2);
		local pet = member:GetPet();
		if ( pet.valid ) then
			if ( pet:Charmed() ) then
				pet:BuffFadeByEffect(22);
			else
				pet:GMMove(x, y, z, 0);
			end
		end
		eq.get_entity_list():RemoveFromHateLists(member);
	end
end

function GovernorTimerEvent(e)
    EnsureRouting();
    for i=1,3 do Reconcile(i);end
	
	if ( e.timer == "check" ) then
	
		-- check for rooms to reset
		for i = 1, 3 do
			if ( instance[i].state == 5 or instance[i].state == 1 ) then
				if ( not Occupied(i) and not Pending(i) ) then
					instance[i].state = 0;
					instance[i].rid = 0;
					instance[i].ports = 0;
					instance[i].wait_checks = 0;
                    instance[i].wait_until=0;instance[i].members={};
					instance[i].ids = {};
					if ( instance[i].terris ) then
						instance[i].terris:Depop();
					end
					instance[i].terris = nil;
                    SaveRouting(i);MazeLog(i,"READY","Maze cleared and available.");
				elseif ( instance[i].state == 1 ) then
					instance[i].wait_checks = instance[i].wait_checks + 1;

					if ( instance[i].wait_until>0 and Now()>=instance[i].wait_until ) then
                        MazeRP(i,"Terris Thule's laughter tears through the hedges. \"Too slow, mortals! His nightmare is mine!\" The dream begins to collapse around you.");
						MoveFailedTrialCorpses(i);
						RemoveFromTrial(i, 204, 1668, 282, 213, 255,
							"Terris Thule invades your thoughts. 'Fools! Did Thelin think to cheat our contract by bringing you here? This nightmare is his alone! Begone!'");
						instance[i].state = 5;
                        SaveRouting(i);MazeLog(i,"FAIL","Five-minute preparation deadline expired.");
					end
				end
			end
		end
		
		-- check for too many players in rooms
		for i = 1, 3 do
			if ( instance[i].state > 0 ) then
				CheckRemoveFromTrial(i, 24, 204, 1668, 282, 215, 0);
			end
		end		
		
		-- stop timer if all rooms are state 0
		local stopTimer = true;
		for i = 1, 3 do
			if ( instance[i].state > 0 ) then
				stopTimer = false;
			end
		end
		if ( stopTimer ) then
			eq.stop_timer(e.timer);
		end
		return;
	end
end

function ThelinWaypointEvent(e)
    EnsureRouting();
	local i = GetInstanceFromSpawnID(e.self:GetSpawnPointID());
	local offset = 1000 - (i * 1000);
	local nc;
    if DAGGER_RP[e.wp] then MazeRP(i,DAGGER_RP[e.wp]);MazeLog(i,"PIECE","Thelin reached dagger-piece waypoint "..e.wp..".");end
	
	if ( e.wp == 26 ) then
		e.self:Emote("kneels down and picks up a dagger hilt.");
		eq.spawn2(SINISTER_TYPE, 0, 0, -4725, 6249+offset, 5, 0);
		eq.spawn2(SINISTER_TYPE, 0, 0, -4726, 6244+offset, 5, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);

	elseif ( e.wp == 46 ) then
		e.self:Emote("slowly picks up a shard of a dagger blade.");
		eq.spawn2(ABHORRENT_TYPE, 0, 0, -4757, 6092+offset, 5, 0);
		eq.spawn2(BLOODTHIRSTY_TYPE, 0, 0, -4755, 6091+offset, 5, 0);
		eq.spawn2(BLOODTHIRSTY_TYPE, 0, 0, -4756, 6094+offset, 5, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);

	elseif ( e.wp == 57 ) then
		e.self:Emote("picks up a the top half of a dagger blade.");
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4923, 5735+offset, 5, 0);
		eq.spawn2(ABHORRENT_TYPE, 0, 0, -4921, 5735+offset, 5, 0);
		eq.spawn2(SINISTER_TYPE, 0, 0, -4924,5735+offset, 5, 0);
		eq.spawn2(THULIAN_TYPE, 0, 0, -4922, 5733+offset, 5, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);
		
	elseif ( e.wp == 71 ) then
		e.self:Emote("picks up a dagger handle with a small hole in it.");
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4144, 5620+offset, 5, 0);
		eq.spawn2(ABHORRENT_TYPE, 0, 0, -4142, 5620+offset, 5, 0);
		eq.spawn2(THULIAN_TYPE, 0, 0, -4143, 5625+offset, 5, 0);
		eq.spawn2(THULIAN_TYPE, 0, 0, -4140, 5625+offset, 5, 0);
		eq.spawn2(BLOODTHIRSTY_TYPE, 0, 0, -4141, 5623+offset, 5, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);

	elseif ( e.wp == 88 ) then
		e.self:Emote("picks up a small gem to place inside the handle.");
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4268, 5892+offset, 5, 0);
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4263, 5895+offset, 5, 0);
		eq.spawn2(ABHORRENT_TYPE, 0, 0, -4265, 5890+offset, 5, 0);
		eq.spawn2(SINISTER_TYPE, 0, 0, -4267, 5890+offset, 5, 0);
		eq.spawn2(THULIAN_TYPE, 0, 0, -4264, 5896+offset, 5, 0);
		eq.spawn2(BLOODTHIRSTY_TYPE, 0, 0, -4266, 5894+offset, 5, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);

	elseif ( e.wp == 99 ) then
		e.self:Emote("kneels down and picks up a dagger blade tip.");
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4430, 6368+offset, 5, 0);
		eq.spawn2(AGGRESSOR_TYPE, 0, 0, -4435, 6368+offset, 5, 0);
		eq.spawn2(ABHORRENT_TYPE, 0, 0, -4433, 6365+offset, 6.75, 0);
		eq.spawn2(SINISTER_TYPE, 0, 0, -4431, 6367+offset, 6.75, 0);
		eq.spawn2(THULIAN_TYPE, 0, 0, -4434, 6369+offset, 6.75, 0);
		eq.spawn2(BLOODTHIRSTY_TYPE, 0, 0, -4432, 6366+offset, 6.25, 0);
		nc = eq.spawn2(NIGHTMARISH_TYPE, 0, 0, e.self:GetX(), e.self:GetY(), e.self:GetZ(), 0);

	elseif ( e.wp == 106 ) then
        MazeRP(i,"The last guardian of Thelin's nightmare rises before you. Terris Thule's voice thunders through the hedges: \"His torment will never end!\"");
        MazeLog(i,"BOSS","Final construct summoned; awaiting the dagger blade shard.");
		eq.spawn2(CONSTRUCT_TYPE, 0, 0, -4550, 6118+offset, 5, 0);
		instance[i].state = 3;SaveRouting(i,e.self);
		eq.set_timer("depop", 7200000); -- so maze doesn't get stuck in an unusuable state in case nobody turns in boss item
		
	elseif ( e.wp == 108 ) then
		eq.set_timer("talk1", 5000);
	end
	
	if ( nc ) then
		table.insert(instance[i].ids, nc:GetID());SaveRouting(i,e.self);
	end
end

function ThelinTradeEvent(e)
    EnsureRouting();
	local i = GetInstanceFromSpawnID(e.self:GetSpawnPointID());	
	local item_lib = require("items");
	
	if ( instance[i].state == 3 and item_lib.check_turn_in(e.self, e.trade, {item1 = 9258}) ) then -- Dagger Blade Shard
		e.self:Emote("takes the final shard from you and places all of the pieces on the ground, with unseen hands the dagger moves together and fuses itself back together into one complete piece.  Thelin picks it up and hands it to you.");
		e.other:QuestReward(e.self, 0, 0, 0, 0, 9259); -- Thelin's Dagger
		e.self:SetRunning(true);
		e.self:ResumeWandering();
		e.self:SetSpecialAbility(35, 1); -- No Harm from Players on
		e.self:SetSpecialAbility(24, 1); -- Will Not Aggro on
		e.self:SetSpecialAbility(25, 1); -- Immune to Aggro on
		
		local offset = 1000 - (i * 1000);
		instance[i].terris = eq.spawn2(TERRIS_TYPE, 0, 0, -4532, 5950+offset, 8, 0);SaveRouting(i,e.self);
        MazeRP(i,"The fragments of Thelin's dagger rise and fuse together in a flash of pale light. A cold presence gathers nearby: Terris Thule has come to answer his demand.");
        MazeLog(i,"DAGGER","Dagger restored; Terris dialogue begins.");
		eq.set_timer("depop", 1500000);
	end

	item_lib.return_items(e.self, e.other, e.trade);
end	


function ThelinOutsideSayEvent(e)

	local qglobals = eq.get_qglobals(e.other);

	if ( not qglobals.thelin ) then
		if ( e.message:findi("hail") ) then
			e.other:Message(0, "Thelin Poxbourne screams loudly, and then falls asleep once again.");
		end
		return;
	end

	if ( e.message:findi("hail") ) then
		e.other:Message(0, "Thelin Poxbourne tells you, 'Who is it?  Are you.. really there?  You are!  Please I beg of you to help me escape from this horrid place.  Terris Thule is holding me here, she delights in the nightmares she sends me.  To further torture me, she has offered me a pact.  She has said that if I can retrieve my [dagger], then I am free to go.  She does this only because she knows that I cannot retrieve it on my own.'");
	
	elseif ( e.message:findi("dagger") ) then
		e.other:Message(0, "Thelin Poxbourne tells you, 'She has taken the only thing that has brought me any joy in my life.  She took it and broke it into seven pieces.  She placed them deep within the labyrinth of my nightmare.  I must retrieve it, will you [help] me.  Please I beg of your mercy.'");
		
	elseif ( e.message:findi("help") ) then
		e.other:Message(0, "Thelin Poxbourne tells you, 'I do not know who you are, but I am thankful that you have stumbled upon me.  I can bring you into my dream state, but my powers are limited. I can maintain three separate dreams, each holding no more than twenty-four adventurers.  Please when you are prepared have the leader of each of your band of adventurers tell me they are ready.'");
		
	elseif ( e.message:findi("ready") ) then


        EnsureRouting();for i=1,3 do Reconcile(i);end
        local members=GetMazeGroup(e.other,150);if #members==0 then return;end
        local raid=e.other:GetRaid();local rid=raid and raid.valid and raid:GetID() or 0;
        local trial,conflict=Assignment(members);
        if conflict then Deny(e.other,1,conflict);return;end
        if trial>0 then
            local room=instance[trial];
            if room.rid~=rid then Deny(e.other,trial,"Your band has changed since entering this dream. I cannot send you into another one while it remains occupied.");return;end
            if room.state~=1 then Deny(e.other,trial,"Your dream has already begun and is sealed. I cannot send your companions into a different maze.");return;end
            if Seats(trial)+Needed(trial,members)>24 then Deny(e.other,trial,"There is not enough room for your whole band in this dream.");return;end
        else
            for i=1,3 do
                local room=instance[i];
                if room.rid==rid and room.state==1 and Seats(i)+Needed(i,members)<=24 then trial=i;break;end
            end
            if trial==0 and rid>0 then
                for i=1,3 do
                    local room=instance[i];
                    if room.rid==rid and room.state>=2 and room.state<=5 and Seats(i)<24 then
                        Deny(e.other,i,"Your raid's dream has already begun and is sealed. I cannot split your companions into another maze.");return;
                    end
                end
            end
            if trial==0 then
                for i=1,3 do
                    if instance[i].state==0 and not ClientInTrial(i) and GetThelinInTrial(i) then trial=i;break;end
                end
            end
        end
        if trial==0 then
            e.self:Emote("groans in agony. 'I suddenly feel the grasp of Terris upon my heart. I must rest. Please return after I have rested.'");return;
        end
        local thelin=GetThelinInTrial(trial);
        if not thelin then Deny(e.other,trial,"I cannot find my other self within that dream. Please wait before entering.");return;end
        local room=instance[trial];local firstEntry=room.state==0;
        if firstEntry then room.state=1;room.rid=rid;room.wait_until=Now()+300;room.members={};end
        local moving={};
        for _,member in ipairs(members) do
            local id=Character(member);local ticket=room.members[id];
            if not InRoom(member,trial) and (not ticket or ticket.arrived or ticket.pending_until<=Now()) then
                room.members[id]={pending_until=Now()+ARRIVAL_GRACE,arrived=false};moving[#moving+1]=member;
            end
        end
        Seats(trial);SaveRouting(trial,thelin); -- Reserve before issuing asynchronous MovePC requests.
        local governor=eq.get_entity_list():GetMobByNpcTypeID(GOVERNOR_TYPE);
        if governor and governor.valid then eq.set_timer("check",10000,governor);end
        if #moving==0 then
            e.other:Message(0,"Thelin Poxbourne tells you, 'I have already guided your band toward this dream. Give them a moment to arrive.'");
            MazeLog(trial,"DUPLICATE","No new teleport needed for "..e.other:GetName().."; existing reservations retained.");return;
        end
        e.self:Emote("closes his eyes and falls asleep immediately. He looks peaceful for a moment, then screams in agony!");
        MazeLog(trial,"PORT",string.format("Sending %d unique characters from %s's band; raid %d.",#moving,e.other:GetName(),rid));
        MazeRP(trial,"Thelin's trembling voice reaches you through the darkness. \"Stay together, friends. I will guide you into the same dream.\"");
        MoveMazeGroup(moving,204,PORT_COORDS[trial].x,PORT_COORDS[trial].y,PORT_COORDS[trial].z,64);
        Reconcile(trial);
        if firstEntry then eq.set_timer("start_warning",5000,thelin);end
	end
end

function ThelinInsideSayEvent(e)
    EnsureRouting();
	local i = GetInstanceFromSpawnID(e.self:GetSpawnPointID());

	if ( instance[i].state == 1 ) then

		if ( e.message:findi("hail") ) then
			e.self:Say("Has everyone made it here safely?  When you tell me I will seal off my dream and we can begin.  We must be careful here, visions await around every turn.  Are you ready to follow?  I know where all the pieces of the dagger are, but I cannot collect them all on my own.");

		elseif ( e.message:findi("ready") ) then
            Reconcile(i);
            local raid=e.other:GetRaid();local rid=raid and raid.valid and raid:GetID() or 0;
            if not InRoom(e.other,i) or not instance[i].members[Character(e.other)] or (instance[i].rid>0 and instance[i].rid~=rid) then
                Deny(e.other,i,"You are not among the companions admitted to this dream.");return;
            end
            if Pending(i) then Deny(e.other,i,"Some of your companions are still entering my dream. Wait for them before we begin.");return;end
			e.self:Say("Please stay close, I know not what horror Terris will unleash upon us.");
			e.self:CastToNPC():SetNoQuestPause(true); -- do not pause on say events
			e.self:SetSpecialAbility(35, 0); -- No Harm from Players off
			e.self:CastToNPC():SetCastRateDetrimental(35); -- this should really be implemented as an NPC database field
			                                               -- this NPC is a shadowknight but casts necro spells; needs to cast aggressively as well
			e.self:SpellFinished(278, e.self); -- Spirit of Wolf
			e.self:AssignWaypoints(8+i);
			instance[i].wait_checks = 0;
			instance[i].state = 2;SaveRouting(i,e.self);MazeLog(i,"START","Dream sealed; further entry is refused rather than redirected.");
            MazeRP(i,"The hedges twist behind you, sealing the path to the waking world. Thelin steadies himself. \"Stay close. Terris is watching us.\"");
		end
		
	elseif ( instance[i].state == 4 ) then
	
		if ( e.message:findi("hail") ) then

			local qglobals = eq.get_qglobals(e.other);
			
			if ( not qglobals.thelin ) then
				e.other:Message(0, "Thelin Poxbourne tells you, 'I do not recognize your face. Are you a vision sent by Terris?!  Begone from my thoughts and begone from my dreams!'");
				eq.set_global("cl_maze", "1", 5, "F");
				e.other:Message(15, "You have received a new checklist flag!");
		
			else
				e.other:Message(0, "Thelin Poxbourne tells you, 'Please destroy her for all that have had to endure her hideous visions.'  Thelin closes his eyes and is swept away from his nightmare.  The land of pure thought begins to vanish from around you.");
				
				if ( qglobals.thelin == "1" ) then
					eq.set_global("thelin", "2", 5, "F");
					e.other:Message(15, "You have received a character flag!");
					
					if ( qglobals.cl_maze ) then
						eq.delete_global("cl_maze");
					end
				end				
			end
			
			e.self:CastSpell(1195, e.other:GetID()); -- Waking Moment
		end
	end
end

function ThelinTimerEvent(e)
    EnsureRouting();
	local i = GetInstanceFromSpawnID(e.self:GetSpawnPointID());

	if ( e.timer == "start_warning" ) then
		if ( instance[i].state == 1 ) then
		        e.self:Say("Time is short. We have only five minutes to begin, before Terris Thule takes notice that you are here.");
            MazeRP(i,"Thelin glances anxiously into the shifting hedges. \"Gather your companions quickly. We must begin before Terris finds us.\"");
		end

	elseif ( e.timer == "talk1" ) then
        MazeRP(i,"Terris Thule's voice fills the maze. \"This bargain is broken! You did not earn your freedom alone!\" The dream shudders beneath her anger.");
		e.self:Say("Terris hear me now!  I have done as you have called for.  My beloved dagger is whole once again!  Come now keep up your part of the bargain.");
		instance[i].terris:Say("You fool!  You did not earn this prize on your own!  The contract that has been drawn is now invalid.  You will never leave my grasp, prepare your soul for eternal torment!");
		eq.set_timer("talk2", 8000);
	
	elseif ( e.timer == "talk2" ) then
        MazeRP(i,"Terris Thule laughs as her form dissolves into mist, leaving Thelin with a broken promise and a sharpened hatred.");
		e.self:Say("Vile wench, I knew in the end it would come to this.  You shall pay dearly for your injustice here.");
		instance[i].terris:Emote("laughs heartily and then vanishes in a swirl of incorporeal mist.");
		instance[i].terris:CastSpell(36, e.self:GetID()); -- Gate
		eq.set_timer("talk3", 8000);
		eq.set_timer("terrisdepop", 2000);
	
	elseif ( e.timer == "terrisdepop" ) then
		instance[i].terris:Depop();
		instance[i].terris = nil;SaveRouting(i,e.self);
	
	elseif ( e.timer == "talk3" ) then
		e.self:Say("So then my hope is nearly lost.  Take with you my dagger.  Plunge it deep into her soulless heart.  If I cannot escape from this plane under her rules, I shall make my own!");
		eq.set_timer("depop", 600000);
		instance[i].state = 4;SaveRouting(i,e.self);
        MazeRP(i,"Thelin's nightmare begins to loosen its grip. \"Take my dagger. Strike Terris where I cannot, and end this torment.\" A path to the waking world opens before you.");
		eq.debug("Hedge Maze "..i.." success");
		
	elseif ( e.timer == "depop" ) then
        MazeRP(i,"The last remnants of Thelin's dream unravel. The maze fades, drawing you back toward the waking world.");
		RemoveFromTrial(i, 204, 1668, 282, 213, 255, "The nightmare fades from around you.");
		instance[i].state = 5;SaveRouting(i,e.self);
		eq.depop_with_timer();
	end
	eq.stop_timer(e.timer);
end

function ThelinDeathEvent(e)
    EnsureRouting();
	local i = GetInstanceFromSpawnID(e.self:GetSpawnPointID());	
	
	local mob;
	for _, id in ipairs(instance[i].ids) do
		mob = eq.get_entity_list():GetNPCByID(id);
		if ( mob and mob.valid ) then
			mob:CastSpell(3073, id); -- Banishment of Nightmares
		end
	end
    MazeRP(i,"Thelin falls, and his fragile dream shatters around you. Terris Thule's laughter follows you back into the darkness.");
	-- have to remove players this way because Banishment doesn't work since it's flagged a beneficial spell
	MoveFailedTrialCorpses(i);
	RemoveFromTrial(i, 204, 1668, 282, 213, 255);
	instance[i].state = 5;SaveRouting(i,e.self);
	eq.debug("Hedge Maze "..i.." failed");
end

function MobSpawnEvent(e)
	eq.set_timer("depop", 1200000);
end

function MobTimerEvent(e)
	if ( e.timer == "depop" ) then
		eq.depop();
	end
end

function CombatEvent(e)
	if ( e.joined ) then
		eq.pause_timer("depop");
	else
		eq.resume_timer("depop");
	end
end

function event_encounter_load(e)

	eq.register_npc_event("Maze", Event.timer, GOVERNOR_TYPE, GovernorTimerEvent);
	
	eq.register_npc_event("Maze", Event.timer, THELIN_INSIDE_TYPE, ThelinTimerEvent);
	eq.register_npc_event("Maze", Event.waypoint_arrive, THELIN_INSIDE_TYPE, ThelinWaypointEvent);
	eq.register_npc_event("Maze", Event.trade, THELIN_INSIDE_TYPE, ThelinTradeEvent);
	eq.register_npc_event("Maze", Event.death_complete, THELIN_INSIDE_TYPE, ThelinDeathEvent);

	eq.register_npc_event("Maze", Event.say, THELIN_OUTSIDE_TYPE, ThelinOutsideSayEvent);
	eq.register_npc_event("Maze", Event.say, THELIN_INSIDE_TYPE, ThelinInsideSayEvent);

	eq.register_npc_event("Maze", Event.spawn, NIGHTMARISH_TYPE, MobSpawnEvent);
	eq.register_npc_event("Maze", Event.timer, NIGHTMARISH_TYPE, MobTimerEvent);

	for _, id in ipairs(MOB_TYPES) do
		eq.register_npc_event("Maze", Event.spawn, id, MobSpawnEvent);
		eq.register_npc_event("Maze", Event.timer, id, MobTimerEvent);
		eq.register_npc_event("Maze", Event.combat, id, CombatEvent);
	end
end
