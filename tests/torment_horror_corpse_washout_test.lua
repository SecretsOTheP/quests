-- Run with Lua 5.1: lua tests/torment_horror_corpse_washout_test.lua <quest-root>
local root = arg[1] or ".";
local checks = 0;
local function check(value, message)
    assert(value, message);
    checks = checks + 1;
end
local function corpse(x, y, z, player, valid)
    local c = { valid = valid ~= false, x=x, y=y, z=z, player=player ~= false, moved=0 };
    function c:IsPlayerCorpse() return self.player; end
    function c:GetX() return self.x; end
    function c:GetY() return self.y; end
    function c:GetZ() return self.z; end
    function c:MoveToInstanceGraveyard() self.moved = self.moved + 1; end
    function c:MoveToGraveyard() error("Generic graveyard routing can leave the guild instance"); end
    return c;
end
local function load(corpses)
    local progress, list_reads = {}, 0;
    local env = setmetatable({eq={}}, {__index=_G});
    env.eq.depop_with_timer = function(id) table.insert(progress,{"depop",id}); end;
    env.eq.unique_spawn = function(...) table.insert(progress,{"unique",...}); end;
    env.eq.spawn2 = function(...) table.insert(progress,{"spawn",...}); end;
    env.eq.get_entity_list = function()
        return {GetCorpseList=function()
            list_reads=list_reads+1;
            if not corpses then return nil; end
            -- Iterator deliberately borrows the owner: force GC every step to
            -- catch loops that discard the list before finishing iteration.
            local owner = {};
            local weak = setmetatable({owner},{__mode="v"});
            local index=0;
            owner.entries=function()
                collectgarbage("collect");
                assert(weak[1],"Corpse list owner was collected while iterating");
                index=index+1;
                return corpses[index];
            end;
            return owner;
        end};
    end;
    local fn=assert(loadfile(root.."/potorment/An_Unimaginable_Horror.lua"));
    setfenv(fn,env);fn();
    return env,progress,function()return list_reads;end;
end
local cases={
    {corpse(-788,997,-1633),true,"Horror room"},
    {corpse(-821,953,-1440),true,"Middle rooms"},
    {corpse(-1040,973,-1238),true,"Lower corridor"},
    {corpse(-1106,970,-1046),true,"Upper corridor"},
    {corpse(-1073,959,-744),true,"Stomach entrance"},
    {corpse(-1258,846,-672),true,"Map pocket corner"},
    {corpse(-598,1074,-1656),true,"Opposite map corner"},
    {corpse(-800,950,-2000),true,"Corpse fallen below stomach"},
    {corpse(-1300,800,-601),true,"Inclusive lower horizontal bounds"},
    {corpse(-550,1120,-601),true,"Inclusive upper horizontal bounds"},
    {corpse(-1301,950,-1000),false,"Outside west bound"},
    {corpse(-549,950,-1000),false,"Outside east bound"},
    {corpse(-800,799,-1000),false,"Outside south bound"},
    {corpse(-800,1121,-1000),false,"Outside north bound"},
    {corpse(-800,950,-600),false,"Above pocket cutoff"},
    {corpse(-800,950,-490),false,"Main-zone height"},
    {corpse(-175,915,-830),false,"Keeper area"},
    {corpse(434,1950,-698),false,"Other lower pocket"},
    {corpse(-341,1706,-491),false,"Already at zone-in"},
    {corpse(-788,997,-1633,false),false,"NPC corpse"},
    {corpse(-788,997,-1633,true,false),false,"Invalid corpse"}
};
local all={};for _,v in ipairs(cases)do table.insert(all,v[1]);end;
local env,progress,reads=load(all);
env.event_death({});
check(reads()==0,"Transition callback must remain independent of corpse washout");
check(#progress==3,"Preserve the three existing transition actions");
check(progress[1][1]=="depop" and progress[1][2]==207028,"Depop original Baraguj");
check(progress[2][1]=="unique" and progress[2][2]==207319 and progress[2][5]==5 and progress[2][6]==-1041,"Spawn reward Baraguj at original position");
check(progress[3][1]=="spawn" and progress[3][2]==207321 and progress[3][5]==-805 and progress[3][7]==-1644,"Preserve exit entity");
env.event_death_complete({});
check(reads()==1,"Only one local corpse-list scan per completion");
for _,v in ipairs(cases)do check(v[1].moved==(v[2] and 1 or 0),v[3]);end;
check(#progress==3,"Washout must not replay event progression");
local empty,_,empty_reads=load({});empty.event_death_complete({});check(empty_reads()==1,"Empty zone completes safely");
local missing,_,missing_reads=load(nil);missing.event_death_complete({});check(missing_reads()==1,"Missing corpse list completes safely");
print(checks.." Torment corpse washout checks passed");
