function event_say(e)
    local is_faction_requirement_met = e.other:GetFaction(e.self) <= Faction.Amiable;
    local is_self_found = e.other:IsSelfFound() == 1 or e.other:IsSoloOnly() == 1;
    if not is_faction_requirement_met or not is_self_found then
        return;
    end

    local is_level_requirement_met = e.other:GetLevel() >= 55;
    local quest_data = eq.get_qglobals(e.self, e.other);
    if quest_data.fed_the_gardens == "done" then
        e.self:Emote("ignores you.");
    elseif e.message:findi("hail") then
        e.self:Emote("disdainfully glaces your direction, before going back to his business.");
    elseif e.message:findi("herbalist") or e.message:findi("mak`ha") or e.message:findi("ritual") then
        if is_level_requirement_met then
            e.self:Say("What do you want, minion!? Oh, Grand Herbalist Mak`ha sent you? You will do nicely to feed his gardens. Are you ready to [offer your life] in service to the Dizok?");
        else
            e.self:Say("Leave my sight, you worthless "..e.other:Race().."!");
        end
    elseif e.message:findi("offer my life") and is_level_requirement_met then
        if e.self:IsCasting() then
            e.self:Say("Can't you see I am busy, minion?!");
        else
            eq.set_global("fed_the_gardens", "done", 1, "D7");
            e.self:Emote("looks at you in anticipation. 'Very well. I will take your essence, minion, and your remains will go to use in the herb gardens. You have served the Dizok well!', he says with a smirk.");
            e.other:Faction(e.self, 451, 1); -- Faction: Brood of Di`Zok
            e.other:Faction(e.self, 307, 1); -- Faction: Sarnak Collective
            e.other:Faction(e.self, 259, -1); -- Faction: Goblins of Mountain Death
            e.other:QuestReward(e.self,0,0,0,0,0,1);
            e.self:CastSpell(1768, e.other:GetID());
        end
    end
end
