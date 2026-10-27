-- Plane of Time B instance controller

local MAX_CLIENTS = 72;
local POTIMEA_CONTROLLER_TYPE = 219053;
local POTIMEB_CONTROLLER_TYPE = 223077;
local Cycle = require("potime_cycle");
local EVENTS_CONTROLLER_TYPE = 223078;
local QUARM_TYPE = 223008;

local EMOTE_STRINGS = {
	[1] = "An hourglass appears in the distance, the few remaining sands trickling down.  As the last grain falls, multicolored lights erupt from it, surrounding you in a brilliant flash.",
	[2] = "Ethereal mists gather at the far wall, causing it fade in and out of focus.",
	[3] = "In the distance, an hourglass appears, the grains of sand falling methodically into place.  As quickly as the image was formed, it dissipates.  You have %s left.",
	
	[4] = "As the path before you opens up in a swirl of mystical energy, the faded image of an hourglass appears. You have %s.",
	[5] = "Solusek Ro says, 'This is absurd, why are we wasting our time and energy on this!?  Direct action is needed, now!  Banishing Zebuxoruk will not stop the mortals from entering into our planes.  Their greed for power will have them soon trampling through our realms!'",
	[6] = "Rallos Zek says, 'On this I agree!  We must take action and the time is now.  I will not have these mortals achieving the powers that we hold.'",
	[7] = "Fennin Ro says, 'Calm yourselves, you need to appreciate the situation that is at hand.'",
	[8] = "Xegony says, 'Please listen to reason, we are doing what we must.  The mortals possess a direct tie to Zebuxoruk.  If his stasis is finished their link will dwindle as well as their powers and knowledge.'",
	[9] = "Rathe says, 'The knowledge that was given to them by Zebuxoruk will fade from their minds.  We must do this now, for if they were able to translate the divine language all existence would unravel.  The balance of power in the universe would be destroyed.'",
	[10] = "Solusek Ro says, 'This is exactly the point that I am making!  So you agree we must show them now that we are the power above them, and not to be questioned!'",
	[11] = "Rallos Zek says, 'You must see what he refers to; we must turn to Norrath and show them our power.  What they are trying to accomplish cannot be allowed to come to pass.'",
	[12] = "Fennin Ro says, 'My son, please understand we must stop this advancement of mortals without halting their existence.  The balance of power must be maintained.  Without the mortals the balance would fade.'",
	[13] = "Solusek Ro says, 'So they have made your decision for you too father.  You are all wrong, this will only bring them further into our realms seeking answers!  We must take action now.  Have at your foolish games, I will not allow them to obtain my power.'",
	[14] = "You look up and see a meteor burning through the sky; Solusek returning to his tower to brood over the matters at hand.",
	[15] = "Rallos lets out a sigh of frustration that vibrates the ground at your feet.",
	[16] = "Rathe says, 'Rallos still your warring heart.  This is what must be done.  We must place him in a stasis from which he will not be released.  Come share your power.  We must commence now.'",
	[17] = "Xegony says, 'Mithaniel, Karana please record what you see here.  With your good nature I am sure that your records will be impartial to any side.  We must record this for the ages and learn from our mistake of allowing Zebuxoruk to gain so much power that is easily passed on to mortals.'",
	[18] = "With a sudden jolt the wall comes into crystal clear focus.",
	
	[19] = "A bright aura streaks through the sky.  The power of it sends a surge through your body that makes your hair stand on end.",
	[20] = "The Triumvirate of Water speaks as one voice.  It says, 'Now step up to the chambers.  Give a part of yourselves to the bind on Zebuxoruk.  Through our power, the bonds on him will never be broken.  He will be eternally placed in stasis.'",
	[21] = "Saryrn says, 'What of our weakened state.  I refuse to return to my realm without the power to rule over my minions.'",
	[22] = "Terris Thule says, 'Yes, how can I spread my touch over my lands if I lack so much of myself?'",
	[23] = "Cazic Thule says, 'Do not worry daughter, we shall stay here until we are able to recover our strength.'",
	[24] = "Rallos Zek says, 'Our armies shall serve us as we regenerate our abilities.  We have nothing to fear.'",
	[25] = "Bertoxxulous says, 'My soldiers of pestilence shall watch over us.  Let us return to our chambers now.'",
	[26] = "Innoruuk says, 'Are you enjoying watching this Hammer of the Tribunal?  I hope your petty report will show my disdain for the Tribunal having no hand in this.'",
	[27] = "The Seventh Hammer says, 'Do not waste your energy Innoruuk.  You know they are eternally preoccupied with their trials.  Surely even you understand many of these trials exist because of the hate you instill into the population of Norrath.'",
	[28] = "Innoruuk says, 'Do not mock me!  I shall seek you out after this is done and my power is restored.  You will not be so smug after our next meeting.'",
	[29] = "With a sudden jolt the wall comes into crystal clear focus.",
	
	[30] = "Terris Thule says, 'I am certain my warriors will have no problem holding back any intruders, but I have my doubts about the other armies.'",
	[31] = "Vallon Zek says, 'Surely you jest.  Your armies better than the regiments from our realm?'",
	[32] = "Tallon Zek says, 'There is no question that our warriors of War and Tactics will be the backbone of the army.'",
	[33] = "Saryrn says, 'It is no matter anyways, no mortal could ever ascend to this place.  These precautions are unnecessary.  Bringing them here was a waste of time.'",
	[34] = "Energy swirls rapidly through the portal causing it to glow brightly with power.",
	
	[35] = "Rallos Zek says, 'Something is wrong.  I feel Tallon and Vallon's spirits have weakened.'",
	[36] = "Innoruuk says, 'Don't be a fool, that is just from giving a part of themselves to the bond on Zebuxoruk.'",
	[37] = "Cazic Thule says, 'No.  It is more than that, I can feel the force of Terris has been drained as well.'",
	[38] = "Bertoxxulous says, 'This is not possible, could mortals have reached us here?  Call in our armies, we are too weak to fight now.'",
	[39] = "Innoruuk says, 'You are all incompetent!  I knew you all could not be trusted.  If we are defeated in our weakened state, I do not know if we will be able to coalesce again.  I will never forgive you all for what has transpired today!'",
	[40] = "Rallos Zek says, 'Now is not the time to bicker!  We must focus our strength on these puny mortals!  Minions of the army, come to our sides.  Your gods beckon you, we need you now!'",
	[41] = "The sundial across the room begins to glow with an ethereal energy.",
	
	[42] = "Fennin Ro says, 'Impossible!  How could the races of Norrath have traveled this deep into the Planes?!'",
	[43] = "Xegony says, 'I regret that it has come to this.  They leave us with little choice, however.  We must fuse our powers together.  Separately we are weakened, together we will halt their advances.'",
	[44] = "Triumvirate of Water says, 'Unfortunate as it may be, I agree.  We must call upon the beast we swore would never be needed.'",
	[45] = "The Rathe says, 'Then let us begin.  Let our abilities and powers meld into one.  It shall be our final protector and savior.  The only thing standing between us and non-existence'",
	[46] = "Your head pounds from the amount of raw energy that begins to coalesce throughout the plane. Bright flashes of red, blue, green and brown begin to come into focus on one single point. A large towering beast begins to manifest itself. A horrible creation with all the powers from each elemental realm. Your body begins to shudder by the mere presence of this being.",
	[47] = "The sundial across the room begins to glow with an ethereal energy.",

};

