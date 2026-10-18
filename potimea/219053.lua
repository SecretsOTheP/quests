-- PoTimeA controller
local POTIMEA_CONTROLLER_TYPE = 219053;
local POTIMEB_CONTROLLER_TYPE = 223077;
local TIMEB_ZONEID = 223;
local TRIAL_TELEPORTS = {
	[1] = { -35, 1636, 495, 128 },		-- earth
	[2] = { -36, 1352, 495, 128 },		-- air
	[3] = { -27, 1103, 495, 128 },		-- undead
	[4] = { -51,  857, 495, 128 },		-- water
	[5] = { -55,  569, 495, 128 },		-- fire
};
local PHASE_LOCS = {
	[3] = { 800, 1100, 494, 128 },
	[4] = { -401, 0, 348.75, 128 },
	[5] = { -419, 0, 3.75, 128 },
	[6] = { -419, 0, 3.75, 128 },
};
local RUN_SPEED_BUFFS = { 220,1922,3185, 424,1554,2002, 874,1340, 169, 278,1776,1921,2517,2524,1330,1750,2007, 717,2605 };

local activeRaidID, activeInstanceID, numRaiders, activePhase, quarmState = 0, 0, 0, 0, 0;
local trialRaiders = {};
local block, pendingStartData, startSignalTries;
local reportedCounts = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };
local presentPlayers, pendingEntries = {}, {};

function RefreshAdmissionCounts()
	for i = 1, 9 do trialRaiders[i] = reportedCounts[i] end
	for _, entry in pairs(pendingEntries) do
		local region = entry.dial;
		if ( activePhase == 2 ) then region = region < 3 and 6 or (region == 3 and 7 or 8) end
		if ( activePhase <= 2 ) then trialRaiders[region] = trialRaiders[region] + 1 end
		trialRaiders[9] = trialRaiders[9] + 1;
	end
	numRaiders = trialRaiders[9];
end

function Unpacket(s, numberize, returnTable)
	local t = {};
	for w in s:gmatch("([^;]+)") do
		if ( numberize ) then
			w = tonumber(w);
		end
		table.insert(t, w);
	end
	if (returnTable) then
		return t;
	else
		return unpack(t);
	end
end

function SignalTimeB(signal, data)
	eq.cross_zone_signal_npc_by_npc_type_id(POTIMEB_CONTROLLER_TYPE, eq.get_zone_guild_id(), signal, data or "");
end

