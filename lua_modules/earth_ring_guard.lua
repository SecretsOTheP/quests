-- Track required NPCs by identity. A disappearance never counts as a kill.
-- Encounter-owned checks survive the loss of the temporary timeout NPC.
local M = {};
local function live(n)
    return n and n.valid and n:GetID() ~= 0 and n:GetHP() > 0 and not n:IsCorpse();
end
function M.new(name, orphanTypes, fail)
    local g = {active=false, checked=false, records={}, serial=0};
    local key = "earth_guard_"..name;
    local session = tostring({});
    function g:arm(owner)
        self.owner = owner or self.owner;
        eq.set_timer("earth_guard", 5000, self.owner);
    end
    function g:track(n)
        assert(live(n), "required NPC failed to spawn");
        self.serial = self.serial + 1;
        local token = session..":"..self.serial;
        n:SetEntityVariable(key, token);
        self.records[token] = {id=n:GetID(), typ=n:GetNPCTypeID()};
        return n;
    end
    function g:start(nativeTypes)
        if self.active then return; end
        for _,typ in ipairs(orphanTypes) do
            assert(not eq.get_entity_list():IsMobSpawnedByNpcTypeID(typ), "untracked NPCs from an earlier attempt");
        end
        self.active=true; self.checked=true; self.records={}; self.deadline=os.time()+5880;
        self:arm();
        if nativeTypes then
            local types={}; for _,typ in ipairs(nativeTypes) do types[typ]=true; end
            local list=eq.get_entity_list():GetNPCList();
            for n in list.entries do
                if live(n) and types[n:GetNPCTypeID()] then self:track(n); end
            end
        end
    end
    function g:spawn(...)
        return self:track(eq.spawn2(...));
    end
    function g:dead(n)
        if not self.active or not n or not n.valid then return false; end
        local token=n:GetEntityVariable(key);
        local r=self.records[token];
        if not r or r.typ~=n:GetNPCTypeID() then return false; end
        self.records[token]=nil;
        return true;
    end
    function g:owns(n)
        if not self.active or not n or not n.valid then return false; end
        local r=self.records[n:GetEntityVariable(key)];
        return r and r.id==n:GetID() and r.typ==n:GetNPCTypeID();
    end
    function g:once(n)
        -- Native trigger deaths can precede the start of the timed encounter.
        if not n or not n.valid or n:GetEntityVariable(key.."_dead")=="1" then return false; end
        n:SetEntityVariable(key.."_dead", "1");
        self:dead(n);
        return true;
    end
    function g:forget(typ)
        for token,r in pairs(self.records) do if r.typ==typ then self.records[token]=nil; end end
    end
    function g:stop()
        self.active=false; self.records={}; self.checked=true;
    end
    function g:tick(e)
        if e.timer~="earth_guard" then return; end
        if not self.checked then
            self.checked=true;
            for _,typ in ipairs(orphanTypes) do
                if eq.get_entity_list():IsMobSpawnedByNpcTypeID(typ) then
                    fail("untracked encounter NPCs after reload"); return;
                end
            end
        end
        if not self.active then return; end
        if os.time()>=self.deadline then fail("98-minute attempt expired"); return; end
        for token,r in pairs(self.records) do
            local n=eq.get_entity_list():GetMob(r.id);
            if live(n) and n:GetNPCTypeID()==r.typ and n:GetEntityVariable(key)==token then
                r.missing=nil;
            else
                r.missing=r.missing or os.time();
                if os.time()-r.missing>=30 then
                    fail("required NPC "..r.typ.." missing without a confirmed kill"); return;
                end
            end
        end
    end
    function g:wrap(callback)
        return function(e)
            local ok,err=pcall(callback,e);
            if not ok then fail("encounter callback failed: "..tostring(err)); end
        end;
    end
    return g;
end
return M;
