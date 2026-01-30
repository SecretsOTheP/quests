function event_say(e)
    local is_faction_requirement_met = e.other:GetFaction(e.self) <= Faction.Amiable;
    local is_self_found = e.other:IsSelfFound() == 1 or e.other:IsSoloOnly() == 1;
    if not is_faction_requirement_met or not is_self_found then
        return;
    end

    local is_level_requirement_met = e.other:GetLevel() >= 55;
    if e.message:findi("hail") then
        if is_level_requirement_met then
            e.self:Say("You there, "..e.other:Race().."! You look like a fine specimen, much fitter than most your ilk. Do you wish to [serve] the Dizok? I could... make use of you in the herb gardens.");
        else
            e.self:Emote("peers down and looks you over. Then goes back to what he was doing, ignoring you.");
        end
    elseif e.message:findi("serve") and is_level_requirement_met then
        e.self:Say("Yes, wonderful, excellent. Even members of lesser races can prove themselves useful to the Dizok. Grand Advisor Zum`uul can prepare you. Tell him I sent you.");
    end
end