function event_signal(e)

	if ( e.signal == 1 ) then		-- new instance started
		
		local charID, dialNum, raidID, instanceID = Unpacket(e.data, true);
		
		if ( raidID and instanceID ) then
			if ( activeInstanceID == instanceID and activePhase > 0 ) then
				SignalTimeB(2); -- repeated startup confirmation must not clear entry reservations
				return;
			end
			eq.debug("Plane of Time instance started.  Raid ID: "..raidID..";  instanceID: "..instanceID);
			activeRaidID = raidID;
			activeInstanceID = instanceID;
			numRaiders, activePhase, quarmState = 0, 1, 0;
			pendingStartData, startSignalTries = nil, 0;
			presentPlayers, pendingEntries = {}, {};
			reportedCounts = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };
			eq.stop_timer("start_retry");
			for i = 1, 9 do
				trialRaiders[i] = 0;
			end
			SignalTimeB(2);	-- send confirm
			block = false;
			eq.stop_timer("unblock");
			--eq.zone_emote(0, "The portal flashes briefly, then glows steadily.");
			
			-- send instance starter inside
			e.signal = 3;
			event_signal(e);
			return;
		end
	
	elseif ( e.signal == 2 ) then			-- instance expired
		
		activePhase = -1;
		eq.set_timer("cooldown", 120000);
		SignalTimeB(2);	-- send confirm
		eq.debug("Plane of Time instance expired.");
	
	elseif ( e.signal == 3 ) then			-- player clicked dial; sent from dial
	
		if ( not e.data or block ) then
			return;
		end
		
		local charID, dialNum, raidID, instanceID = Unpacket(e.data, true);		
		if ( not charID or not dialNum or dialNum < 1 or dialNum > 5 or dialNum % 1 ~= 0 or not raidID or not instanceID ) then return end
		local client = eq.get_entity_list():GetClientByCharID(charID);
		if ( not client or not client.valid ) then return end
		-- One in-flight entry per character, even when repeated clicks reach us
		-- after the player script's short click throttle has elapsed.
		if ( pendingEntries[charID] or presentPlayers[charID] ) then return end
		local charName = client:GetName();
		eq.debug("client clicked dial.  charID: "..charID.." ("..charName..");  dialNum: "..dialNum..";  raidID: "..raidID..";  instanceID: "..instanceID);
		eq.debug("active raid ID: "..activeRaidID..";  active instance ID: "..activeInstanceID);

		if ( activePhase == -1 ) then
			client:Message(0, "The portal glows weakly at first, then somewhat brighter.  It appears to be recharging.");
			return;
		end

		if ( activeRaidID == 0 and activeInstanceID == 0 and activePhase == 0 ) then
			-- TimeB is inactive and not cooling down, relay signal
			pendingStartData = e.data..";"..charName;
			startSignalTries = 12;
			SignalTimeB(1, pendingStartData);
			eq.set_timer("start_retry", 5000);
			block = true;	-- block signals until the instance is started
			eq.set_timer("unblock", 60000); -- in case signals are lost somehow
			
		elseif ( instanceID > 0 and activeInstanceID ~= instanceID ) then
			-- player is saved to an instance that is not the same as the active instance
			
			local qglobals = eq.get_qglobals(POTIMEB_CONTROLLER_TYPE, 223);
			local instanceGuildID = tonumber(qglobals["time_guild_"..instanceID]) or 0;
			local currentGuildID = eq.get_zone_guild_id();

			if ( instanceGuildID == currentGuildID ) then
			-- Converge an obsolete same-guild pointer on the loaded guild timeline.
			e.data = charID..";"..dialNum..";"..raidID..";"..activeInstanceID;
			event_signal(e);
			return;
			end

			local instanceTimers = qglobals["time_timers_"..instanceID];
			local instanceExpired = true;
			if ( instanceTimers ) then
				local timers = Unpacket(instanceTimers, true, true);
				local now = os.time();
				for _, t in pairs(timers) do
					if ( now < (t*100) ) then
						instanceExpired = false;
						break;
					end
				end
			else
				eq.debug(client:GetName().."'s saved instance ("..instanceID..") does not exist.  Allowing entry.");
			end
			
			if ( instanceExpired and instanceTimers ) then
				eq.debug(client:GetName().."'s saved instance ("..instanceID..") has expired timers.  Allowing player to switch instances.");
			end

			if ( not instanceExpired ) then
				-- player is saved to an instance with timers not expired.  deny entry
				client:Message(13, "The portal recoils from your touch. Your fate is already bound to another thread of time.");
			else
				-- send player into active instance even though IDs don't match
				e.data = charID..";"..dialNum..";"..raidID..";"..activeInstanceID;
				event_signal(e);
				return;
			end

		elseif ( activeRaidID ~= raidID ) then
			-- Raid IDs are temporary. The guild instance owns the timeline.
				eq.debug("Rebinding active Time instance "..activeInstanceID.." from raid "..activeRaidID.." to raid "..raidID);
				activeRaidID = raidID;
				SignalTimeB(9, "3;"..raidID);
				e.data = charID..";"..dialNum..";"..raidID..";"..activeInstanceID;
				event_signal(e);
		return;


		elseif ( (instanceID == activeInstanceID or instanceID == 0) and raidID == activeRaidID ) then
			
			local p2reject;
			if ( activePhase == 2 ) then
				if ( dialNum < 3 ) then
					if ( trialRaiders[6] >= 36 ) then
						p2reject = true;
					end
				elseif ( dialNum > 3 ) then
					if ( trialRaiders[8] >= 36 ) then
						p2reject = true;
					end
				else
					if ( trialRaiders[7] >= 18 ) then
						p2reject = true;
					end
				end				
			end
			
			if ( numRaiders >= 90 or (activePhase == 1 and trialRaiders[dialNum] >= 18) or p2reject ) then
				client:Message(0, "The energy has been drained from this portal.  You must wait before you can use it.");
			else
				client:Message(0, "The portal glows and the mists of time swirl around you.");
				
				pendingEntries[charID] = { dial = dialNum, expires = os.time() + 60 };
				RefreshAdmissionCounts();
				
				-- remove run speed buffs if quarm engaged
				if ( activePhase == 6 and quarmState > 1 and quarmState < 5 ) then
					for _, id in ipairs(RUN_SPEED_BUFFS) do
						client:BuffFadeBySpellID(id);
					end
				end

				SignalTimeB(3, client:CharacterID()..";"..dialNum);
				
				local loc = TRIAL_TELEPORTS[dialNum];
				if ( PHASE_LOCS[activePhase] ) then
					loc = PHASE_LOCS[activePhase];
				end
				client:MovePCGuildID(TIMEB_ZONEID, eq.get_zone_guild_id(), loc[1], loc[2], loc[3], loc[4]);
			end
		end
		
	elseif ( e.signal == 4 ) then		-- zone state update / phase change
	
		if ( not e.data ) then
			return;
		end

		local previousPhase = activePhase;
		activeRaidID, activeInstanceID, activePhase = Unpacket(e.data, true);
		if ( previousPhase == 1 and activePhase == 2 ) then
			reportedCounts[6] = reportedCounts[1] + reportedCounts[2];
			reportedCounts[7] = reportedCounts[3];
			reportedCounts[8] = reportedCounts[4] + reportedCounts[5];
		end
		RefreshAdmissionCounts();
		pendingStartData, startSignalTries = nil, 0;
		eq.stop_timer("start_retry");
		
		eq.debug("PoTimeB (instance ID "..activeInstanceID.."; raid ID "..activeRaidID..") active phase is now "..activePhase);
		SignalTimeB(2);	-- send confirm
		block = false;
	
	elseif ( e.signal == 5 ) then		-- periodic player counts

		local oldCount = numRaiders;
		-- Time B reports who is actually inside alongside the counts. This
		-- prevents counting an arrival both as a reservation and as a player.
		local countData, ids = (e.data or ""):match("^([%d;]+)|([%d;]*)$");
		if ( not countData ) then return end
		local counts = Unpacket(countData, true, true);
		if ( #counts ~= 11 or counts[10] ~= activeInstanceID or counts[11] ~= activePhase or activePhase < 1 ) then return end
		presentPlayers = {};
		for id in ids:gmatch("%d+") do presentPlayers[tonumber(id)] = true end
		for id, entry in pairs(pendingEntries) do
			-- Only a fresh report may release a failed/timed-out transfer.
			if ( presentPlayers[id] or os.time() >= entry.expires ) then pendingEntries[id] = nil end
		end
		for i = 1, 9 do reportedCounts[i] = counts[i] end
		RefreshAdmissionCounts();
		
		if ( oldCount ~= numRaiders ) then
			if ( activePhase == 1 ) then
				eq.debug("Active Raiders: "..numRaiders.."  --  Earth: "..trialRaiders[1]..";  Air: "..trialRaiders[2]..";  Undead: "..trialRaiders[3]..";  Water: "..trialRaiders[4]..";  Fire: "..trialRaiders[5]);
			elseif ( activePhase == 2 ) then
				eq.debug("Active Raiders: "..numRaiders.."  --  Earth+Air: "..trialRaiders[6]..";  Undead: "..trialRaiders[7]..";  Water+Fire: "..trialRaiders[8]);
			else
				eq.debug("Active Raiders: "..numRaiders);
			end
		end
		
	elseif ( e.signal == 6 ) then			-- Quarm state

		if ( not e.data ) then
			return;
		end

		quarmState = tonumber(e.data) or 0;

		if ( quarmState == 5 ) then
			eq.debug("Quarm slain; instance ends in 1 hour");
		else
			eq.debug("Quarm state is now "..quarmState);
		end
		
	elseif ( e.signal == 8 ) then			-- saved instance belongs to another guild zone

		local charID = tonumber(e.data);
		if ( charID ) then
			local client = eq.get_entity_list():GetClientByCharID(charID);
			if ( client and client.valid ) then
				client:Message(13, "The portal recoils from your touch. Your fate is bound to another guild's thread of time.");
			end
		end
		pendingStartData, startSignalTries = nil, 0;
		eq.stop_timer("start_retry");
		SignalTimeB(2);
		block = false;

	elseif ( e.signal == 9 ) then			-- saved timeline retired; a fresh one was created

		local charID = tonumber(e.data);
		if ( charID ) then
			local client = eq.get_entity_list():GetClientByCharID(charID);
			if ( client and client.valid ) then
				client:Message(13, "The last sands of your former timeline have fallen. A new path through the Plane of Time now lies before you.");
			end
		end
		pendingStartData, startSignalTries = nil, 0;
		eq.stop_timer("start_retry");
		SignalTimeB(2);
		block = false;

	elseif ( e.signal == 7 ) then			-- PoTimeB zone reset
		ResetZone();
		eq.debug("PoTimeB script reset");
	end
end

function event_timer(e)
	if ( e.timer == "unblock" ) then
		block = false;
		--eq.debug("unblocked", 3);
	elseif ( e.timer == "cooldown" ) then
		ResetZone();
	elseif ( e.timer == "start_retry" ) then
		if ( pendingStartData and startSignalTries > 0 ) then
			SignalTimeB(1, pendingStartData);
			startSignalTries = startSignalTries - 1;
			return;
		end
		pendingStartData = nil;
		block = false;
	end
	eq.stop_timer(e.timer);
end

function ResetZone()
	activeRaidID, activeInstanceID, numRaiders, activePhase = 0, 0, 0, 0;
	presentPlayers, pendingEntries = {}, {};
	reportedCounts = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	for i = 1, 9 do
		trialRaiders[i] = 0;
	end
end
