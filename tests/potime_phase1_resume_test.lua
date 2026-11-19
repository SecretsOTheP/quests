-- Run with Lua 5.1 from the quests directory.
local source = arg[1] or "potimeb/223077.lua";
package.path = "lua_modules/?.lua;"..package.path;
local NOW = 1800000000;
local function fixture(p1, p2, p3, deadline, checkpoint, p4, p5, p6)
    local globals = {
        time_guild_55001="53", time_expires_55001=tostring(NOW+583200),
        time_cycle_55001=NOW..";"..(NOW+583200)..";"..(checkpoint and "1" or "0"),
        time_kills_55001=table.concat({p1,p2 or "00000",p3 or string.rep("0",18),p4 or "0000",p5 or "0000",p6 or "0"},";")
    };
    local values={};
    for i=1,12 do values[i]=tostring(math.floor((deadline or NOW+10000)/100)); end
    globals.time_timers_55001=table.concat(values,";");
    local timers, signals, cross = {}, {}, {};
    local env=setmetatable({os={time=function() return NOW; end}}, {__index=_G});
    env.eq={};
    function env.eq.get_qglobals() return globals; end
    function env.eq.get_zone_guild_id() return 53; end
    function env.eq.set_global(name,value) globals[name]=value; end
    function env.eq.set_timer(name,ms) timers[name]=ms; end
    function env.eq.stop_timer(name) timers[name]=nil; end
    function env.eq.debug() end
    function env.eq.zone_emote() end
    function env.eq.signal(target,signal,delay,data) signals[#signals+1]={target,signal,data}; end
    function env.eq.cross_zone_signal_npc_by_npc_type_id(target,guild,signal,data)
        cross[#cross+1]={target,guild,signal,data};
    end
    function env.eq.get_entity_list()
        return {GetClientList=function()
            local i=0;
            return {entries=function()
                i=i+1;
                local ys={1600,1350,1100,850,550};
                if ys[i] then
                    local y=ys[i];
                    return {GetX=function() return 0; end,GetY=function() return y; end,GetGM=function() return false; end};
                end
            end};
        end};
    end
    local chunk=assert(loadfile(source));
    setfenv(chunk,env)();
    env.event_signal({signal=1,data="123;1;456;55001;Tester",self={}});
    return env,globals,timers,signals,cross;
end

-- A completed P1 never queues trials or shadows, and resumes at the next uncleared phase.
for _, checkpoint in ipairs({false,true}) do
    local env,g,t,s,c=fixture("11111",checkpoint and "11111" or nil,checkpoint and string.rep("1",18) or nil,nil,checkpoint);
    local nextPhase=checkpoint and 4 or 2;
    local savedKills,savedTimers,savedCycle=g.time_kills_55001,g.time_timers_55001,g.time_cycle_55001;
    env.TryStartTrials();
    for i=1,5 do assert(not t["trial"..i.."start"],"completed trial restarted"); end
    env.event_timer({timer="phase1"});
    assert(not t.check_trial_start,"completed P1 still polling trials");
    if not checkpoint then
        assert(t.dialog,"completed P1 did not transition");
        for i=1,14 do env.event_timer({timer="dialog"}); end
    end
    assert(#s==1 and s[1][2]==nextPhase*100+1,"wrong phase resumed");
    assert(c[#c][4]=="456;55001;"..nextPhase,"Time A phase update incorrect");
    assert(g.time_kills_55001==savedKills and g.time_timers_55001==savedTimers and g.time_cycle_55001==savedCycle,"resume changed saved lockouts");
    env.event_timer({timer="phase1"});
    assert(#s==1,"stale startup timer restarted the phase");
end

-- Unstarted and partial clears still start all trials; killed trial bosses retain shadow flags.
for _,flags in ipairs({"00000","11000"}) do
    local env,g,t,s=fixture(flags);
    env.TryStartTrials();
    env.event_timer({timer="phase1"});
    assert(not t.dialog,"incomplete P1 skipped");
    for i=1,5 do
        assert(t["trial"..i.."start"],"trial was not queued");
        env.event_timer({timer="trial"..i.."start"});
        assert(s[i][2]==tonumber("1"..i.."1") and s[i][3]==flags:sub(i,i),"trial boss flag changed");
    end
end

-- An expired P1 lockout restores normal bosses; the next first kill starts the existing timer.
local env,g,t,s=fixture("11111",nil,nil,NOW-100);
assert(g.time_kills_55001:sub(1,5)=="00000","expired bosses stayed cleared");
env.TryStartTrials();
env.event_timer({timer="phase1"});
assert(not t.dialog,"expired P1 skipped");
for i=1,5 do
    env.event_timer({timer="trial"..i.."start"});
    assert(s[i][3]=="0","expired boss remained a shadow");
end
env.SetBossKilled(1,1);
assert(tonumber(g.time_timers_55001:match("^[^;]+"))*100==NOW+43200,"normal kill timer changed");
local saved=g.time_timers_55001;
env.SetBossKilled(1,2);
assert(g.time_timers_55001==saved,"later kill restarted phase timer");
-- Once P4 is earned, P1 is skipped regardless of its kills or 12-hour timer.
-- Exercise every P1 mask, including the player's 01000 save, before/after expiry,
-- and resume at the first remaining god phase without rewriting loot lockouts.
local cases = 0;
for mask=0,31 do
    local p1="";
    for bit=4,0,-1 do p1=p1..tostring(math.floor(mask/2^bit)%2); end
    for _, deadline in ipairs({NOW-100,NOW+10000}) do
        for _, phase in ipairs({4,5,6}) do
            local p4=phase==4 and "1110" or "1111";
            local p5=phase<=5 and "0000" or "1111";
            local env,g,t,s,c=fixture(p1,"11111",string.rep("1",18),deadline,true,p4,p5,"0");
            local kills,timers,cycle=g.time_kills_55001,g.time_timers_55001,g.time_cycle_55001;
            assert(kills:sub(1,5)==(deadline <= NOW and "00000" or p1),"normal P1 expiry bookkeeping changed");
            env.TryStartTrials();
            for i=1,5 do assert(not t["trial"..i.."start"],"checkpoint queued P1 trial"); end
            env.event_timer({timer="phase1"});
            assert(#s==1 and s[1][2]==phase*100+1,"checkpoint resumed incorrect god phase");
            assert(c[#c][4]=="456;55001;"..phase,"Time A checkpoint route incorrect");
            assert(not t.check_trial_start and not t.dialog,"checkpoint still running early phases");
            assert(g.time_kills_55001==kills and g.time_timers_55001==timers and g.time_cycle_55001==cycle,"checkpoint changed lockouts");
            env.event_timer({timer="phase1"});
            assert(#s==1,"checkpoint startup repeated");
            cases=cases+1;
        end
    end
end
print("PASS: "..cases.." P4-checkpoint cases skip P1-P3 across all P1 masks and expired/live timers; god lockouts and Time A routing preserved");
print("PASS: cleared P1 resumes at P2 or the saved P4 checkpoint; no replay; partial clears preserved; expiry restores bosses; saved and normal kill timers unchanged");
