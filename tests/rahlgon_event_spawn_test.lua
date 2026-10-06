-- Run: lua tests/rahlgon_event_spawn_test.lua /path/to/Quests
local root = arg[1] or ".";
local count = 0;
local function check(ok, text) assert(ok, text); count = count + 1; end
local points = {};
for id=347213,347221 do
    local p={valid=true,enabled=id~=347213,alive=false,timer=0};
    function p:Enable() self.enabled=true; end
    function p:Disable(depop) self.enabled=false; self.depop=depop~=false; if self.depop then self.alive=false; end end
    function p:SetTimer(t) self.timer=t; end
    function p:Process() if self.enabled and not self.alive then self.alive=true;self.hp=100; end end
    points[id]=p;
end
local projections,signals=0,0;
local eqmock={
    get_entity_list=function() return {GetSpawnByID=function(_,id) return points[id]; end}; end,
    set_next_hp_event=function() end, stop_timer=function() end,
    depop_all=function(typ)
        if typ==208176 then points[347213].alive=false;
        elseif typ==208175 then for id=347214,347221 do points[id].alive=false; end end
    end,
    spawn2=function(typ) if typ==208207 then projections=projections+1; end end,
    signal=function(typ) if typ==208207 then signals=signals+1; end end
};
local function script(path)
    local env=setmetatable({eq=eqmock},{__index=_G});
    local chunk=assert(loadfile(root.."/"..path));setfenv(chunk,env);chunk();return env;
end
local ad=script("povalor/#Aerin-Dar.lua");local rg=script("povalor/Rahlgon.lua");local p=points[347213];
p:Process();check(not p.alive,"disabled default must not spawn Rahlgon");
ad.event_spawn({});check(p.enabled and p.timer==1,"Aerin spawn restores Rahlgon");
for id=347214,347221 do check(points[id].timer==1,"other minion restoration remains intact");end
p:Process();check(p.alive and p.hp==100,"restored add starts full health");
rg.event_death_complete({self={GetSpawnPointID=function() return 347213;end}});
check(not p.enabled and not p.depop,"death disables native respawn and preserves corpse");
p.alive=false;p.timer=0;p:Process();check(not p.alive,"native expiry cannot respawn add mid-attempt");
ad.event_timer({timer="checkhp",self={GetHPRatio=function() return 100;end}});
check(p.enabled and p.timer==1,"Aerin reset restores Rahlgon");
p:Process();check(p.alive and p.hp==100,"retry receives fresh add");
rg.event_death_complete({self={GetSpawnPointID=function() return 0;end}});
check(p.enabled,"foreign death cannot disable real event spawn");
ad.event_death_complete({killer={GetID=function() return 1;end}});
check(not p.enabled and not p.alive,"Aerin victory removes and disables add");
check(projections==1 and signals==1,"projection and kill-rights signaling retained");
print(count.." Rahlgon event lifecycle checks passed.");
