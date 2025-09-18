local module = {}

function module.hail_dialog(self, other, message, subject)
    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if not is_self_found then
        return false;
    end

    local quests = module.quest_data[subject]
    if message:findi("Hail") and (not quests.is_pop_content or eq.is_the_planes_of_power_enabled()) then
        if quests.is_agnostic then
            self:Say("Are you in search of the essence of ["..subject.."]?");
        else
            self:Say("Are you a follower of ["..subject.."]?");
        end
        return true;
    end

    return false;
end

function module.check_dialog(self, other, message, subject)
    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if not is_self_found then
        return false;
    end

    if message:findi(subject:gsub("(%W)", "%%%1")) then -- percent-escape '-' in Cazic-Thule, etc
        local keywords = {};
        for _, quest_datum in ipairs(module.quest_data[subject]) do
            if not quest_datum.is_pop_content or eq.is_the_planes_of_power_enabled() then
                table.insert(keywords, "["..quest_datum.keyword.."]");
            end
        end
        if #keywords ~= 0 then
            self:Say("If you are in need of the essence of "..subject.." for your rituals, such as an imbued "..table.concat(keywords, " or ")..", I can help you.");
            return true;
        end
    end

    for _, quest_datum in ipairs(module.quest_data[subject]) do
        if message:findi(quest_datum.keyword) and (not quest_datum.is_pop_content or eq.is_the_planes_of_power_enabled()) then
            local components = {};
            for _, component in ipairs(quest_datum.components) do
                table.insert(components, component.name)
            end
            self:Say("Bring me " .. quest_datum.plat_cost .. " platinum and your "..table.concat(components, " and ")..", and I will imbue it with the essence of "..subject..".");
            return true;
        end
    end

    return false;
end

function module.check_turn_in(item_lib, self, other, trade, subject)
    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if not is_self_found then
        return false;
    end

    for _, quest_datum in ipairs(module.quest_data[subject]) do
        local trade_check = { platinum = quest_datum.plat_cost };
        for i, v in ipairs(quest_datum.components) do
            trade_check["item"..i] = v.id;
        end
        if (not quest_datum.is_pop_content or eq.is_the_planes_of_power_enabled()) and item_lib.check_turn_in(self, trade, trade_check, 0) then
            other:SummonCursorItem(quest_datum.reward_id, 1);
            self:Say("Take this. I have imbued this "..quest_datum.keyword.." with the essence of "..subject..".");
            self:CastSpell(667,self:GetID()); -- Spell: Enchant Silver, cast for visual effect
            return true;
        end
    end

    return false;
end

