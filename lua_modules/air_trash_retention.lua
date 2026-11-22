-- Guild-instance trash only. Absolute deadlines never refresh on reload.
local M = { BASE=3600, KILL=2700, CAP=64800, NORMAL=1080 };
-- Match the server: controls off forces slowed guild-instance respawns.
function M.enabled()
    if eq.get_zone_guild_id()<=1 then return false; end
    if eq.get_rule("Quarm:EnableGuildInstanceRespawnControl")~="true" then return true; end
    local choice=eq.get_data("guild_instance_respawns:"..eq.get_zone_guild_id());
    return choice=="0" or choice=="false";
end
function M.restore_guild(guild)
    if guild<=1 then return; end
    local key="poair-trash-reset-"..guild;
    local revision=tonumber((eq.get_data(key) or ""):match("^(%d+)|")) or 0;
    -- A revision also detects restore -> slow while Air is unloaded.
    eq.set_data(key,(revision+1).."|"..os.time());
end
local Spawns=require("air_trash_spawns");
local groups=Spawns.groups;
local function live(n)
    return n and n.valid and n:GetID()~=0 and n:GetHP()>0 and not n:IsCorpse();
end
function M.new(name)
    if eq.get_zone_guild_id()<=1 then return nil; end
    local allowed={}; for _,id in ipairs(assert(groups[name])) do allowed[id]=true; end
    local t={first=0,deadline=0,dead={},pending={},epoch=0,active=M.enabled(),reset_at=0,key="poair-ring-v1-"..name.."-"..eq.get_zone_guild_id().."-trash"};
    local function ids_text(values)
        local ids={}; for id in pairs(values) do ids[#ids+1]=id; end; table.sort(ids);
        return table.concat(ids,",");
    end
    local function parse_ids(text)
        local ids={};
        for id in text:gmatch("[^,]+") do
            id=tonumber(id); if not id or not allowed[id] then return nil; end
            ids[id]=true;
        end
        return ids;
    end
    function t:Save()
        eq.set_data(self.key,table.concat({"2",self.epoch,self.active and 1 or 0,
            self.first,self.deadline,ids_text(self.dead),self.reset_at,ids_text(self.pending)},"|"),"172800");
    end
    function t:Refresh()
        local epoch,reset_at=(eq.get_data("poair-trash-reset-"..eq.get_zone_guild_id()) or ""):match("^(%d+)|(%d+)$");
        epoch,reset_at=tonumber(epoch) or 0,tonumber(reset_at) or 0;
        local active=M.enabled();
        local raw=eq.get_data(self.key) or "";
        local fields={}; for value in (raw.."|"):gmatch("(.-)|") do fields[#fields+1]=value; end
        local old_epoch,old_active,a,b,dead,pending,pending_at=epoch,active,0,0,{}, {},0;
        if fields[1]=="1" and #fields==4 then
            old_epoch,old_active=0,true;a,b=tonumber(fields[2]),tonumber(fields[3]);dead=parse_ids(fields[4]);
        elseif fields[1]=="2" and #fields==8 then
            old_epoch,old_active=tonumber(fields[2]),fields[3]=="1";
            a,b=tonumber(fields[4]),tonumber(fields[5]);dead=parse_ids(fields[6]);
            pending_at=tonumber(fields[7]);pending=parse_ids(fields[8]);
        end
        if not old_epoch or not a or not b or not dead or not pending or not pending_at
            or a>os.time() or a<0 or b<a or b>a+M.CAP then
            a,b,dead,pending,pending_at=0,0,{}, {},0;old_epoch,old_active=epoch,active;
        end
        local changed=old_epoch~=epoch or old_active~=active;
        if old_epoch~=epoch or (old_active and not active) then
            for id in pairs(dead) do pending[id]=true; end
            pending_at=old_epoch~=epoch and reset_at>0 and reset_at or os.time();
            a,b,dead=0,0,{};
        end
        self.epoch,self.active,self.first,self.deadline,self.dead=epoch,active,a,b,dead;
        self.pending,self.reset_at=pending,pending_at;
        -- Only release previously held trash. Never replace a living NPC or corpse.
        -- Persist remaining normal respawn time, so unloading cannot restore the hold.
        for id in pairs(pending) do
            local spawn=eq.get_entity_list():GetSpawnByID(id);
            if spawn and spawn.valid then
                if not live(spawn:GetNPC()) then
                    local remaining=math.max(1,pending_at+spawn:RespawnTimer()-os.time());
                    eq.update_spawn_timer(id,remaining*1000);
                end
                pending[id]=nil;changed=true;
            end
        end
        if changed then self:Save(); end
    end
    function t:Held(id) return self.active and os.time()<self.deadline and self.dead[id]; end
    function t:Suppress(n)
        if live(n) and self:Held(n:GetSpawnPointID()) then n:Depop(false); end
    end
    function t:Record(id)
        if not allowed[id] then return false; end
        self:Refresh();
        if not self.active then return false; end
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
    function t:ReleaseExpired(ids)
        if not self.active or self.deadline==0 or os.time()<self.deadline then return; end
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
