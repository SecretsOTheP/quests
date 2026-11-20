-- Guild-instance trash only. Absolute deadlines never refresh on reload.
local M = { BASE=3600, KILL=2700, CAP=64800 };
local Spawns=require("air_trash_spawns");
local groups=Spawns.groups;
local function live(n)
    return n and n.valid and n:GetID()~=0 and n:GetHP()>0 and not n:IsCorpse();
end
function M.new(name)
    if eq.get_zone_guild_id()<=1 then return nil; end
    local allowed={}; for _,id in ipairs(assert(groups[name])) do allowed[id]=true; end
    local t={first=0,deadline=0,dead={},key="poair-ring-v1-"..name.."-"..eq.get_zone_guild_id().."-trash"};
    function t:Save()
        local ids={}; for id in pairs(self.dead) do ids[#ids+1]=id; end; table.sort(ids);
        eq.set_data(self.key,"1|"..self.first.."|"..self.deadline.."|"..table.concat(ids,","),"172800");
    end
    function t:Refresh()
        self.first,self.deadline,self.dead=0,0,{};
        local a,b,ids=(eq.get_data(self.key) or ""):match("^1|(%d+)|(%d+)|(.*)$");
        a,b=tonumber(a),tonumber(b);
        if not a or not b or a>os.time() or b<a or b>a+M.CAP then return; end
        local dead={};
        for id in ids:gmatch("[^,]+") do
            id=tonumber(id); if not id or not allowed[id] then return; end; dead[id]=true;
        end
        self.first,self.deadline,self.dead=a,b,dead;
    end
    function t:Held(id) return os.time()<self.deadline and self.dead[id]; end
    function t:Record(id)
        if not allowed[id] then return false; end
        self:Refresh();
        local now=os.time();
        if now>=self.deadline then
            -- A kill may arrive before the periodic expiry sweep. Release old
            -- travel suppression before replacing the saved death list.
            local extras={};for old in pairs(self.dead) do if Spawns.extra[old] then extras[#extras+1]=old;end;end
            self:ReleaseExpired(extras);
            self.first,self.deadline,self.dead=now,now+M.BASE,{};
        end
        if self.dead[id] then return false; end
        self.dead[id]=true;
        self.deadline=math.min(self.deadline+M.KILL,self.first+M.CAP);
        self:Save(); return true;
    end
    function t:Suppress(n)
        if live(n) and self:Held(n:GetSpawnPointID()) then n:Depop(false); end
    end
    function t:ReleaseExpired(ids)
        if self.deadline==0 or os.time()<self.deadline then return; end
        local changed=false;
        for _,id in ipairs(ids) do
            if self.dead[id] then
                local spawn=eq.get_entity_list():GetSpawnByID(id);
                if spawn and spawn.valid then
                    -- Never reset a living mob or replace a boss spawnpoint.
                    if not live(spawn:GetNPC()) then spawn:Repop(); end
                    self.dead[id]=nil; changed=true;
                end
            end
        end
        if changed then self:Save(); end
    end
    t:Refresh(); return t;
end
return M;
