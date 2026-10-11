local SPAWNID = 347213;

function event_death_complete(e)
    if ( e.self:GetSpawnPointID() ~= SPAWNID ) then
        return;
    end
    local spawn = eq.get_entity_list():GetSpawnByID(SPAWNID);
    if ( spawn and spawn.valid ) then
        -- Keep the corpse intact. Aerin Dar's next spawn/reset restores the add.
        spawn:Disable(false);
    end
end
