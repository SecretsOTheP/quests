-- Guild-instance Air rings. Guild 1 keeps the encounter files' quake path.
-- Only confirmed deaths advance stages; missing/failed spawns are retried.
local M = {};
local PULSE = "air_ring_recovery";
local CYCLE = 237600; -- existing 66-hour island repop
local IDLE = 9000; -- existing 2.5-hour Avatar budget, paused in combat
local configs = {
    Wind = {controller=215420, marker=215414, boss=215390, ph=215425, avatar=215391,
        avatar_loc={-1591,484,15,192}, ph_loc={-369,-627,105.75,201},
        natives={215013,215002,215014}, tracked={215386,215387,215388,215389,215390,215424,215425,215391}, offset=1},
    Smoke = {controller=215421, marker=215415, boss=215396, ph=215427, avatar=215392,
        avatar_loc={1396,-680,18,0}, boss_loc={-445,-1284,323,0},
        natives={215012,215039}, tracked={215395,215447,215448,215449,215396,215427,215392}, offset=2},
    Mist = {controller=215423, marker=215416, boss=215399, ph=215429, avatar=215393,
        avatar_loc={-1573,-570,356.125,192}, boss_loc={326,-718,441,128},
        natives={215026,215450,215027,215058,215028,215324}, tracked={215397,215398,215399,215429,215393}, offset=3},
    Dust = {controller=215422, marker=215417, boss=215375, ph=215428, avatar=215394,
        avatar_loc={1671,527,344,192}, boss_loc={-400,889,433.6,131}, boss_point=366131,
        natives={215043,215044,215045,215060}, tracked={215400,215401,215375,215428,215394}, offset=4}
};
local valid_phases = {island=true, priest=true, traps=true, champions=true, fire=true,
    wind=true, arch1=true, arch2=true, arch3=true, adds1=true, adds2=true, adds3=true,
    boss=true, avatar=true, cooldown=true, failed=true};

local function live(n)
    return n and n.valid and n:GetID() ~= 0 and n:GetHP() > 0 and not n:IsCorpse();
