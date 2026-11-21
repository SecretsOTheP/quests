local Trash=require("air_trash_retention");
local CASTELLAN_TYPE = 215000; -- A_Castellan_of_Air
local ALRANDERISAN_TYPE = 215383; -- #Constable_Alranderisan
local BELECOHEN_TYPE = 215384; -- #Constable_Belecohen
local FERABALEN_TYPE = 215385; -- #Constable_Ferabalen
local CHAMBERLAIN_TYPE = 215411; -- #Chamberlain_Escalardian
local APPRENTICE_TYPE = 215410; -- #A_Chamberlain`s_Apprentice
local ARMOR_GUY_TYPE = 215418; -- armor_guy

local CASTELLAN_SPAWNIDS = { 365333, 365444, 365629, 365679, 365833, 366093, 366315, 366369, 366414, 366612, 
							366707, 366798, 367079, 367099, 367284 };
local LOCS = {
	[ALRANDERISAN_TYPE] = { 403, 463, -88.5 },
	[BELECOHEN_TYPE] = { 518, 456, -88.5 },
	[FERABALEN_TYPE] = { 461, 498, -85.875 },
};

local signals = {};
local kills = 0;
local spawns = { ALRANDERISAN_TYPE, BELECOHEN_TYPE, FERABALEN_TYPE };
local function RaidContentEnabled()
	local guild_id = eq.get_zone_guild_id();
	return guild_id > 1 or (guild_id == 1 and eq.guild_one_raid_window_open());
end

-- Keep event counters with the retained trash; a controller reload must not
-- count the same clear twice or recreate a constable already killed.
local loaded_cycle=nil;
local final_type,final_dead=0,false;
local function ProgressKey() return "poair-castellan-progress-"..eq.get_zone_guild_id(); end
local function SaveProgress(t)
    if not t or t.first==0 then return; end
    eq.set_data(ProgressKey(),table.concat({t.first,kills,spawns[1],spawns[2],spawns[3],
        signals[2] or 0,signals[3] or 0,signals[4] or 0,final_type,final_dead and 1 or 0},"|"),"172800");
