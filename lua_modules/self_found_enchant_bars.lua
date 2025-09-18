local enchant_bars = {}

function enchant_bars._check_bar_type(item_lib, self, other, trade, bar_data, require_cast)
    local num_bars = 0;
    local required_level = bar_data.required_level;
    local bar_id = bar_data.bar_id;
    local reward_id = bar_data.reward_id;
    local plat_cost = bar_data.plat_cost;

    if (other:GetLevel() >= required_level) then

        local plat_remaining = trade.platinum or 0;
        local reagent_count = item_lib.count_handed_item(self, trade, {bar_id});
        
        if (plat_remaining >= plat_cost and reagent_count > 0) then
            if(require_cast) then
                self:Say("Behold, the transformation is complete. May this enchantment serve as a testament to your growing intellect and mastery over the arcane. Use it with keen insight on your journey.");
                self:CastSpell(667,self:GetID()); -- Spell: Enchant Silver
            else
                self:Say("Here you go.");
            end

            while (plat_remaining >= plat_cost and reagent_count > 0) do
                other:QuestReward(self,0,0,0,0,reward_id);
                plat_remaining = plat_remaining - plat_cost;
                reagent_count = reagent_count - 1;
            end
        end

        -- Return remaining reagents (ran out of plat)
        while (reagent_count > 0) do
            other:SummonItem(bar_id, 1, 9999, true);
            reagent_count = reagent_count - 1;
        end

        -- Return remaining platinum (ran out of reagents)
        trade.platinum = plat_remaining;
    end
end

function enchant_bars._get_bar_data()
    return {
        {
            -- silver
            bar_name = "silver",
            component_name = "Silver Bar",
            bar_id = 16500,
            reward_id = 16504,
            plat_cost = 1,
            required_level = 8
        },
        {
            -- electrum
            bar_name = "electrum",
            component_name = "Electrum Bar",
            required_level = 16,
            bar_id = 16501,
            reward_id = 16505,
            plat_cost = 1,
        },
        {
            -- gold
            bar_name = "gold",
            component_name = "Gold Bar",
            required_level = 20,
            bar_id = 16502,
            reward_id = 16506,
            plat_cost = 1,
        },
        {
            -- platinum
            bar_name = "platinum",
            component_name = "Platinum Bar",
            required_level = 24,
            bar_id = 16503,
            reward_id = 16507,
            plat_cost = 1,
        },
        {
            -- velium
            bar_name = "velium",
            component_name = "Velium Bar",
            required_level = 44,
            bar_id = 22098,
            reward_id = 22099,
            plat_cost = 1,
        },
        {
            -- clay
            bar_name = "clay",
            component_name = "Large Block of Clay",
            required_level = 8,
            bar_id = 16902,
            reward_id = 16896,
            plat_cost = 1,
        },
        {
            -- mithril
            bar_name = "mithril",
            component_name = "Large Brick of Mithril",
            required_level = 20,
            bar_id = 10476,
            reward_id = 10455,
            plat_cost = 1,
        },
        {
            -- adamantite
            bar_name = "adamantite",
            component_name = "Large Brick of Adamantite",
            required_level = 20,
            bar_id = 10475,
            reward_id = 10449,
            plat_cost = 1,
        },
        {
            -- steel
            bar_name = "steel",
            component_name = "Large Brick of High Quality Ore",
            required_level = 20,
            bar_id = 10469,
            reward_id = 10440,
            plat_cost = 1,
        },
        {
            -- brellium
            bar_name = "brellium",
            component_name = "Large Brick of Brellium",
            required_level = 20,
            bar_id = 10474,
            reward_id = 10434,
            plat_cost = 1,
        },
        {
            -- Vial of Viscous Mana
            bar_name = "Viscous Mana",
            component_name = "Pearl",
            required_level = 8,
            bar_id = 10024,
            reward_id = 10250,
            plat_cost = 2,
        },
        {
            -- Vial of Cloudy Mana
            bar_name = "Cloudy Mana",
            component_name = "Peridot",
            required_level = 12,
            bar_id = 10028,
            reward_id = 10251,
            plat_cost = 2,
        },
        {
            -- Vial of Clear Mana
            bar_name = "Clear Mana",
            component_name = "Emerald",
            required_level = 16,
            bar_id = 10029,
            reward_id = 10252,
            plat_cost = 2,
        },
        {
            -- Vial of Distilled Mana
            bar_name = "Distilled Mana",
            component_name = "Sapphire",
            required_level = 20,
            bar_id = 10034,
            reward_id = 10253,
            plat_cost = 107, -- +1 Sapphire (105pp), Poison Vial (1.5p), Tip
        },
        {
            -- Vial of Purified Mana
            bar_name = "Purified Mana",
            component_name = "Ruby",
            required_level = 24,
            bar_id = 10035,
            reward_id = 10254,
            plat_cost = 400, -- +3x Rubies (394pp), Poison Vial (1.5pp), Tip
        },
    };
end

function enchant_bars.check_bars_quest_dialogue(self, other, message)

    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if(is_self_found) then

        local bar_data_list = enchant_bars._get_bar_data();

        -- Loop through bar types and check for the quest dialogue
        for index, bar_data in ipairs(bar_data_list) do
            enchant_bars.check_bar_quest_dialogue(self, other, message, bar_data);
        end

        if(message:findi("Hail")) then
            self:Say("Are you in need of [enchantments]? If so, I may be able to help you.");
        elseif(message:findi("enchantments")) then
            self:Say("Are you seeking enchantments of [metal and ore]? Or perhaps you are looking for enchanted [mana vials]?");
        elseif(message:findi("metal")) then
            self:Say("You wish to explore the deeper mysteries of metallurgy and magic? A noble path. The enchantment of metal is a delicate art. I can enchant [silver], [electrum], [gold], [platinum], [velium], [clay], [mithril], [adamantite], [steel], and [brellium]. Which do you seek?");
        elseif(message:findi("mana vials")) then
            if eq.is_the_scars_of_velious_enabled() then
                self:Say("Enchanted mana is a very concentrated, potent substance that requires a gemstone catalyst for the transformation. There are various formulations of enchanted mana, [viscous mana], [cloudy mana], [clear mana], [distilled mana], and [purified mana]. Which do you seek?");
            else
                self:Say("Enchanted mana is a very concentrated, potent substance that requires a gemstone catalyst for the transformation. There are various formulations of enchanted mana, [viscous mana], [cloudy mana], [clear mana], and [distilled mana]. Which do you seek?");
            end
        end
        
    end
end

function enchant_bars.check_bar_quest_dialogue(self, other, message, bar_data)
    if(message:findi(bar_data.bar_name) and not message:findi("Hail")) then
        if (other:GetLevel() >= bar_data.required_level) then
            message = "Present me with " .. bar_data.plat_cost ..
                     " platinum pieces and your " .. bar_data.component_name ..
                     ", and we shall begin the process of its transformation.";
            self:Say(message);
        else
            self:Say("You are a bit too inexperienced to be dabbling in such magic, aren't you?");
        end
    end 
end 

function enchant_bars.check_for_bars_to_enchant(item_lib, self, other, trade, require_cast)

    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;

    local bar_data_list = enchant_bars._get_bar_data();

    if(is_self_found) then
        -- Loop through each type of bar and see if this is what they are turning in
        for index, bar_data in ipairs(bar_data_list) do
            enchant_bars._check_bar_type(item_lib, self, other, trade, bar_data, require_cast);
        end
    end
end

return enchant_bars;