end
local function count(t) local n=0; for _ in pairs(t) do n=n+1; end; return n; end
local function list(t)
    local out={}; for k in pairs(t) do out[#out+1]=tostring(k); end
    table.sort(out); return table.concat(out,",");
end
local function parse_list(text, numeric)
    local result={};
    for value in text:gmatch("[^,]+") do
        if not value:match("^[%w_]+$") then return nil; end
        local key=numeric and tonumber(value) or value;
        if not key then return nil; end
        result[key]=true;
    end
    return result;
end
local function parse_position(text)
    local values={};
    for value in text:gmatch("[^,]+") do
        local n=tonumber(value); if not n or n~=n or math.abs(n)>1000000 then return nil; end
        values[#values+1]=n;
    end
    if #values~=3 then return nil; end
    values[4]=0; return values;
end

function M.install(name, opts)
    if eq.get_zone_guild_id() <= 1 then return; end
    local c = assert(configs[name]);
    local key = "poair-ring-v1-"..name:lower().."-"..eq.get_zone_guild_id();
    local s, initialized, controller, busy, missing = nil, false, nil, false, {};
    local check_zone_restore, controller_bound=false, false;
    local erratics_enabled, inherited_hate = nil, {};
    local move={-452,640,437.576};
    local island={}; for _, id in ipairs(opts.island) do island[id]=true; end
    local tag="air_"..name:lower();
    local function debug(text) eq.debug("Air "..name.." guild="..eq.get_zone_guild_id()..": "..text); end
    local function find(npc_type) return eq.get_entity_list():GetNPCByNPCTypeID(npc_type); end
    local function point(id) return eq.get_entity_list():GetSpawnByID(id); end
    local function tagged(n)
        return n and n.valid and n:GetEntityVariable(tag.."_cycle") == tostring(s.cycle);
    end
    local function save()
        local fields={"1",s.cycle,s.phase,s.deadline,s.stage_at,s.dust_end,s.remaining,
            s.clock,s.paused,s.consumed,s.real,s.position,list(s.island),list(s.dead),s.traps,s.add_loc};
        for i=1,12 do fields[i]=tostring(fields[i]); end
        -- Longer than the existing event cycle; absolute timestamps, not TTL,
        -- decide whether an attempt or cooldown has expired.
        eq.set_data(key,table.concat(fields,"|"),"604800");
    end
    local function new_state(cycle, delay)
        local now=os.time();
        return {cycle=cycle,phase="island",deadline=now+delay,stage_at=now,dust_end=0,
            remaining=0,clock=now,paused=0,consumed=0,real=0,position=1,island={},dead={},traps="",add_loc="-452,640,437.576"};
    end
    local function load()
        if initialized then return; end
        initialized=true;
        local raw=eq.get_data(key) or "";
        local f={}; for field in (raw.."|"):gmatch("(.-)|") do f[#f+1]=field; end
        local valid=#f==16 and f[1]=="1" and valid_phases[f[3]];
        if valid then
            for _,i in ipairs({2,4,5,6,7,8,9,10,11,12}) do
                f[i]=tonumber(f[i]);
                if not f[i] or f[i]<0 or f[i]~=math.floor(f[i]) then valid=false; end
            end
        end
        local native=valid and parse_list(f[13],true);
        local dead=valid and parse_list(f[14],false);
        if valid and native and dead and f[7]<=IDLE and f[9]<=1 and f[10]<=1 and f[11]<=1
            and f[12]>=1 and f[12]<=5 then
            for id in pairs(native) do if not island[id] then valid=false; end end
            if f[15]~="" and not f[15]:match("^%-?%d+,%-?%d+;%-?%d+,%-?%d+;%-?%d+,%-?%d+;%-?%d+,%-?%d+$") then valid=false; end
            local p=f[3];
            if (p=="priest" or p=="traps") and name~="Wind" then valid=false; end
            if p=="champions" and name~="Smoke" then valid=false; end
            if (p=="fire" or p=="wind") and name~="Mist" then valid=false; end
            if (p:match("^arch") or p:match("^adds")) and name~="Dust" then valid=false; end
            if p=="traps" and f[15]=="" then valid=false; end
            if not parse_position(f[16]) then valid=false; end
        else valid=false; end
        if valid then
            s={cycle=f[2],phase=f[3],deadline=f[4],stage_at=f[5],dust_end=f[6],remaining=f[7],
                clock=f[8],paused=f[9],consumed=f[10],real=f[11],position=f[12],island=native,dead=dead,traps=f[15],add_loc=f[16]};
            check_zone_restore=true;
            if s.phase=="avatar" then
                local avatar=find(c.avatar);
                -- A quest reload preserves an engaged NPC. An unloaded zone
                -- has no ongoing combat, so time since the last save is idle.
                if not (s.paused==1 and live(avatar) and tagged(avatar) and avatar:IsEngaged()) then
                    s.remaining=math.max(0,s.remaining-math.max(0,os.time()-s.clock));
                    s.paused=0;
                end
                s.clock=os.time(); save();
            end
            debug("restored "..s.phase.."; island reset remaining "..math.max(0,s.deadline-os.time()).." seconds");
        else
            if raw~="" then debug("invalid saved state; using a fresh island cycle"); end
            s=new_state(os.time(),1080+c.offset); save();
        end
    end
    local function enable_erratics(on)
        if name~="Dust" then return; end
        on=not not on;
        if erratics_enabled==on then return; end
        erratics_enabled=on;
        for _,id in ipairs(opts.erratic) do
            local p=point(id);
            if p and p.valid then if on then p:Enable(); else p:Disable(); end end
        end
        if not on then eq.depop_all(215402); end
    end
    local function active_dust()
        return name=="Dust" and (s.phase:match("^arch") or s.phase:match("^adds") or (s.phase=="boss" and s.real==1));
    end
    local function unlock(n, body)
        n:SetSpecialAbility(24,0); n:SetSpecialAbility(25,0); n:SetSpecialAbility(35,0);
        n:SetBodyType(body or 1,false);
    end
    local function transition(phase)
        s.phase=phase; s.stage_at=os.time();
        if phase=="boss" then
            s.real=live(find(c.marker)) and 1 or 0;
            if name=="Dust" then s.real=live(find(c.boss)) and 1 or 0; s.dust_end=0; end
            if name=="Wind" then s.position=math.random(1,#opts.bosses); end
        elseif phase=="avatar" then
            s.remaining=IDLE; s.clock=os.time(); s.paused=0;
        elseif phase=="traps" then
            local positions={};
            for i=1,4 do positions[i]=math.random(-589,-169)..","..math.random(-842,-498); end
            s.traps=table.concat(positions,";");
        end
        save(); debug("stage "..phase);
    end
    local function expected()
        local rows={};
        local function add(role, npc_type, loc, extra)
            rows[#rows+1]={role=role,npc_type=npc_type,loc=loc,extra=extra};
        end
        if s.phase=="island" or s.phase=="champions" then
            if name=="Smoke" then
                for _,threshold in ipairs({5,10,15,21}) do
                    local v=opts.champions[threshold];
                    if count(s.island)>=threshold then add("champ"..threshold,v[1],{v[2],v[3],v[4],v[5]},"champ"); end
                end
            end
        elseif s.phase=="priest" then
            add("priest",215387,{-259,-677,115,211});
            for i,v in ipairs(opts.menacing) do add("menacing"..i,215386,{v[1],v[2],v[3],0},i); end
        elseif s.phase=="traps" then
            local locations={};
            for x,y in s.traps:gmatch("(%-?%d+),(%-?%d+)") do locations[#locations+1]={tonumber(x),tonumber(y),115,0}; end
            for i=1,4 do
                -- Fixed slots make each trap's replacement independently recoverable.
                local loc=locations[i];
                if s.dead["trap"..i] then add("sporadic"..i,215388,loc);
                else add("trap"..i,215424,loc); end
            end
        elseif s.phase=="fire" or s.phase=="wind" then
            for i,loc in ipairs(opts.surgers) do add(s.phase..i,s.phase=="fire" and 215397 or 215398,loc); end
        elseif s.phase:match("^arch") then
            add(s.phase,215400,{-452,640,437.576,10});
        elseif s.phase:match("^adds") then
            for i=1,3 do add(s.phase.."_"..i,215401,parse_position(s.add_loc)); end
        elseif s.phase=="boss" then
            if name=="Wind" and s.real==1 then
                for i,loc in ipairs(opts.bosses) do add(i==s.position and "boss" or ("fake"..i),i==s.position and c.boss or 215389,loc); end
            else
                add("boss",s.real==1 and c.boss or c.ph,(name=="Wind" and c.ph_loc or c.boss_loc),
                    name=="Dust" and s.real==1 and "native" or nil);
            end
        elseif s.phase=="avatar" and s.remaining>0 then
            add("avatar",c.avatar,c.avatar_loc);
        end
        return rows;
    end
    local function owned_npcs()
        local result={};
        for n in eq.get_entity_list():GetNPCList().entries do
            if live(n) and tagged(n) then result[#result+1]=n; end
        end
        return result;
    end
    local function cleanup(rows)
        local wanted={};
        for _,row in ipairs(rows) do if not s.dead[row.role] then wanted[row.role]=true; end end
        for _,n in ipairs(owned_npcs()) do
            if not wanted[n:GetEntityVariable(tag.."_role")] then n:Depop(false); end
        end
    end
    local function avatar_clock()
        if s.phase~="avatar" then return; end
        local now=os.time();
        if s.paused==0 then s.remaining=math.max(0,s.remaining-math.max(0,now-s.clock)); end
        s.clock=now;
    end
    local function reset_island()
        cleanup({}); enable_erratics(false);
        for _,id in ipairs(opts.island) do local p=point(id); if p and p.valid then p:Repop(); end end
        if name=="Dust" and (live(find(c.boss)) or live(find(c.marker))) then
            local p=point(c.boss_point); if p and p.valid then p:Repop(); end
        end
        s=new_state(math.max(os.time(),s.cycle+1),1080); missing={}; save();
        debug("island reset; new 18-minute clearing window");
    end
    local function ensure()
        if busy then return; end
        busy=true;
        load(); avatar_clock();
        if check_zone_restore then
            check_zone_restore=false;
            local same_zone=live(controller) and controller:GetEntityVariable(tag.."_controller_cycle")==tostring(s.cycle);
            -- Reloaded quests keep the controller and its entity variables.
            -- A fresh zone resets unfinished rings instead of replaying waves.
            -- Earned Avatars and completed cooldowns are preserved separately.
            if not same_zone and s.phase~="avatar" and s.phase~="cooldown" then
                reset_island();
                debug("zone unload interrupted the ring; reset for a fresh attempt");
            end
        end
        if s.phase=="avatar" and s.remaining<=0 then transition("cooldown"); end
        if s.dust_end>0 and os.time()>=s.dust_end then
            s.dust_end=0; transition("failed");
            debug("one-hour wave deadline expired; spiders disabled, existing island reset retained");
        end
        if os.time()>=s.deadline and s.phase~="avatar" then reset_island(); end
        local rows=expected(); cleanup(rows);
        enable_erratics(active_dust());
        local present={};
        for _,n in ipairs(owned_npcs()) do present[n:GetEntityVariable(tag.."_role")]=n; end
        for _,row in ipairs(rows) do
            if not s.dead[row.role] then
                local n=present[row.role]; local fresh=false;
                if not live(n) then
                    if row.extra=="native" then
                        n=find(c.boss);
                        if not live(n) then
                            local p=point(c.boss_point); if p and p.valid then p:Repop(); end
                            n=nil; -- Spawn2 repop is asynchronous; confirm it next tick.
                        end
                    elseif row.role=="avatar" then
                        n=eq.unique_spawn(row.npc_type,0,0,unpack(row.loc));
                    else
                        n=eq.spawn2(row.npc_type,0,0,unpack(row.loc));
                    end
                    fresh=live(n);
                    if fresh then
                        n:SetEntityVariable(tag.."_cycle",tostring(s.cycle));
                        n:SetEntityVariable(tag.."_role",row.role);
                    end
                end
                if live(n) then
                    missing[row.role]=nil;
                    if row.extra=="champ" and s.phase=="champions" then unlock(n); end
                    if row.extra=="native" then unlock(n,21); n:ChangeSize(16); end
                    if fresh and s.phase=="priest" and type(row.extra)=="number" then
                        local v=opts.menacing[row.extra]; n:CastToNPC():MoveTo(v[4],v[5],v[6],v[7],true);
                        eq.set_timer("wake",math.max(1,(s.stage_at+math.ceil(row.extra/2)*60-os.time())*1000),n);
                    end
                    if fresh and row.npc_type==215401 then
                        for _,client in ipairs(inherited_hate) do if client.valid then n:AddToHateList(client,1); end end
                    end
                    if row.role=="avatar" then
                        if s.consumed==0 then
                            local marker=find(c.marker);
                            if live(marker) then eq.depop_with_timer(c.marker); end
                            s.consumed=1; save();
                            debug("Avatar confirmed; availability marker consumed");
                        end
                        if fresh then
                            -- Spawn handlers set the stock timer; restore only its remainder.
                            eq.set_timer("depop",math.max(1,s.remaining*1000),n);
                        end
                    end
                elseif not missing[row.role] then
                    missing[row.role]=true; debug("spawn missing for "..row.role.."; retrying without advancing");
                end
            end
        end
        if name=="Dust" and s.phase=="island" then
            local n=find(c.boss);
            if live(n) then n:ChangeSize(3+math.floor(count(s.island)/3)); end
        end
        if s.phase=="avatar" then save(); end
        if live(controller) then controller:SetEntityVariable(tag.."_controller_cycle",tostring(s.cycle)); end
        busy=false;
    end
    local function start(e)
        controller=e and e.self or find(c.controller);
        load();
        if live(controller) then
            if controller_bound and controller:GetEntityVariable(tag.."_controller_cycle")~=tostring(s.cycle) then
                check_zone_restore=true;
            end
            controller_bound=true;
            eq.set_timer(PULSE,1000,controller);
        end
        -- Defer one tick so all native spawnpoints have finished loading.
    end
    local function timer(e)
        if e.timer~=PULSE then return; end
        controller=e.self; ensure();
        local delay=30;
        if s.phase~="avatar" then delay=math.min(delay,s.deadline-os.time()); end
        if s.dust_end>0 then delay=math.min(delay,s.dust_end-os.time()); end
        if s.phase=="avatar" and s.paused==0 then delay=math.min(delay,s.remaining); end
        eq.set_timer(PULSE,math.max(1,delay*1000),controller);
    end
    local function all_dead(prefix, n)
        for i=1,n do if not s.dead[prefix..i] then return false; end end
        return true;
    end
    local function island_death(e)
        load();
        local id=e.self:GetSpawnPointID();
        if s.phase~="island" or not island[id] or e.self:GetEntityVariable(tag.."_native_counted")~="" then return; end
        e.self:SetEntityVariable(tag.."_native_counted",tostring(s.cycle));
        s.island[id]=true; move={e.self:GetX(),e.self:GetY(),e.self:GetZ()};
        s.deadline=os.time()+1080;
        local cleared=true;
        for _,pid in ipairs(opts.island) do
            local p=point(pid);
            if not p or not p.valid or live(p:GetNPC()) then cleared=false; break; end
        end
        -- Smoke requires all 21 actual island deaths, not unrelated elementals.
        if name=="Smoke" and count(s.island)~=#opts.island then cleared=false; end
        if cleared then
            s.deadline=os.time()+CYCLE;
            if name=="Wind" then transition("priest");
            elseif name=="Smoke" then transition("champions");
            elseif name=="Mist" then transition("fire");
            else s.dust_end=os.time()+3600; transition("arch1"); end
        else save(); end
        ensure();
    end
    local function stage_death(e)
        load();
        if not tagged(e.self) then return; end
        local role=e.self:GetEntityVariable(tag.."_role");
        if s.dead[role] then return; end
        local expected_now=false;
        for _,row in ipairs(expected()) do if row.role==role and row.npc_type==e.self:GetNPCTypeID() then expected_now=true; end end
        if not expected_now then return; end
        s.dead[role]=true;
        if s.phase=="priest" and role=="priest" then transition("traps");
        elseif s.phase=="traps" and all_dead("sporadic",4) then transition("boss");
        elseif s.phase=="champions" and s.dead.champ5 and s.dead.champ10 and s.dead.champ15 and s.dead.champ21 then transition("boss");
        elseif s.phase=="fire" and all_dead("fire",4) then transition("wind");
        elseif s.phase=="wind" and all_dead("wind",4) then transition("boss");
        elseif s.phase:match("^arch") and role==s.phase then
            s.add_loc=e.self:GetX()..","..e.self:GetY()..","..e.self:GetZ();
            transition("adds"..s.phase:sub(-1));
        elseif s.phase:match("^adds") and all_dead(s.phase.."_",3) then
            local round=tonumber(s.phase:sub(-1));
            if round<3 then transition("arch"..(round+1)); else transition("boss"); end
        elseif s.phase=="boss" and role=="boss" then
            transition(s.real==1 and "avatar" or "cooldown");
        elseif s.phase=="avatar" and role=="avatar" then transition("cooldown");
        else save(); end
        ensure();
        inherited_hate={};
    end
    local function trap_combat(e)
        if not e.joined then return; end
        load(); if s.phase~="traps" or not tagged(e.self) then return; end
        local role=e.self:GetEntityVariable(tag.."_role");
        if not role:match("^trap[1-4]$") or s.dead[role] then return; end
        s.dead[role]=true; save(); ensure();
    end
    local function avatar_combat(e)
        load();
        if e.self:GetNPCTypeID()==c.avatar and s.phase=="avatar" and tagged(e.self) then
            avatar_clock(); s.paused=e.joined and 1 or 0; save();
        end
        opts.combat(e);
    end
    local function avatar_timer(e)
        if e.timer=="depop" then
            load();
            if s.phase=="avatar" and tagged(e.self) then s.remaining=0; transition("cooldown"); end
        end
        opts.avatar_timer(e);
    end
    local function menacing_timer(e)
        if e.timer=="wake" then
            eq.stop_timer("wake"); unlock(e.self); e.self:SetRunning(true); eq.set_timer("move",10000);
        end
        if not e.self:IsEngaged() then
            local priest=find(215387);
            local loc=move;
            if live(priest) and priest:IsEngaged() then loc={priest:GetX(),priest:GetY(),priest:GetZ()}; end
            e.self:CastToNPC():MoveTo(loc[1],loc[2],loc[3],-1,false);
        end
    end
    local function erratic_spawn(e)
        e.self:MoveTo(move[1],move[2],move[3],-1,false); eq.set_timer("move",10000);
    end
    local function erratic_timer(e)
        load();
        if not active_dust() then e.self:Depop(false); return; end
        if not e.self:IsEngaged() then
            local boss=find(s.phase=="boss" and c.boss or 215400);
            if live(boss) and boss:IsEngaged() then e.self:CastToNPC():MoveTo(boss:GetX(),boss:GetY(),boss:GetZ()-3,-1,false); end
        end
    end
    local function reg(event,npc,callback)
        -- The server replaces this encounter's handler for this event/NPC.
        eq.register_npc_event(name,event,npc,callback);
    end
    reg(Event.spawn,c.controller,start); reg(Event.timer,c.controller,timer);
    reg(Event.signal,c.controller,function() end); -- deaths are accounted directly
    for _,npc in ipairs(c.natives) do
        -- Mist's wizard retains its separate Ardent spawn on EVENT_DEATH.
        if not (name=="Mist" and npc==215450) then reg(Event.death,npc,function() end); end
        reg(Event.death_complete,npc,island_death);
    end
    for _,npc in ipairs(c.tracked) do
        reg(Event.death,npc,function() end); reg(Event.death_complete,npc,stage_death);
    end
    reg(Event.combat,c.avatar,avatar_combat); reg(Event.timer,c.avatar,avatar_timer);
    if name=="Wind" then reg(Event.combat,215424,trap_combat); reg(Event.timer,215386,menacing_timer); end
    if name=="Dust" then
        reg(Event.death,215400,function(e)
            inherited_hate={};
            for entry in e.self:GetHateList().entries do
                if entry.ent and entry.ent.valid and entry.ent:IsClient() then inherited_hate[#inherited_hate+1]=entry.ent; end
            end
        end);
        reg(Event.spawn,215402,erratic_spawn); reg(Event.timer,215402,erratic_timer);
        reg(Event.spawn,c.marker,function()
            load();
            if s.phase~="avatar" and s.phase~="boss" then local p=point(c.boss_point); if p and p.valid then p:Repop(); end end
        end);
    end
    -- A quest reload has no new controller spawn event.
    start({self=find(c.controller)});
end

return M;