end
local function LoadProgress(t)
    if not t or loaded_cycle==t.first then return; end
    loaded_cycle=t.first;kills=0;signals={};final_type=0;final_dead=false;
    local values={};for v in (eq.get_data(ProgressKey()) or ""):gmatch("[^|]+") do values[#values+1]=tonumber(v);end
    if #values~=10 or values[1]~=t.first or t.first==0 or os.time()>=t.deadline then return; end
    if values[2]<0 or values[2]>15 then return;end
    local valid={[ALRANDERISAN_TYPE]=true,[BELECOHEN_TYPE]=true,[FERABALEN_TYPE]=true};
    for i=3,5 do if not valid[values[i]] then return;end;valid[values[i]]=nil;end
    for i=6,8 do if values[i]~=0 and values[i]~=1 then return;end;end
    if values[9]~=0 and values[9]~=CHAMBERLAIN_TYPE and values[9]~=APPRENTICE_TYPE then return;end
    if values[10]~=0 and values[10]~=1 then return;end
    kills=values[2];spawns={values[3],values[4],values[5]};
    for i=2,4 do if values[i+4]==1 then signals[i]=1;end;end
    final_type,final_dead=values[9],values[10]==1;
end
local function TrashState()
    local t=Trash.new("castellan");
    if t and not t.active then return nil; end
    LoadProgress(t);return t;
end
local function RestorePending()
    local t=TrashState();if not t or os.time()>=t.deadline then return;end
    -- Restore only earned, undefeated NPCs; never reopen the armor loot marker.
    local death_signal={[ALRANDERISAN_TYPE]=2,[BELECOHEN_TYPE]=3,[FERABALEN_TYPE]=4};
    for i,id in ipairs(spawns) do
        if kills>=i*5 and not signals[death_signal[id]] then
            local loc=LOCS[id];eq.unique_spawn(id,0,0,loc[1],loc[2],loc[3],0);
        end
    end
    if final_type~=0 and not final_dead then eq.unique_spawn(final_type,0,0,457,412,-88.622,0);end
end

function RepopIsland()
    local t=TrashState();
    if t and os.time()<t.deadline then
        for _,id in ipairs(CASTELLAN_SPAWNIDS) do
            local p=eq.get_entity_list():GetSpawnByID(id);if p and p.valid then t:Suppress(p:GetNPC());end
        end
        eq.set_timer("castellan_repop",math.max(1,t.deadline-os.time())*1000);
        return;
    end
    final_type,final_dead=0,false;
	local elist = eq.get_entity_list();

	for _, id in ipairs(CASTELLAN_SPAWNIDS) do
		elist:GetSpawnByID(id):Repop();
	end
	
	kills = 0;
	
	for i = 2, 4 do
		signals[i] = nil;
	end

	spawns[1] = eq.ChooseRandom(ALRANDERISAN_TYPE, BELECOHEN_TYPE, FERABALEN_TYPE);
	spawns[2] = nil;
	spawns[3] = nil;
	while ( not spawns[2] ) do
		spawns[2] = eq.ChooseRandom(ALRANDERISAN_TYPE, BELECOHEN_TYPE, FERABALEN_TYPE);
		if ( spawns[2] == spawns[1] ) then
			spawns[2] = nil;
		end
	end
	while ( not spawns[3] ) do
		spawns[3] = eq.ChooseRandom(ALRANDERISAN_TYPE, BELECOHEN_TYPE, FERABALEN_TYPE);
		if ( spawns[3] == spawns[1] or spawns[3] == spawns[2] ) then
			spawns[3] = nil;
		end
	end
    SaveProgress(t);
end

local mode_epoch,mode_active=nil,nil;
local function CheckMode()
    local t=Trash.new("castellan");if not t then return;end
    if mode_epoch~=nil and (mode_epoch~=t.epoch or (mode_active and not t.active)) then
        -- Let the existing event finish; discard only its extended trash timer.
        eq.set_timer("castellan_repop",Trash.NORMAL*1000);
    end
    mode_epoch,mode_active=t.epoch,t.active;
end

function event_spawn(e)
	if ( RaidContentEnabled() ) then
        local t=TrashState();
        if eq.get_zone_guild_id()>1 then CheckMode();eq.set_timer("castellan_mode",30000);end
        eq.set_timer("castellan_repop",t and math.max(1,t.deadline>os.time() and t.deadline-os.time() or Trash.BASE)*1000 or 1080000);
        if t then eq.set_timer("castellan_restore",1000);end
	end
end

function event_timer(e)
	if ( not RaidContentEnabled() ) then
		eq.stop_timer(e.timer);
		return;
	end

    if e.timer=="castellan_mode" then CheckMode();return;end
    if e.timer=="castellan_restore" then eq.stop_timer(e.timer);RestorePending();return;end
	if ( e.timer == "castellan_repop" ) then
		RepopIsland();
	end
end

function event_signal(e)
	if ( not RaidContentEnabled() ) then
		return;
	end

    local t=TrashState();
    if e.signal==5 then
        if t then final_dead=true;SaveProgress(t);end
        return;
    end
	if ( e.signal == 1 ) then
	
        if t and os.time()<t.deadline then
            eq.set_timer("castellan_repop",math.max(1,t.deadline-os.time())*1000);
        elseif ( eq.get_entity_list():IsMobSpawnedByNpcTypeID(CASTELLAN_TYPE) ) then
			eq.set_timer("castellan_repop", 1080000); -- 18 mins
		else
			eq.set_timer("castellan_repop", 10800000); -- 3 hours
		end
		
        if t then
            local count=0;for _ in pairs(t.dead) do count=count+1;end
            if count<=kills then return;end -- duplicate signals cannot earn another named
            kills=count;
        else kills=kills+1;end

		local t, mob;
		if ( kills == 5 ) then
			t = spawns[1];
		elseif ( kills == 10 ) then
			t = spawns[2];
		elseif ( kills == 15 ) then
			t = spawns[3];
		end

		if ( t ) then
			loc = LOCS[t];
			mob = eq.unique_spawn(t, 0, 0, LOCS[t][1], LOCS[t][2], LOCS[t][3], 0);
			if ( mob and mob.valid ) then
				eq.debug(mob:GetCleanName().." spawned");
			end
		end
		
	else
		signals[e.signal] = 1;
		
        if signals[2] and signals[3] and signals[4] and (not t or final_type==0) then
		
			local elist = eq.get_entity_list();
			local mob;
			
			if ( not elist:IsMobSpawnedByNpcTypeID(CHAMBERLAIN_TYPE) and not elist:IsMobSpawnedByNpcTypeID(APPRENTICE_TYPE) ) then
			
				if ( elist:IsMobSpawnedByNpcTypeID(ARMOR_GUY_TYPE) ) then
                    if t then final_type=CHAMBERLAIN_TYPE;end
					mob = eq.spawn2(CHAMBERLAIN_TYPE, 0, 0, 457, 412, -88.622, 0);
				else
                    if t then final_type=APPRENTICE_TYPE;end
					mob = eq.spawn2(APPRENTICE_TYPE, 0, 0, 457, 412, -88.622, 0);
				end
				if ( mob and mob.valid ) then
					eq.debug(mob:GetCleanName().." spawned");
				end
			end

		end
	end
    SaveProgress(t);
end