local REGIONS = {
	[1] = { -500, 1000, 1500, 2000 },	-- earth trial
	[2] = { -500, 1000, 1230, 1500 },	-- air
	[3] = { -500, 1000, 1000, 1230 },	-- undead
	[4] = { -500, 1000,  725, 1000 },	-- water
	[5] = { -500, 1000,  400,  725 },	-- fire
	[6] = { -500, 1000, 1230, 2000 },	-- earth+air
	[7] = { -500, 1000, 1000, 1230 },	-- undead
	[8] = { -500, 1000,  400, 1000 },	-- water+fire
};
local REGION_MAX = { 18, 18, 18, 18, 18, 36, 18, 36 };
local NUM_BOSSES_PHASE = { 5, 5, 18, 4, 4, 1 };
local DIALOG_START_STOPS = { [1] = { 5, 18 }, [2] = { 19, 29 }, [3] = { 30, 34 }, [4] = { 35, 41 }, [5] = { 42, 47 } };

local zonePhase = 0;
local zoneRaidID = 0;
local zoneInstanceID = 0
local zoneInstanceGeneration;
local zoneInstanceData = "";
local zoneTimers = {};
local zoneBossTable = {};
local failTime = 0;
local failWarningMsg;
local validPlayers;     -- sequential list of sub-tables containing character ID and os.time() of when they zoned
local bossEngagedTime = 0;
local phase3Completed = false;
local guildCycle;
local phaseAdvancePending = false;
local phaseOneStarted = false;
local forceClose = false;
local emptySince;
local trialStates = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 };
local dialog;
local trialSignal, signalTries, confirmSignal, confirmData, pulses;
local lastSavedClientID;

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

-- only called when client is about to zone over from clicking dial
function AddValidPlayer(charID, dialNum)
	for i in ipairs(validPlayers) do
		if ( validPlayers[i][1] == charID ) then
			validPlayers[i][2] = os.time();
			validPlayers[i][3] = dialNum;
			validPlayers[i][4] = true;					-- zoned in from dial click? turns false shortly after zoning over
			validPlayers[i][5] = bossEngagedTime;		-- phase 4-6 raid boss engaged time that is set when CheckValidPlayers() is called after pull
			return;
		end
	end
	table.insert(validPlayers, { charID, os.time(), dialNum, true, bossEngagedTime });
end

-- sort list so late zoners are at bottom
function SortValidPlayerList()
	table.sort(validPlayers, function(a, b) if ( a[2] < b[2] ) then return true; end end );
end

-- returns: true/false if player has ever zoned in via dial while inside the active raid
--          true/false if player just zoned in via dial.  flips false next time CheckValidPlayers() is called (every 20s)
--          engage time of boss if player was in combat area when CheckValidPlayers() was called while boss was engaged
function IsValidCharID(charID, dialNum)
	for _, p in ipairs(validPlayers) do
		if ( p[1] == charID ) then
		
			if ( not dialNum ) then
				return true, p[4], p[5];
			else
				if ( dialNum == p[3] ) then
					return true, p[4], p[5];
				elseif ( dialNum == 6 and (p[3] == 1 or p[3] == 2) ) then
					return true, p[4], p[5];
				elseif ( dialNum == 7 and p[3] == 3 ) then
					return true, p[4], p[5];
				elseif ( dialNum == 8 and (p[3] == 4 or p[3] == 5) ) then
					return true, p[4], p[5];
				end			
			end
		end
	end
	return false, false, 0;
end

function KickPlayer(client)
	if ( client:Connected() ) then
		client:MovePCGuildID(219, eq.get_zone_guild_id(), math.random(-57, -17), math.random(-130, -90), 10, 0);	-- Plane of Time A evac loc with some randomness
	end
end

function SetBossKilled(phase, bossNum)
	if ( Cycle.expired(guildCycle, os.time()) ) then EndAttempt(); return false end
	if ( not zoneBossTable[phase] or not zoneBossTable[phase][bossNum] ) then
		return false;
	end
	local alreadyKilled = zoneBossTable[phase][bossNum] == 1;
	local now = os.time();
	local t = 561600; -- original god lockout: 6 days, 12 hours
	if ( phase == 1 ) then
		t = 43200; -- original Phase 1 lockout: 12 hours
	elseif ( phase == 2 or phase == 3 ) then
		t = 302400; -- original Phase 2/3 lockout: 3 days, 12 hours
	end
	
	local timerNum = phase;
	if ( phase == 4 ) then
		timerNum = bossNum + 3;
	elseif ( phase == 5 ) then
		timerNum = bossNum + 7;
	elseif ( phase == 6 ) then
		timerNum = 12;
	end
	-- A duplicate god-death signal must not replace a still-active saved lockout
	-- or award phase completion again. Existing deadlines survive this restoration.
	if ( phase > 3 and alreadyKilled and zoneTimers[timerNum] >= now ) then
		return false;
	end
	zoneBossTable[phase][bossNum] = 1;
	if ( phase > 3 or zoneTimers[timerNum] == 0 ) then -- first kill starts a Phase 1-3 timer
		zoneTimers[timerNum] = guildCycle and
			(phase > 3 and guildCycle.ends or math.min(now + t, guildCycle.ends)) or now + t;
	end
	
	SetInstanceGlobals();
	return true;
end

-- returns true if phase has bosses up
function CheckPhaseStatus(phase)
	local now = os.time();
	local phaseDown = true;
	local timerNum;

	for i = 1, #zoneBossTable[phase] do

		timerNum = phase;
		if ( phase == 4 ) then
			timerNum = i + 3;
		elseif ( phase == 5 ) then
			timerNum = i + 7;
		elseif ( phase == 6 ) then
			timerNum = 12;
		end

		-- God kills last for this cycle, including after loading rounded legacy timers.
		if ( phase > 3 and guildCycle and zoneBossTable[phase][i] == 1 ) then
			zoneTimers[timerNum] = guildCycle.ends;
		end
		if ( zoneBossTable[phase][i] == 1 and now >= zoneTimers[timerNum] ) then
			zoneBossTable[phase][i] = 0; -- boss is now alive
			eq.debug("Phase "..phase.." boss "..i.." timer past expiry; respawning");
			phaseDown = false;
			zoneTimers[timerNum] = 0;
			
		elseif ( zoneBossTable[phase][i] == 0 ) then
			phaseDown = false;
		end
	end
	return not phaseDown;
end

