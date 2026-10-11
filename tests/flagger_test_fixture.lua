-- Offline encounter-test support only. Load the real shared helper inside
-- each mocked quest environment; these client APIs model the Server bindings.
return function(env, root)
    local invalid = {valid=false};
    local function Enrich(client)
        if not client or not client.valid then return client; end
        client.GetID = client.GetID or function(self) return self:GetGM() and 9901 or 9902; end;
        client.IsClient = client.IsClient or function() return true; end;
        client.IsPet = client.IsPet or function() return false; end;
        client.CastToClient = client.CastToClient or function(self) return self; end;
        client.CharacterID = client.CharacterID or function(self) return self:GetID(); end;
        client.GetRaid = client.GetRaid or function() return invalid; end;
        client.GetGroup = client.GetGroup or function() return invalid; end;
        client.GetName = client.GetName or function(self) return "Fixture" .. self:GetID(); end;
        return client;
    end
    local entity = env.eq.get_entity_list();
    local originalList = entity.GetClientList;
    function entity:GetClientList()
        local owner = originalList(self);
        local iterator = owner.entries;
        -- Keep the non-owning luabind iterator's collection alive.
        return {entries=function(...)
            local retainedOwner = owner;
            return Enrich(iterator(...));
        end};
    end
    if not entity.GetClientByID then
        function entity:GetClientByID(id)
            local clients = self:GetClientList();
            for client in clients.entries do if client:GetID() == id then return client; end; end
            return invalid;
        end
    end
    local originalRequire = env.require;
    env.require = function(name)
        if name ~= "projection_eligibility" then return originalRequire(name); end
        local file = assert(io.open(root .. "/lua_modules/projection_eligibility.lua"));
        local source = file:read("*a"); file:close();
        local chunk = assert(loadstring(source)); setfenv(chunk, env);
        local helper = chunk(); local spawn = helper.Spawn;
        helper.Spawn = function(typ, grid, unused, x, y, z, heading, killer, seconds)
            return spawn(typ, grid, unused, x, y, z, heading, Enrich(killer), seconds);
        end
        return helper;
    end
end
