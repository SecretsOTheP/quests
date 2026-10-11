-- Lua 5.1: lua tests/pok_library_setup_test.lua .
local root = assert(arg[1], "quest root required");
package.path = root .. "/lua_modules/?.lua;" .. package.path;
local checks = 0;
local function check(ok, message) assert(ok, message); checks = checks + 1; end
local npcs, points, handlers, timers, logs, created;
local serial = 0;
Event = {say=1, trade=2};
local function npc(spec, x, y, z)
    serial = serial + 1;
    local n = {valid=true, spec=spec, x=x, y=y, z=z, vars={}, id=serial};
    function n:GetNPCTypeID() return self.spec.npc_id; end
    function n:GetCleanName() return self.spec.name:gsub("_", " "); end
    function n:GetEntityVariable(key) return self.vars[key] or ""; end
    function n:SetEntityVariable(key, value) self.vars[key] = value; end
    function n:Depop() self.depop = true; end
    function n:GetX() return self.x; end
    function n:GetY() return self.y; end
    function n:GetZ() return self.z; end
    npcs[#npcs+1] = n;
    return n;
end
local function flush()
    for i=#npcs,1,-1 do
        if npcs[i].depop then table.remove(npcs,i); end
    end
end
local function point(id, group, current)
    local p = {valid=true, enabled=true};
    function p:SpawnGroupID() return group; end
    function p:CurrentNPCID() return current; end
    function p:Disable(depop) check(depop==false,"prototype disable must not force-depop others"); self.enabled=false; end
    points[id] = p;
    return p;
end
local function reset(supported)
    npcs, points, handlers, timers, logs, created = {}, {}, {}, {}, {}, {};
    local entities = {};
    function entities:GetNPCList()
        local snapshot = {}; for i,n in ipairs(npcs) do snapshot[i]=n; end
        local i=0;
        return {entries=function() i=i+1; return snapshot[i]; end};
    end
    function entities:GetSpawnByID(id) return points[id] or {valid=false}; end
    eq = {
        debug=function(text) logs[#logs+1]=text; end,
        get_entity_list=function() return entities; end,
        set_timer=function(name,ms,e) check(e=="encounter","timer needs encounter owner"); timers[name]=ms; end,
        stop_timer=function(name,e) check(e=="encounter","stop timer needs encounter owner"); timers[name]=nil; end,
        register_npc_event=function(enc,event,id,fn)
            check(enc=="LibraryPhysicists","wrong encounter");
            handlers[id]=handlers[id] or {};
            check(not handlers[id][event],"duplicate event registration"); handlers[id][event]=fn;
        end,
        create_npc=function() error("unsafe legacy API called"); end
    };
    if supported then
        eq.create_npc_from_table=function(spec,x,y,z,h)
            created[#created+1]={spec=spec,x=x,y=y,z=z,h=h};
            return npc(spec,x,y,z);
        end;
    end
end
local function load()
    handlers, timers = {}, {};
    local env=setmetatable({}, {__index=_G});
    local chunk=assert(loadfile(root .. "/poknowledge/encounters/LibraryPhysicists.lua"));
    setfenv(chunk,env); chunk(); env.event_encounter_load({encounter="encounter"});
    return function() env.event_timer({timer="maintain"}); flush(); end, env;
end

reset(false);
local tick=load();
check(#npcs==0 and next(timers)==nil and next(handlers)==nil,"old server must stop without unsafe calls");
check(#logs==1 and logs[1]:find("Server update required",1,true),"old server needs useful diagnostic");

reset(true);
local tick,env=load();
check(timers.initialize==1000 and timers.maintain==5000,"startup and recovery timers");
env.event_timer({timer="initialize"});
check(timers.initialize==nil and #npcs==2 and #created==2,"empty DB creates both NPCs");
local first,second=npcs[1],npcs[2];
check(first.spec.name=="Gork,_Theoretical_Physicist" and second.spec.name=="Mork,_Applied_Physicist","roles in names");
check(first.spec.luclinface==4 and first.spec.helmtexture==0 and second.spec.helmtexture==3,"approved faces and helmet");
for _,c in ipairs(created) do
    check(c.spec.race==10 and c.spec.size==7.5 and c.spec.chesttexture==1 and c.spec.feettexture==1,"ogre clothing");
    check(c.spec.loottable_id==0 and c.spec.loot_lockout==0 and c.spec.skip_global_loot==true,"no loot or lockouts");
    check(c.spec.runspeed==0 and c.spec.merchanttype==0 and c.h==157,"stationary non-merchant with heading");
end
check(created[1].x==949 and created[1].y==25 and created[1].z==3.4,"lower NPC landing");
check(created[2].x==948 and created[2].y==44 and created[2].z==389.4,"upper NPC landing");
-- Exercise actual registered callbacks, including loop capture and ownership.
for _,case in ipairs({{first,"up",389.4},{second,"down",3.4}}) do
    local c={moves=0};
    function c:GetX() return case[1].x; end
    function c:GetY() return case[1].y; end
    function c:GetZ() return case[1].z; end
    function c:Message() end
    function c:MovePC(zone,x,y,z,h) self.moves=self.moves+1; self.z=z; end
    handlers[case[1]:GetNPCTypeID()][Event.say]({self=case[1],other=c,message=case[2]});
    check(c.moves==1 and c.z==case[3],"registered dialogue must use correct NPC and direction");
end
for i=1,3 do tick(); end
check(#npcs==2 and #created==2,"repeat checks do not duplicate");
tick=load(); tick();
check(#created==2 and npcs[1]==first and npcs[2]==second,"quest reload adopts existing owned NPCs");
first:Depop(); flush(); tick();
check(#npcs==2 and #created==3,"missing NPC recreated individually");
npcs={}; tick();
check(#npcs==2 and #created==5,"zone repop restores both");

reset(true);
local p1=point(7151301,7151301,7151301);
local p2=point(7151302,7151302,7151302);
npc({npc_id=7151301,name="Gork"},949,25,3.4);
npc({npc_id=7151302,name="Mork,_Applied_Physicist"},948,44,389.4);
tick=load(); tick();
check(#npcs==0 and #created==0 and not p1.enabled and not p2.enabled,"legacy prototypes retire before replacements");
tick(); check(#npcs==2 and #created==2,"legacy SQL rows do not prevent automatic creation");
-- Simulate a native spawn appearing late, alongside its automatic replacement.
npc({npc_id=7151301,name="Gork,_Theoretical_Physicist"},949,25,3.4);
tick(); check(#npcs==2 and #created==2,"late native spawn removed without replacing keeper");
local duplicate=npc(npcs[1].spec,949,25,3.4); duplicate:SetEntityVariable("library_physicist_v1","1");
tick(); check(#npcs==2,"duplicate owned entity removed");

reset(true);
local foreign=npc({npc_id=7151301,name="Unrelated_NPC"},0,0,0);
local foreign_point=point(7151301,999,7151301);
tick=load(); tick(); tick();
check(not foreign.depop and foreign_point.enabled,"foreign entity and point untouched");
check(#npcs==2 and #created==1 and #logs==1,"ID conflict skips only conflicting NPC and logs once");
local receiver={Message=function() error("foreign NPC handled dialogue"); end};
handlers[7151301][Event.say]({self=foreign,other=receiver,message="hail"});
check(true,"foreign NPC dialogue ignored");

reset(true);
local factory=eq.create_npc_from_table;
eq.create_npc_from_table=function() return nil; end;
tick=load(); tick(); tick();
check(#npcs==0 and #logs==2,"creation failure logs once per NPC");
eq.create_npc_from_table=factory; tick();
check(#npcs==2,"creation failure can recover");
print("PASS: " .. checks .. " setup checks; fresh creation, reload, repop, prototype migration, duplicate prevention, old server guard, collision and retry.");