-- kill data string is a series of 0s and 1s representing boss kills delimited by semicolons between phases
-- timer data string is a series of integers for the respawn timestamps of phases 1-3 and each god, with last two digits cut off
function SetInstanceVars(killData, timerData)
	
	local bosses = Unpacket(killData, false, true);
	local timers = Unpacket(timerData, true, true);
		
	if ( not timers or not bosses or not timers[12] or not bosses[6] ) then
		return false;
	end

	for p = 1, 6 do
		if ( #bosses[p] ~= NUM_BOSSES_PHASE[p] ) then
			return false;
		end
		if ( not zoneBossTable[p] ) then
			zoneBossTable[p] = {};
		end
		for i = 1, NUM_BOSSES_PHASE[p] do
			if ( bosses[p]:sub(i, i) == "1" ) then	-- "1" == boss killed
				zoneBossTable[p][i] = 1;
			else
				zoneBossTable[p][i] = 0;
			end
		end
	end
	
	for i = 1, 12 do
		if ( not timers[i] ) then
			zoneTimers[i] = 0;
		else
			zoneTimers[i] = timers[i] * 100;
		end		
	end
	
	validPlayers = {};
	return true;
end

-- A new allocation gets a distinct identity even when its numeric ID is reused.
-- Existing saves without this marker remain legacy timelines.
local function ValidTimeGeneration(value, instanceID)
	local epoch = type(value) == "string" and value:match("^"..instanceID..":(%d+)$");
	return epoch and tonumber(epoch) > 0 and tonumber(epoch) < math.huge;
end

function SetupNewInstance(controller)
	-- Keep new saves out of the shared legacy pool (1-999). Public Time uses
	-- guild -1; every guild gets its own 1000-ID block, even with stale caches
	-- or simultaneous starts in different guild zones.
	local guildID = eq.get_zone_guild_id();
	local firstID = (guildID + 2) * 1000;
	-- #timelockout reads timeline IDs as uint32. Never wrap into another block.
	if ( guildID < -1 or firstID + 999 > 4294967295 ) then
		eq.debug("Cannot allocate Time timeline for guild "..guildID..": ID range is invalid");
		return 0;
	end
	
	for p = 1, 6 do
		zoneBossTable[p] = {};
		for i = 1, NUM_BOSSES_PHASE[p] do
			zoneBossTable[p][i] = 0;
		end
	end
	
	for i = 1, 12 do
		zoneTimers[i] = 0;
	end
	
	validPlayers = {};
	zoneInstanceGeneration = nil;
	guildCycle = Cycle.new(os.time(), false);
	
	-- Numeric lookup reads current database state instead of the NPC's cache.
	local qglobals = eq.get_qglobals(POTIMEB_CONTROLLER_TYPE, 223);
	for slot = 1, 999 do
		local instanceID = firstID + slot;
		if (
			not qglobals["time_timers_"..instanceID] and
			not qglobals["time_kills_"..instanceID] and
			not qglobals["time_guild_"..instanceID] and
			not qglobals["time_expires_"..instanceID] and
			not qglobals["time_generation_"..instanceID] and
			not qglobals["time_cycle_"..instanceID]
		) then
			zoneInstanceGeneration = instanceID..":"..os.time();
			eq.debug("Using new instance ID "..instanceID);
			return instanceID;
		end
	end
	return 0;
end

-- Legacy retirement metadata must never erase an outstanding boss lockout.
-- New saves instead retire at their fixed cycle boundary.
function HasActiveTimeLockouts(timerData)
	if ( type(timerData) ~= "string" or not timerData:match("^%d[%;%d]*%d$")
		or timerData:find(";;", 1, true) ) then return false, false; end
	local now = os.time();
	local count, active = 0, false;
	for value in timerData:gmatch("([^;]+)") do
		local deadline = tonumber(value);
		if ( not deadline or deadline == math.huge ) then return false, false; end
		count = count + 1;
		if ( deadline * 100 >= now ) then active = true; end
	end
	return active, count == 12;
end

function IsRetiredLegacyTimeline(qglobals, instanceID)
	local cycle, validCycle = Cycle.decode(qglobals["time_cycle_"..instanceID]);
	if ( not validCycle ) then return false end -- restoration will reject damaged metadata
	if ( cycle ) then return Cycle.expired(cycle, os.time()) end
	local deadline = tonumber(qglobals["time_expires_"..instanceID]) or 0;
	local active, valid = HasActiveTimeLockouts(qglobals["time_timers_"..instanceID]);
	return deadline > 0 and os.time() >= deadline
		and valid and not active;
end

function FindGuildInstance(controller, guildID)
	-- Include legacy saves unchanged, but do not use a stale NPC cache.
	local qglobals = eq.get_qglobals(POTIMEB_CONTROLLER_TYPE, 223);
	local instanceID = 0;

	for name, value in pairs(qglobals) do
		local candidateID = tonumber(name:match("^time_guild_(%d+)$"));

		if ( candidateID and tonumber(value) == guildID ) then
			local hasState =
				(qglobals["time_kills_"..candidateID] and qglobals["time_timers_"..candidateID])
				or qglobals["time_cycle_"..candidateID];

			if (
				hasState and
				not IsRetiredLegacyTimeline(qglobals, candidateID) and
				(instanceID == 0 or candidateID < instanceID)
			) then
				instanceID = candidateID;
			end
		end
	end

	return instanceID;
end

function SetInstanceGlobals()

	local killsStr, timersStr = "", "";
	
	for p = 1, 6 do
		for i = 1, NUM_BOSSES_PHASE[p] do
			killsStr = killsStr..tostring(zoneBossTable[p][i])
		end
		if ( p < 6 ) then
			killsStr = killsStr..";";
		end
	end
	
	for i = 1, 12 do
		timersStr = timersStr..tostring(math.floor(zoneTimers[i] / 100));	-- cut off last two digits to save space in qglobal
		if ( i < 12 ) then
			timersStr = timersStr..";";
		end
	end
	
	eq.set_global("time_kills_"..zoneInstanceID, killsStr, 2, "D7");
	eq.set_global("time_timers_"..zoneInstanceID, timersStr, 2, "D7");
	eq.set_global("time_guild_"..zoneInstanceID, tostring(eq.get_zone_guild_id()), 2, "D7");
	-- Storage retention may refresh; the absolute cycle deadline never does.
	eq.set_global("time_expires_"..zoneInstanceID, tostring(guildCycle and guildCycle.ends or 0), 2, "D7");
	if ( guildCycle ) then
		eq.set_global("time_cycle_"..zoneInstanceID, Cycle.encode(guildCycle), 2, "D30");
	end
	if ( zoneInstanceGeneration ) then
		eq.set_global("time_generation_"..zoneInstanceID, zoneInstanceGeneration, 2, "D30");
	end
end

function SavePlayerInstance(client)
	-- Preserve long-lived character bindings; entry checks use the saved loot
	-- deadlines, so early participants cannot evade a later boss's lockout.
	eq.target_global("time_instance", tostring(zoneInstanceID), "D30", 0, client:CharacterID(), 0);
	eq.target_global("time_instance_guild", tostring(eq.get_zone_guild_id()), "D30", 0, client:CharacterID(), 0);
	-- Clear a previous generation when legitimately joining a legacy timeline.
	eq.target_global("time_instance_generation", zoneInstanceGeneration or "0", "D30", 0, client:CharacterID(), 0);
	if ( zoneInstanceGeneration ) then
		-- Keep the identity at least as long as the most recent character pointer.
		eq.set_global("time_generation_"..zoneInstanceID, zoneInstanceGeneration, 2, "D30");
	end

	-- set zoned-in-from-dial flag to false.  doing this at same time we save player
	local charID = client:CharacterID();
	for i, p in ipairs(validPlayers) do
		if ( p[1] == charID ) then
			p[4] = false;
		end
	end
	lastSavedClientID = charID;
	eq.debug(client:GetName().." saved to instance");
end

function SetPlayerBossTime(client, t)
	local charID = client:CharacterID();
	for i, p in ipairs(validPlayers) do
		if ( p[1] == charID ) then
			p[5] = t;
		end
	end
end

function TryStartTrials()
	for i = 1, 5 do
		if ( zonePhase == 1 and trialStates[i] == 0 ) then
		
			local clientList = eq.get_entity_list():GetClientList();
			local x, y;
			if ( clientList ) then
			
				for client in clientList.entries do
				
					x, y = client:GetX(), client:GetY();
					
					if ( trialStates[i] == 0 and not client:GetGM() and x > REGIONS[i][1] and x < REGIONS[i][2] and y > REGIONS[i][3] and y < REGIONS[i][4] ) then
						eq.set_timer("trial"..i.."start", 44000);
						trialStates[i] = 1;
						eq.debug("Trial "..i.." started");
					end
				end
			end
		end
	end
end

function CheckValidPlayers()
	local data, x, y, charID, isValid, zonedFromDial;
	local activeClients = 0;
	local trialClients = { 0, 0, 0, 0, 0, 0, 0, 0 };
	local bootList = {};
	local countedPlayers = {};
	
	local elist = eq.get_entity_list();
	local clientList = elist:GetClientList();
	local bossID = GetEngagedBossTime();
	
	if ( bossEngagedTime == 0 and bossID > 0 ) then
		bossEngagedTime = os.time();
	elseif ( bossID == 0 ) then
		bossEngagedTime = 0;
	end
	
	if ( clientList ) then
	
		for client in clientList.entries do

			if ( not client:GetGM() and client.valid and client:GetName() ~= "No name" ) then
				x, y = client:GetX(), client:GetY();
				charID = client:CharacterID();
				
				if ( x < 500 or y > 500 ) then
					-- clients not in the graveyard
					
					isValid, zonedFromDial = IsValidCharID(charID);
					if ( isValid ) then
						activeClients = activeClients + 1;
						countedPlayers[charID] = true;
						if ( zonedFromDial ) then
							SavePlayerInstance(client);
						end
						SetPlayerBossTime(client, bossEngagedTime);
					else
						bootList[charID] = true;		-- player had not zoned in via dial and is not in GY
						eq.debug(client:GetName().." is in combat area but should not be.  Kicking them from zone.");
					end
				end
			
				if ( zonePhase == 1 ) then
				
					for i = 1, 5 do
						if ( x > REGIONS[i][1] and x < REGIONS[i][2] and y > REGIONS[i][3] and y < REGIONS[i][4] ) then
							if ( IsValidCharID(charID, i) ) then
								trialClients[i] = trialClients[i] + 1;
							else
								if ( not bootList[charID] ) then
									activeClients = activeClients - 1;
									bootList[charID] = true;
									eq.debug(client:GetName().." is in the wrong trial. (possible warp hack)  Kicking them from zone.");
								end
							end
						end
					end
				
				elseif ( zonePhase == 2 ) then
				
					for i = 6, 8 do
						if ( x > REGIONS[i][1] and x < REGIONS[i][2] and y > REGIONS[i][3] and y < REGIONS[i][4] ) then
							if ( IsValidCharID(charID, i) ) then
								trialClients[i] = trialClients[i] + 1;
							else
								if ( not bootList[charID] ) then
									activeClients = activeClients - 1;
									bootList[charID] = true;
									eq.debug(client:GetName().." is in the wrong phase 2 area. (possible warp hack)  Kicking them from zone.");
								end
							end
						end
					end
			
				end
			end
		end
		
		local c, charID;
		if ( activeClients > MAX_CLIENTS ) then
			eq.debug("Too many players in combat area detected");
			local overCap = activeClients - MAX_CLIENTS;
			local boots = 0;
			
			SortValidPlayerList(); -- sorted by zone-in time
			
			for i = #validPlayers, 1, -1 do
				charID = validPlayers[i][1];
				
				c = elist:GetClientByCharID(charID);
				if ( c.valid and not bootList[charID] ) then
					bootList[charID] = true;
					eq.debug(c:GetName().." booted from zone");
					boots = boots + 1;
					activeClients = activeClients - 1;
					if ( boots == overCap ) then
						break;
					end
				end
			end
		end
		
		for n = 1, 8 do
			if ( trialClients[n] > REGION_MAX[n] ) then
				eq.debug("Too many players detected in trial #"..n);
				SortValidPlayerList(); -- sorted by zone-in time
				
				for i = #validPlayers, 1, -1 do
					charID = validPlayers[i][1];
					
					c = elist:GetClientByCharID(charID);
					if ( c.valid and not bootList[charID] and trialClients[n] > REGION_MAX[n] ) then
						if ( c:GetX() > REGIONS[n][1] and c:GetX() < REGIONS[n][2] and c:GetY() > REGIONS[n][3] and c:GetY() < REGIONS[n][4] ) then
							bootList[charID] = true;
							eq.debug(c:GetName().." booted from trial region "..n);
							activeClients = activeClients - 1;
							trialClients[n] = trialClients[n] - 1;
						end
					end
				end
			end
		end
		
		for charID in pairs(bootList) do		
			countedPlayers[charID] = nil;
			KickPlayer(elist:GetClientByCharID(charID));
		end
	end
	local ids = {};
	for charID in pairs(countedPlayers) do table.insert(ids, tostring(charID)) end
	return activeClients, trialClients, table.concat(ids, ";");
end

function KickRaid()
	local clientList = eq.get_entity_list():GetClientList();
	if ( clientList ) then
	
		for client in clientList.entries do

			if ( not client:GetGM() and (client:GetX() < 500 or client:GetY() > 500) ) then
				KickPlayer(client);
			end
		end
	end
end

function DepopZone()
	local npc_list = eq.get_entity_list():GetNPCList();
	
	if ( npc_list ) then
		for npc in npc_list.entries do
			if ( npc.valid and npc:GetNPCTypeID() ~= POTIMEB_CONTROLLER_TYPE and npc:GetNPCTypeID() ~= EVENTS_CONTROLLER_TYPE ) then
				npc:Depop();
			end
		end
	end
end

function SetFailWarningTimer()
	local timeRemaining = failTime - os.time();

	if ( timeRemaining < 1801 ) then
		eq.stop_timer("fail_warning");
		return;
		
	elseif ( timeRemaining < 3601 ) then
		failWarningMsg = "thirty minutes";
		eq.set_timer("fail_warning", (timeRemaining - 1800)*1000);
	else
		local hours = math.floor(timeRemaining / 3600);
		local seconds = timeRemaining % 3600;

		eq.set_timer("fail_warning", (seconds+1)*1000);
		if ( hours == 1 ) then failWarningMsg = "one hour";
		elseif ( hours == 2 ) then failWarningMsg = "two hours";
		elseif ( hours == 3 ) then failWarningMsg = "three hours";
		elseif ( hours == 4 ) then failWarningMsg = "four hours";
		elseif ( hours == 5 ) then failWarningMsg = "five hours";
		elseif ( hours == 6 ) then failWarningMsg = "six hours";
		elseif ( hours == 7 ) then failWarningMsg = "seven hours";
		elseif ( hours == 8 ) then failWarningMsg = "eight hours";
		elseif ( hours == 9 ) then failWarningMsg = "nine hours";
		elseif ( hours == 10 ) then failWarningMsg = "ten hours";
		elseif ( hours == 11 ) then failWarningMsg = "eleven hours";
		else failWarningMsg = ""; eq.debug("Error: hours == "..hours); end
	end
	if ( zonePhase >= 4 and not forceClose and zoneBossTable[6][1] == 0 ) then
		if ( zonePhase == 5 ) then
			failWarningMsg = "The gods' room guards may return in "..failWarningMsg..". Your boss progress will remain.";
		else
			-- There is no room trash to reset in P4 or P6.
			eq.stop_timer("fail_warning");
			return;
		end
	else
		failWarningMsg = string.format(EMOTE_STRINGS[3], failWarningMsg);
	end
end

function DoAdditionalHoursEmote(hours)
	local msg;
	if ( hours == 1 ) then msg = "one additional hour";
	elseif ( hours == 1.25 ) then msg = "an additional one hour and fifteen minutes";
	elseif ( hours == 2 ) then msg = "two additional hours";
	elseif ( hours == 3 ) then msg = "three additional hours";
	elseif ( hours == 4 ) then msg = "four additional hours";
	else msg = ""; end
	
	eq.zone_emote(0, string.format(EMOTE_STRINGS[4], msg));
end

function SignalTimeA(signal, data)
	eq.cross_zone_signal_npc_by_npc_type_id(POTIMEA_CONTROLLER_TYPE, eq.get_zone_guild_id(), signal, data or "");
end

-- repeat signal until we get a reply but give up after some tries.  make sure important signals get received
function SendSignalRequestConfirm(signal, data)
	SignalTimeA(signal, data);
	eq.set_timer("confirm", 5000);
	signalTries = 10;
	confirmData = data;
	confirmSignal = signal;
end

function LoadGuildCycle(qglobals, instanceID)
	local value, valid = Cycle.decode(qglobals["time_cycle_"..instanceID]);
	if ( not valid ) then return false end
	if ( not value ) then
		-- One-time adoption: retain all kills and start a full cycle on entry.
		-- A completed P3 or any saved god kill demonstrates prior back-half access.
		local checkpoint = true;
		for _, killed in ipairs(zoneBossTable[3]) do if killed == 0 then checkpoint = false end end
		for phase = 4, 6 do
			for _, killed in ipairs(zoneBossTable[phase]) do if killed == 1 then checkpoint = true end end
		end
		value = Cycle.new(os.time(), checkpoint);
	end
	guildCycle = value;
	for phase = 1, 6 do CheckPhaseStatus(phase) end
	return true;
end

function EndAttempt()
	for _, name in ipairs({"phase1", "dialog", "fail", "fail2", "fail_warning", "pulse", "check_trial_start", "late_reset", "cycle_end"}) do
		eq.stop_timer(name);
	end
	if ( zoneInstanceID > 0 ) then SetInstanceGlobals() end
	SendSignalRequestConfirm(2);
	zonePhase = -1;
	phaseAdvancePending, forceClose = false, false;
	emptySince = nil;
	eq.set_timer("cooldown", 60000);
	for i = 1, #trialStates do
		eq.stop_timer("trial"..i.."start");
		trialStates[i] = 0;
	end
	KickRaid();
	DepopZone();
end

function HasActiveCombat()
	local npcs = eq.get_entity_list():GetNPCList();
	if ( npcs ) then
		for npc in npcs.entries do
			if ( npc.valid and npc:IsEngaged() ) then return true end
		end
	end
	return false;
end

function HasSessionPlayers()
	local clients = eq.get_entity_list():GetClientList();
	if ( clients ) then
		for client in clients.entries do
			-- Include the graveyard so a wipe/recovery is not mistaken for leaving.
			if ( client.valid and client:Connected() and IsValidCharID(client:CharacterID()) ) then return true end
		end
	end
	return false;
end

function RenewLatePhase()
	if ( zonePhase < 4 or forceClose or phaseAdvancePending ) then return end
	eq.stop_timer("fail");
	eq.stop_timer("fail_warning");
	if ( zonePhase == 6 and zoneBossTable[6][1] == 1 ) then EndAttempt(); return end
	if ( HasActiveCombat() ) then
		eq.set_timer("late_reset", 10000);
		return;
	end
	eq.stop_timer("late_reset");
	if ( zonePhase == 5 ) then
		eq.signal(EVENTS_CONTROLLER_TYPE, 502, 0, table.concat(zoneBossTable[5], ";"));
		eq.zone_emote(0, "The armies of the gods return to guard their surviving masters.");
	else
		eq.zone_emote(0, "The hourglass turns. Your progress against the gods remains.");
	end
	failTime = os.time() + math.max(1, GetAdditionalHours(zonePhase)) * 3600;
	eq.set_timer("fail", (failTime - os.time()) * 1000);
	SetFailWarningTimer();
end

function event_signal(e)
	if ( zonePhase > 0 and Cycle.expired(guildCycle, os.time()) ) then EndAttempt(); return end
	if ( e.signal == 11 ) then
		if ( zonePhase == 5 and not forceClose and not phaseAdvancePending ) then
			eq.set_timer("late_reset", 10000);
		end
		return;
	end
	
	if ( e.signal == 1 ) then	-- PoTimeA is requesting to start an instance
	
		local charID, dialNum, raidID, instanceID, charName = Unpacket(e.data);
		charID, dialNum, raidID, instanceID = tonumber(charID), tonumber(dialNum), tonumber(raidID), tonumber(instanceID);
	
		if ( not dialNum or not charID or not raidID or not instanceID ) then
			return
		end
		eq.debug("Instance start requested; charID "..charID.." ("..(charName or "?")..") clicked dial number "..dialNum.." in raid ID "..raidID.." with instance ID "..instanceID);
		
if ( zonePhase == 0 ) then
	local currentGuildID = eq.get_zone_guild_id();
	local guildInstanceID = FindGuildInstance(e.self, currentGuildID);

	if ( guildInstanceID > 0 and guildInstanceID ~= instanceID ) then
		eq.debug(
			"Using guild "..currentGuildID..
			"'s active Time instance "..guildInstanceID..
			" instead of character instance "..instanceID
		);
		instanceID = guildInstanceID;
	end

	if ( instanceID == 0 ) then

eq.debug("zone inactive and player has no instance; creating new instance and notifying PoTimeA");
				instanceID = SetupNewInstance(e.self);
			else
				eq.debug("zone inactive and player has previous instance; using previous instance");
				local qglobals = eq.get_qglobals(POTIMEB_CONTROLLER_TYPE, 223);
				if ( IsRetiredLegacyTimeline(qglobals, instanceID) ) then
					eq.debug("Time instance "..instanceID.." reached its retirement deadline; creating a fresh timeline");
					instanceID = SetupNewInstance(e.self);
					SendSignalRequestConfirm(9, tostring(charID));
				else
					local instanceGuildID = tonumber(qglobals["time_guild_"..instanceID]);
					if ( instanceGuildID ~= nil and instanceGuildID ~= currentGuildID ) then
						eq.debug("Rejected Time instance "..instanceID.." owned by guild zone "..instanceGuildID.." from guild zone "..currentGuildID);
						SendSignalRequestConfirm(8, tostring(charID));
						return;
					end
					local killData = qglobals["time_kills_"..instanceID];
					local timerData = qglobals["time_timers_"..instanceID];
					if ( qglobals["time_cycle_"..instanceID] and (not killData or not timerData) ) then
						eq.debug("Error: Fixed Time cycle is missing saved state; refusing a replacement run.");
						return;
					elseif ( not killData or not timerData ) then
						instanceID = SetupNewInstance(e.self);
					else
						eq.debug("Instance kill data: "..killData);
						eq.debug("Instance timer data: "..timerData);
						eq.debug("current os.time() is "..os.time());
						local generation = qglobals["time_generation_"..instanceID];
						if ( generation ~= nil and not ValidTimeGeneration(generation, instanceID) ) then
							eq.debug("Error: Time instance generation is corrupted! Instance ID: "..instanceID);
							return;
						end
						zoneInstanceGeneration = generation;
						if ( not SetInstanceVars(killData, timerData) or not LoadGuildCycle(qglobals, instanceID) ) then
							eq.debug("Error: Time instance qglobals are corrupted!  Instance ID: "..instanceID);
							return;
						end
					end
				end
			end
			zoneInstanceID = instanceID;
			if ( zoneInstanceID == 0 ) then
				eq.debug("Critical Error: All instance qglobals are in use.");
				return;
			end
			-- Original entry flow: every attempt must complete all five Phase 1
			-- trials together. Saved kills still control shadow loot on retries.
			zonePhase = 1;
			zoneRaidID = raidID;
			phase3Completed = false;
			phaseAdvancePending, forceClose = false, false;
			phaseOneStarted = false;
			emptySince = nil;
			CheckPhaseStatus(1);
			eq.set_timer("cycle_end", math.max(1, guildCycle.ends - os.time()) * 1000);
			SendSignalRequestConfirm(1, charID..";"..dialNum..";"..raidID..";"..instanceID);
			SetInstanceGlobals();
			eq.set_timer("phase1", 45000);
			eq.set_timer("check_trial_start", 2000);
			for i = 1, #trialStates do
				trialStates[i] = 0;
			end

		elseif ( zonePhase > 0 ) then
			eq.debug("Error: Zone already active and PoTimeA requesting new instance.  This shouldn't happen. (zone crash?)  Sending zone state update");
			SendSignalRequestConfirm(4, zoneRaidID..";"..zoneInstanceID..";"..zonePhase);
		end
	
	elseif ( e.signal == 2 ) then		-- confirmation signal from PoTimeA
		signalTries = 0;
		confirmData = nil;
		confirmSignal = 0;
		eq.stop_timer("confirm");
		eq.debug("received confirmation signal from PoTimeA");
	
	elseif ( e.signal == 3 ) then		-- player ID of somebody about to zone over
	
		if ( not e.data or zonePhase < 1 ) then
			return;
		end
		
		local charID, dialNum = Unpacket(e.data, true);
		
		if ( charID and dialNum ) then
			-- keep track of who zoned over via dial and their zone-in time so we can boot the right people when necessary
			AddValidPlayer(charID, dialNum);
			--eq.debug("character ID "..charID.." about to zone over");
		end
	
	elseif ( e.signal == 4 ) then		-- player clicked a door
	
		if ( not e.data ) then
			return;
		end
		
		local doorID, charID = Unpacket(e.data, true);
		DoorClick(doorID, eq.get_entity_list():GetClientByCharID(charID));
	
	elseif ( e.signal == 5 ) then		-- trial completed
	
		local trialNum = tonumber(e.data);
		if ( not trialNum ) then
			return;
		end
		SetTrialCompleted(trialNum);
	
	elseif ( e.signal == 6 ) then		-- boss killed
	
		local phase, bossNum = Unpacket(e.data, true);
		
		if ( not phase or not bossNum ) then
			return;
		end
		
		if ( SetBossKilled(phase, bossNum) ) then
			
			local allDead = true;
			for num, killStatus in ipairs(zoneBossTable[phase]) do
				if ( killStatus == 0 ) then
					allDead = false;
					break;
				end
			end
			
			if ( phase > 3 and allDead ) then
				PhaseDialog();
			end
		end
		
	elseif ( e.signal == 7 ) then		-- phase 2 completed
		if ( zonePhase == 2 ) then
			PhaseDialog();
		end

	elseif ( e.signal == 10 ) then		-- phase 3 final pair defeated in this attempt
		if ( zonePhase == 3 and not phase3Completed and not forceClose and os.time() < failTime ) then
			phase3Completed = true;
			guildCycle.checkpoint = true;
			SetInstanceGlobals();
			PhaseDialog();
		end
		
	elseif ( e.signal == 8 ) then		-- player zoned or logged into combat area

		if ( e.data ) then
		
			local client = eq.get_entity_list():GetClientByID(tonumber(e.data));
			if ( client and client.valid ) then
			
				if ( zonePhase < 1 ) then				
					eq.debug(client:GetName().." zoned or logged in to combat area with zone inactive; moving them to graveyard");
					client:MovePC(223, 851, -141, 396, 0);	-- graveyard
				else
					local charID = client:CharacterID();
					local isValid, zonedFromDial, savedEngagedTime = IsValidCharID(charID);

					if ( isValid ) then
						if ( not lastSavedClientID or lastSavedClientID ~= charID ) then -- prevent redundant saves.  sometimes the 20 second timer saves right before this
							SavePlayerInstance(client);
						end
						
						if ( GetEngagedBossTime() > 0 and not zonedFromDial and bossEngagedTime > 0 ) then
						
							if ( client:FindBuff(756) and client:GetHPRatio() < 25 and client:GetManaRatio() < 5 and client:GetItemHPBonuses() < 100 ) then -- Resurrection Effects
								eq.debug(client:GetName().." resurrected in combat");
								return
							end
							if ( bossEngagedTime > savedEngagedTime ) then								
								eq.debug(client:GetName().." zoned or logged into combat area while boss engaged and having left zone prior to engagement; moving them to graveyard");
								client:MovePC(223, 851, -141, 396, 0);	-- graveyard
							else
								eq.debug(client:GetName().." non-dial zone-in while boss engaged but has current boss timestamp");
							end
						end
					else
						eq.debug(client:GetName().." zoned or logged into combat area and has not been in the raid; moving them to graveyard");
						client:MovePC(223, 851, -141, 396, 0);	-- graveyard
					end
				end
			end
		end
		
	elseif ( e.signal == 9 ) then		-- GM commands
	
		local op, var = Unpacket(e.data, true);
		
		if ( not op ) then
			return;
		end
	
		if ( op == 1 and zonePhase > 0 ) then	-- reset zone now
			forceClose = true;
			eq.set_timer("fail", 1000);
		
		elseif ( op == 2 and zonePhase > 0 ) then	-- reset zone in 120 seconds
			forceClose = true;
			eq.zone_emote(7, "WARNING: Instance is shutting down in two minutes.  Players will be removed from the combat area.");
			eq.set_timer("fail", 120000);
			failTime = os.time() + 120;
		
		elseif ( op == 3 and var and zonePhase > 0 ) then	-- change running instance raid ID
			eq.debug("Previous active instance raid ID was "..zoneRaidID);
			zoneRaidID = var;
			SendSignalRequestConfirm(4, zoneRaidID..";"..zoneInstanceID..";"..zonePhase);
			eq.debug("Active instance raid ID is now "..zoneRaidID);
			
		elseif ( op == 4 and zonePhase == 1 ) then	-- force complete phase 1
			if ( not phaseOneStarted ) then
				SetupPhaseOne();
			end
			for i = 1, 5 do
				SetTrialCompleted(i);
			end
			
		elseif ( op == 5 ) then	-- zone status
			if ( zonePhase == -1 ) then
				eq.debug("zone is cooling down");
			elseif ( zonePhase == 0 ) then
				eq.debug("no instance active; zone is available for use");
			else
				eq.debug("Zone is active.  Instance ID: "..zoneInstanceID..";  Raid ID: "..zoneRaidID..";  Phase: "..zonePhase);
			end
		end
	end
end

function event_timer(e)
	if ( zonePhase > 0 and Cycle.expired(guildCycle, os.time()) ) then EndAttempt(); return end
	if ( e.timer == "cycle_end" ) then
		-- Native timer time and os.time() can cross the second boundary apart.
		-- An early callback must retry the remaining time, not the whole cycle.
		if ( zonePhase > 0 and guildCycle ) then
			eq.set_timer("cycle_end", math.max(1, guildCycle.ends - os.time()) * 1000);
		else
			eq.stop_timer("cycle_end");
		end
		return;
	end
	if ( e.timer == "late_reset" ) then RenewLatePhase(); return end

	if ( e.timer == "check_trial_start" ) then

		TryStartTrials();
		return;
	
	elseif ( e.timer == "pulse" ) then
	
		if ( zonePhase > 0 ) then
			if ( HasSessionPlayers() ) then
				emptySince = nil;
			elseif ( not emptySince ) then
				emptySince = os.time();
			elseif ( os.time() - emptySince >= Cycle.empty_grace ) then
				EndAttempt();
				return;
			end
			local activeClients, regionCounts, countedIDs = CheckValidPlayers();
			
			data = "";
			for i = 1, 8 do
				data = data..tostring(regionCounts[i])..";";
			end
			data = data..tostring(activeClients)..";"..zoneInstanceID..";"..zonePhase.."|"..(countedIDs or "");
			SignalTimeA(5, data);
			
			pulses = pulses + 1;
			if ( pulses == 3 ) then
				eq.debug(string.format("Instance time remaining: %i minutes;  Active clients: %i", math.floor((failTime + 1 - os.time()) / 60), activeClients));
				pulses = 0;
			end
			
			return;
		end	
	
	elseif ( e.timer == "dialog" ) then
		if ( zonePhase < 1 or zonePhase > 5 or not dialog ) then
			eq.stop_timer("dialog");
			return;
		end
		
		eq.zone_emote(0, EMOTE_STRINGS[dialog]);
		if ( dialog == DIALOG_START_STOPS[zonePhase][2] ) then
			PhaseStart();
		else
			dialog = dialog + 1;
			return;
		end
		
	elseif ( e.timer == "fail_warning" ) then
		eq.zone_emote(0, failWarningMsg);
		SetFailWarningTimer();
		return;
	
	elseif ( e.timer == "confirm" ) then
		signalTries = signalTries - 1;
		if ( signalTries < 1 ) then
			eq.debug("Critical error: no response from PoTimeA sending signal "..confirmSignal.."!");
		else
			eq.debug("PoTimeA failed to send signal confirmation");
			SignalTimeA(confirmSignal, confirmData);
			return;
		end
		
	elseif ( e.timer == "fail" ) then
		if ( zonePhase >= 4 and not forceClose ) then
			RenewLatePhase();
			return;
		end
		eq.zone_emote(0, EMOTE_STRINGS[1]);
		eq.set_timer("fail2", 2500);
		
	elseif ( e.timer == "fail2" ) then
		EndAttempt();

	elseif ( e.timer == "phase1" ) then
		if ( zonePhase == 1 ) then
			SetupPhaseOne();
		end
		
	elseif ( e.timer == "cooldown" ) then
		zonePhase = 0;
		DepopZone();
		eq.debug("zone now available");
		
	elseif ( e.timer:find("^trial") ) then
		local _, _, trialNum = e.timer:find("^trial(%d)start$");
		trialNum = tonumber(trialNum);
		if ( trialNum and zonePhase == 1 and trialStates[trialNum] == 1 ) then
			eq.signal(EVENTS_CONTROLLER_TYPE, tonumber("1"..trialNum.."1"), 0, tostring(zoneBossTable[1][trialNum]));
			eq.debug("Trial "..trialNum.." spawned.  Boss status == "..tostring(zoneBossTable[1][trialNum]));
		end
	end
	
	
	eq.stop_timer(e.timer);
end

function SetTrialCompleted(t)
	if ( zonePhase ~= 1 or not trialStates[t] or trialStates[t] == 2 ) then return end
	eq.zone_emote(0, EMOTE_STRINGS[2]);
	trialStates[t] = 2;
	
	if ( zonePhase == 1 and 
	trialStates[1] == 2 and trialStates[2] == 2 and trialStates[3] == 2 and trialStates[4] == 2 and trialStates[5] == 2 ) then
		eq.stop_timer("check_trial_start");
		PhaseDialog();
	end
end

function GetAdditionalHours(phase)
	local hours = 0;

	if ( phase == 2 ) then
		hours = 1;
		
	elseif ( phase == 3 ) then
		hours = 1.25;
		
	elseif ( phase == 4 or phase == 5 ) then
		for _, b in ipairs(zoneBossTable[phase]) do
			if ( b == 0 ) then
				hours = hours + 1;
			end
		end
		
	elseif ( phase == 6 ) then
		hours = 2;	
	end
	return hours;
end

function GetNextPhase()
	-- Early phases must finish in this attempt until the P4 checkpoint is earned.
	if ( zonePhase < 3 and not guildCycle.checkpoint ) then
		CheckPhaseStatus(zonePhase + 1);
		return zonePhase + 1;
	end
	local p = math.max(4, zonePhase + 1);
	for i = p, 6 do
		if ( CheckPhaseStatus(i) ) then
			return i;
		end
	end
	return 0;
end

-- doesn't handle phase 1
function PhaseStart()
	phaseAdvancePending = false;
	zonePhase = GetNextPhase();
	if ( zonePhase == 3 ) then
		phase3Completed = false;
	end
	if ( zonePhase == 0 ) then
		return;
	end
	SendSignalRequestConfirm(4, zoneRaidID..";"..zoneInstanceID..";"..zonePhase);	-- tell potimea that phase has changed
	DoAdditionalHoursEmote(GetAdditionalHours(zonePhase));
	SetFailWarningTimer();

	local data = ""
	for i, b in ipairs(zoneBossTable[zonePhase]) do
		if ( i > 1 ) then
			data = data..";";
		end
		data = data..b;
	end		

	eq.signal(EVENTS_CONTROLLER_TYPE, zonePhase*100+1, 0, data);
end

function PhaseDialog()
	local now = os.time();
	if ( phaseAdvancePending or forceClose or Cycle.expired(guildCycle, now) ) then return end
	
	if ( zonePhase == 6 ) then
		failTime = now + 3598;
		eq.set_timer("fail", (failTime - now)*1000);
		eq.stop_timer("fail_warning");
		eq.stop_timer("fail2");
		SignalTimeA(6, "5");
		eq.debug("Quarm defeated.  Remaining instance time set to 1 hour.");
		return;
	end
	if ( failTime <= now and zonePhase < 4 ) then return end
	local nextPhase = GetNextPhase();
	if ( nextPhase == 0 ) then
		eq.debug("Not advancing phase; bosses in remaining phases have not respawned yet");
		return;
	else
		eq.debug("Phase "..zonePhase.." completed.  Next phase is "..nextPhase);
	end
	
	phaseAdvancePending = true;
	if ( zonePhase == 1 ) then
		eq.stop_timer("phase1");
		eq.stop_timer("check_trial_start");
		for i = 1, 5 do eq.stop_timer("trial"..i.."start") end
	end
	eq.stop_timer("late_reset");
	failTime = math.max(failTime, now) + 3600*GetAdditionalHours(nextPhase);
	eq.set_timer("fail", (failTime - now)*1000);
	SetFailWarningTimer();
	if ( zonePhase == 1 and guildCycle.checkpoint ) then
		eq.zone_emote(0, "Phase 1 is complete. Your saved progress opens the way to Phase "..nextPhase..".");
		PhaseStart();
		return;
	end
	
	eq.set_timer("dialog", 3000);
	dialog = DIALOG_START_STOPS[zonePhase][1];
end

function DoorClick(doorID, client)

	if ( zonePhase > 1 ) then
		-- Phase 1 earth doors
		if ( doorID >= 42 and doorID <= 45 ) then
			OpenDoor(42, client);
			return;
		-- Phase 1 air doors
		elseif ( doorID >= 46 and doorID <= 49 ) then
			OpenDoor(46, client);
			return;
		-- Phase 1 undead doors
		elseif ( doorID >= 29 and doorID <= 32 ) then
			OpenDoor(29, client);
			return;
		-- Phase 1 water doors
		elseif ( doorID >= 25 and doorID <= 28 ) then
			OpenDoor(25, client);
			return;
		-- Phase 1 fire doors
		elseif ( doorID >= 5 and doorID <= 8 ) then
			OpenDoor(5, client);
			return;
		end
		
		if ( zonePhase > 2 ) then
			-- Phase 2 earth/air doors
			if ( doorID >= 38 and doorID <= 41 ) then
				OpenDoor(38, client);
				return;
			-- Phase 2 undead doors
			elseif ( doorID >= 33 and doorID <= 36 ) then
				OpenDoor(33, client);
				return;
			-- Phase 2 water/fire doors
			elseif ( doorID >= 13 and doorID <= 16 ) then
				OpenDoor(13, client);
				return;
			end
			
			local x, y, z, h;
			if ( zonePhase > 3 and doorID == 62 ) then	-- P3 portal to P4 room
				x, y, z, h = -401, 0, 348.75, 64*2;
				
			elseif ( zonePhase > 4 and doorID == 24 ) then	-- P4 room sundial
				x, y, z, h = -419, 0, 3.75, 64*2;
				
			elseif ( zonePhase > 5 and doorID == 51 ) then	-- dial to Quarm				
				x, y, z, h = 251, -1124, 0, 192*2;
				eq.signal(QUARM_TYPE, 1);
			end
			
			if ( x ) then
				client:MovePC(223, x, y, z, h);
				if ( client:GetPet().valid ) then
					client:GetPet():GMMove(x, y, z, 0);
				end
				return;
			end
		end
	end
	
	client:Message(0, "The wall feels both insubstantial and solid at the same time, almost as if you were not in phase with it.");
end

function OpenDoor(doorID, client)
	local entity_list = eq.get_entity_list();
	
	for i = doorID, doorID+3 do
		entity_list:FindDoor(i):ForceOpen(client);
	end
end

function GetEngagedBossTime()
	local npcList = eq.get_entity_list():GetNPCList();
	for npc in npcList.entries do	
		if ( npc.valid and npc:GetMaxHP() > 1000000 and npc:IsEngaged() ) then
			return npc:GetID();
		end
	end
	return 0;
end

function SetupPhaseOne()
	if ( phaseOneStarted or zonePhase ~= 1 or phaseAdvancePending ) then return end
	phaseOneStarted = true;
	eq.stop_timer("phase1");
	if ( guildCycle and guildCycle.checkpoint ) then
		eq.zone_emote(0, "Your guild has already cleared Phase 3 this cycle. After Phase 1 you will continue against the remaining gods.");
	end
	zonePhase = 1;
	failTime = os.time() + 3601;
	eq.set_timer("fail", 3601000);
	SetFailWarningTimer();
	eq.set_timer("pulse", 20000);
	pulses = 0;
end
