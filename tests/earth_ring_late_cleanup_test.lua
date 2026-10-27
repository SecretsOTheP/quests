-- Lua 5.1: lua tests/earth_ring_late_cleanup_test.lua /path/to/Quests
-- Reuse the established encounter fixture, with native-style deferred Depop.
local root = arg[1] or ".";
local f=assert(io.open(root.."/tests/earth_ring_guard_test.lua"));
local fixture=f:read("*a"); f:close();
fixture=assert(fixture:match("^(.-)\n%-%- Dust: real deaths required"));
local substitutions;
fixture,substitutions=fixture:gsub("function n:Depop%(%)self.valid=false;end", "function n:Depop()self.pending=true;end");
assert(substitutions==1,"fixture must model deferred native depop");
local world=assert(loadstring(fixture.."\nreturn world;"))();
local checks=0;
local function check(ok,message) checks=checks+1;assert(ok,message);end
local function flush(w)
    for _,n in pairs(w.npcs) do if n.pending then n.valid=false; end; end
end
local function empty(w,types)
    for _,typ in ipairs(types) do check(#w:list(typ)==0,"cleanup removed type "..typ);end
end
local vineTypes={218019,218362,218363,218364,218420,218396};
local stoneTypes={218029,218032,218031,218030,218033,218369,218370,218371,218372,218373,218374,218395};
local function vineBoss()
    local w=world("Vine");w:begin();w:killAll(218362);
    return w,w:one(218364);
end

-- Failure occurs before an already-due boss adds callback in the same tick.
do
    local w,boss=vineBoss();
    local otherRing=w:spawn(218372); -- Stone heap must not be touched.
    local marker,anchor=w:spawn(218392),w:spawn(218343);
    w:dispatch("timer",boss,{timer="adds"});
    check(#w:list(218420)==2,"first legitimate Vine add wave is unchanged");
    w:tick(6000);
    local nextid=w.nextid;
    w:dispatch("timer",boss,{timer="adds"});
    check(w.nextid==nextid,"late Vine adds timer cannot spawn after failure");
    flush(w);empty(w,vineTypes);
    check(otherRing.valid and not otherRing.pending,"Vine failure preserves another ring's NPC");
    check(marker.valid and not marker.pending and anchor.valid and not anchor.pending,"Vine preserves completion marker and permanent emote anchor");
    w:failed();
end

-- Success cleanup has the same deferred-delete window, without changing lockout.
do
    local w,boss=vineBoss();
    w:dispatch("timer",boss,{timer="adds"});
    w:kill(boss);
    local nextid=w.nextid;
    w:dispatch("timer",boss,{timer="adds"});
    check(w.nextid==nextid,"late Vine adds timer cannot spawn after success");
    flush(w);empty(w,vineTypes);
    check(#w.signals==1,"Vine success grants its original single Arbitor signal");
    for _,write in ipairs(w.writes) do check(write.ms==237600000,"Vine success retains 66-hour lockout");end
end

-- Native trigger deaths queued after cleanup must not restart the failed trial.
do
    local w=world("Vine");
    for i=1,30 do w:spawn(218019);end
    for i=1,3 do w:kill(w:one(218019));end
    w:tick(6000);
    local nextid,writes=w.nextid,#w.writes;
    for i=1,3 do w:kill(w:one(218019));end
    check(w.nextid==nextid and #w.writes==writes,"late tainted deaths do not restart or fail twice");
    flush(w);empty(w,vineTypes);
    w:begin();
    check(#w:list(218362)==10,"fresh native mobs still start the next Vine attempt");
    w:killAll(218362);
    check(w:one(218364),"legitimate tracked corpse-ID-zero deaths still advance Vine");
end
do
    local w=world("Stone");
    for _,typ in ipairs({218031,218030,218032,218033}) do w:spawn(typ);w:spawn(typ);end
    w:spawn(218029); -- Visible dormant Monstrosity, present before rubble phase.
    w:killAll(218031);
    local otherRing=w:spawn(218420); -- Vine add must survive Stone cleanup.
    local marker,anchor=w:spawn(218391),w:spawn(218036);
    w:tick(6000);
    local nextid,writes=w.nextid,#w.writes;
    w:killAll(218030);
    check(w.nextid==nextid and #w.writes==writes,"late Stone native deaths cannot restart failed trial");
    flush(w);empty(w,stoneTypes);
    check(otherRing.valid and not otherRing.pending,"Stone failure preserves another ring's NPC");
    check(marker.valid and not marker.pending and anchor.valid and not anchor.pending,"Stone preserves completion marker and permanent emote anchor");
    w:begin();
    check(#w:list(218369)==43,"fresh Stone triggers still produce exactly 43 fortifications");
    w:killAll(218369);
    check(#w:list(218370)==4,"legitimate tracked corpse-ID-zero deaths still advance Stone");
end

-- An inner spawn callback can fail before the outer spawn2 call returns.
do
    local w,boss=vineBoss();
    local set_timer=w.env.eq.set_timer;
    w.env.eq.set_timer=function(name,...)
        if name=="depop" then error("injected optional add timer error");end
        return set_timer(name,...);
    end;
    w:dispatch("timer",boss,{timer="adds"});
    local adds=0;
    for _,n in pairs(w.npcs) do if n.typ==218420 then adds=adds+1;end;end
    check(adds==1,"nested optional add failure aborts remaining raw spawn loop");
    flush(w);empty(w,vineTypes);
    w:failed();
end
do
    local w=world("Stone");
    w.handlers["spawn:218369"]=function() w:tick(6000);end;
    w:begin();
    local forts=0;
    for _,n in pairs(w.npcs) do if n.typ==218369 then forts=forts+1;end;end
    check(forts==1,"nested spawn failure aborts remaining fortification spawn loop");
    flush(w);empty(w,stoneTypes);
    w:failed();
end
print("PASS: "..checks.." deferred Stone/Vine cleanup checks");