module.quest_data = {
    ["Rodcet Nife"] = {
        {
            keyword = "opal",
            reward_id = 22560,
            plat_cost = 50,
            components = {
                {
                    name = "Opal",
                    id = 10030,
                },
            },
        },
    },
    ["Quellious"] = {
        {
            keyword = "topaz",
            reward_id = 22555,
            plat_cost = 50,
            components = {
                {
                    name = "Topaz",
                    id = 10025,
                },
            },
        },
    },
    ["Karana"] = {
        {
            keyword = "raw diamond",
            reward_id = 29991,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Storm Rider Blood",
                    id = 29526,
                },
            },
        },
        {
            keyword = "plains pebble",
            reward_id = 22553,
            plat_cost = 50,
            components = {
                {
                    name = "Plains Pebble",
                    id = 12832,
                },
            },
        },
    },
    ["The Tribunal"] = {
        {
            keyword = "raw diamond",
            reward_id = 29494,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Alkaline Etched Stone",
                    id = 21954,
                },
            },
        },
        {
            keyword = "ivory",
            reward_id = 22501,
            plat_cost = 50,
            components = {
                {
                    name = "Ivory",
                    id = 22504,
                },
            },
        },
    },
    ["Cazic-Thule"] = {
        {
            keyword = "amber",
            reward_id = 22502,
            plat_cost = 50,
            components = {
                {
                    name = "Amber",
                    id = 10022,
                },
            },
        },
    },
    ["Terris-Thule"] = {
        is_pop_content = true,
        {
            keyword = "raw diamond",
            reward_id = 29990,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Nightmare Mephit Blood",
                    id = 29525,
                },
            },
        },
    },
    ["Innoruuk"] = {
        {
            keyword = "sapphire",
            reward_id = 22508,
            plat_cost = 50,
            components = {
                {
                    name = "Sapphire",
                    id = 10034,
                },
            },
        },
    },
    ["Saryrn"] = {
        is_pop_content = true,
        {
            keyword = "raw diamond",
            reward_id = 29875,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Putrescent Blood",
                    id = 26635,
                },
            },
        },
    },
    ["Brell Serilis"] = {
        {
            keyword = "ruby",
            reward_id = 22506,
            plat_cost = 50,
            components = {
                {
                    name = "Ruby",
                    id = 10035,
                },
            },
        },
    },
    ["Tunare"] = {
        {
            keyword = "emerald",
            reward_id = 22507,
            plat_cost = 50,
            components = {
                {
                    name = "Emerald",
                    id = 10029,
                },
            },
        },
    },
    ["Rallos Zek"] = {
        {
            keyword = "raw diamond",
            reward_id = 31598,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "War Wraith Blood",
                    id = 29419,
                },
            },
        },
        {
            keyword = "jade",
            reward_id = 22500,
            plat_cost = 50,
            components = {
                {
                    name = "Jade",
                    id = 10023,
                },
            },
        },
    },
    ["Prexus"] = {
        {
            keyword = "black pearl",
            reward_id = 22548,
            plat_cost = 50,
            components = {
                {
                    name = "Black Pearl",
                    id = 10012,
                },
            },
        },
    },
    ["Mithaniel Marr"] = {
        {
            keyword = "raw diamond",
            reward_id = 30489,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Metallic Liquid",
                    id = 29956,
                },
            },
        },
        {
            keyword = "diamond",
            reward_id = 22549,
            plat_cost = 50,
            components = {
                {
                    name = "Diamond",
                    id = 10037,
                },
            },
        },
    },
    ["Erollisi Marr"] = {
        {
            keyword = "rose quartz",
            reward_id = 22550,
            plat_cost = 50,
            components = {
                {
                    name = "Rose Quartz",
                    id = 10021,
                },
            },
        },
    },
    ["Bertoxxulous"] = {
        {
            keyword = "raw diamond",
            reward_id = 30118,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Bubonian Blood",
                    id = 29346,
                },
            },
        },
        {
            keyword = "black sapphire",
            reward_id = 22551,
            plat_cost = 50,
            components = {
                {
                    name = "Black Sapphire",
                    id = 10036,
                },
            },
        },
    },
    ["Bristlebane"] = {
        {
            keyword = "peridot",
            reward_id = 22554,
            plat_cost = 50,
            components = {
                {
                    name = "Peridot",
                    id = 10028,
                },
            },
        },
    },
    ["Solusek Ro"] = {
        {
            keyword = "fire opal",
            reward_id = 22552,
            plat_cost = 50,
            components = {
                {
                    name = "Fire Opal",
                    id = 10031,
                },
            },
        },
    },
    ["The Elements"] = {
        is_pop_content = true,
        is_agnostic = true,
        {
            keyword = "diamond of water",
            reward_id = 29987,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Water Mephit Blood",
                    id = 29522,
                },
            },
        },
        {
            keyword = "diamond of fire",
            reward_id = 29986,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Fire Mephit Blood",
                    id = 29521,
                },
            },
        },
        {
            keyword = "diamond of air",
            reward_id = 29989,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Air Mephit Blood",
                    id = 29524,
                },
            },
        },
        {
            keyword = "diamond of earth",
            reward_id = 29988,
            plat_cost = 500,
            is_pop_content = true,
            components = {
                {
                    name = "Raw Diamond",
                    id = 15981,
                },
                {
                    name = "Earth Mephit Blood",
                    id = 29523,
                },
            },
        },
    },
};

return module;
