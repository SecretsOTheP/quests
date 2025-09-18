
function CorbinWaypoint(e)
	if(e.wp == 2) then
		e.self:Say("Almost there now, just a bit further...");
	elseif(e.wp == 3) then
		e.self:Say("Uh oh, looks like they were tipped off somehow... I hope you can handle them.");
		eq.spawn2(116029,18,0,-2366,-428,205,0); -- Commander_Bahreck
		eq.spawn2(116030,19,0,-2364,-448,205,0); -- Ry`Gorr_Basher
		eq.spawn2(116030,19,0,-2392,-436,205,0); -- Ry`Gorr_Basher
		eq.spawn2(116129,19,0,-1756,-951,220,0); -- Kromrif_Soldier
		eq.spawn2(116129,19,0,-1780,-935,220,0); -- Kromrif_Soldier
		eq.spawn2(116030,19,0,-1808,-952,215,0); -- Ry`Gorr_Basher
		eq.spawn2(116030,19,0,-1512,-244,186,0); -- Ry`Gorr_Basher
		eq.spawn2(116030,19,0,-1487,-262,188,0); -- Ry`Gorr_Basher
	elseif(e.wp == 5) then
		e.self:Say("Well, you're a bit tougher than I had given you credit for. I owe you my life, friend. The camp is right over here.");
	elseif(e.wp == 6) then
		eq.unique_spawn(116035,0,0,-3188,-574,158,62); -- NPC: #Dobbin_Crossaxe
	elseif(e.wp == 7) then
		e.self:Say("I have escaped! With the help of our friends here I was saved from certain death. We are in their debt.");
		if(eq.get_entity_list():IsMobSpawnedByNpcTypeID(116035)) then
			eq.get_entity_list():GetMobByNpcTypeID(116035):Say("We thought it was too late, the Dain will be very pleased!");
		end	
	elseif(e.wp == 8)then
		if(eq.get_entity_list():IsMobSpawnedByNpcTypeID(116035)) then
			eq.get_entity_list():GetMobByNpcTypeID(116035):Say("Please friend, show me your Mithril ring and I will show you our gratitude.");
		end			
	end
end

function CommanderSpawn(e)
	eq.set_timer("depop_commander",3600000);
	e.self:SetRunning(true);
end

function CommanderTimer(e)
	if(e.timer == "depop_commander") then
		eq.depop();
	end
end

function CommanderCombat(e)
	if(e.joined) then
		if(not eq.is_paused_timer("depop_commander")) then
			eq.pause_timer("depop_commander");
		end
	else
		eq.resume_timer("depop_commander");
	end
end

function SoldierSpawn(e)
	eq.set_timer("depop_soldier",3600000);
	e.self:SetRunning(true);
end

function SoldierTimer(e)
	if(e.timer == "depop_soldier") then
		eq.depop();
	end
end

function SoldierCombat(e)
	if(e.joined) then
		if(not eq.is_paused_timer("depop_soldier")) then
			eq.pause_timer("depop_soldier");
		end
	else
		eq.resume_timer("depop_soldier");
	end
end


function BasherSpawn(e)
	eq.set_timer("depop_basher",3600000);
	e.self:SetRunning(true);
end

function BasherTimer(e)
	if(e.timer == "depop_basher") then
		eq.depop();
	end
end

function BasherCombat(e)
	if(e.joined) then
		if(not eq.is_paused_timer("depop_basher")) then
			eq.pause_timer("depop_basher");
		end
	else
		eq.resume_timer("depop_basher");
	end
end

function CommanderWaypoint(e)
	if(e.wp == 1) then
		e.self:SetRunning(false);
	elseif(e.wp == 8) then
		e.self:SetRunning(true);
	end
end

function SoldierWaypoint(e)
	if(e.wp == 1) then
		e.self:SetRunning(false);
	elseif(e.wp == 9) then
		e.self:SetRunning(true);
	end
end

function BasherWaypoint(e)
	if(e.wp == 1) then
		e.self:SetRunning(false);
	elseif(e.wp == 9) then
		e.self:SetRunning(true);
	end
end

function event_encounter_load(e)
	eq.register_npc_event("ringseven", Event.waypoint_arrive, 116034, CorbinWaypoint);
	eq.register_npc_event("ringseven", Event.spawn, 116029, CommanderSpawn);
	eq.register_npc_event("ringseven", Event.spawn, 116129, SoldierSpawn);
	eq.register_npc_event("ringseven", Event.spawn, 116030, BasherSpawn);
	eq.register_npc_event("ringseven", Event.waypoint_arrive, 116029, CommanderWaypoint);
	eq.register_npc_event("ringseven", Event.timer, 116029, CommanderTimer);
	eq.register_npc_event("ringseven", Event.combat, 116029, CommanderCombat);
	eq.register_npc_event("ringseven", Event.waypoint_arrive, 116129, SoldierWaypoint);
	eq.register_npc_event("ringseven", Event.timer, 116129, SoldierTimer);
	eq.register_npc_event("ringseven", Event.combat, 116129, SoldierCombat);
	eq.register_npc_event("ringseven", Event.waypoint_arrive, 116030, BasherWaypoint);
	eq.register_npc_event("ringseven", Event.timer, 116030, BasherTimer);
	eq.register_npc_event("ringseven", Event.combat, 116030, BasherCombat);
end
