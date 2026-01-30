-- =====================================================================================
-- TAKP-Compatible: Order and Discord / Reborn System
-- Version 6.2: Removed dependency on GetClassName() for maximum stability.
-- =====================================================================================

-- [MODULES] --
local newgameplus = require("newgameplus");
local titles = require("title_manager");
local item_lib = require("items");

-- [DATA TABLES & CONFIG] --
local REBORN_ATTRIBUTE_POINTS = 25
local MAX_POINTS_PER_STAT = 20
local STATS = {"STR", "STA", "DEX", "AGI", "WIS", "INT", "CHA"}

local valid_combos = {
    [1]   = { name = "Human",      classes = {1,2,3,4,5,6,7,8,9,12,13,14,15}, deities = {"Bertoxxulous", "Brell Serilis", "Cazic Thule", "Erollisi Marr", "Innoruuk", "Karana", "Mithaniel Marr", "Prexus", "Quellious", "Rallos Zek", "Rodcet Nife", "Solusek Ro", "The Tribunal", "Tunare", "Agnostic"}, cities = {"Qeynos", "Freeport"} },
    [2]   = { name = "Barbarian",  classes = {1,9,10,15},                     deities = {"Mithaniel Marr", "Rallos Zek", "The Tribunal"}, cities = {"Halas"} },
    [3]   = { name = "Erudite",    classes = {2,3,5,11,12,13,14},             deities = {"Cazic Thule", "Prexus", "Quellious"}, cities = {"Erudin"} },
    [4]   = { name = "Wood Elf",   classes = {1,4,6,9,8},                     deities = {"Karana", "Tunare"}, cities = {"Kelethin"} },
    [5]   = { name = "High Elf",   classes = {1,2,3,12,13,14},                deities = {"Erollisi Marr", "Karana", "Mithaniel Marr", "Tunare"}, cities = {"Felwithe"} },
    [6]   = { name = "Dark Elf",   classes = {1,2,5,9,11,12,13,14},           deities = {"Innoruuk"}, cities = {"Neriak"} },
    [7]   = { name = "Half Elf",   classes = {1,3,4,6,8,9,15},                deities = {"Agnostic", "Bertoxxulous", "Brell Serilis", "Cazic Thule", "Erollisi Marr", "Innoruuk", "Karana", "Mithaniel Marr", "Prexus", "Quellious", "Rallos Zek", "Rodcet Nife", "Solusek Ro", "The Tribunal", "Tunare"}, cities = {"Qeynos", "Freeport", "Kelethin"} },
    [8]   = { name = "Dwarf",      classes = {1,2,3,9,15},                    deities = {"Brell Serilis"}, cities = {"Kaladim"} },
    [9]   = { name = "Troll",      classes = {1,5,10,15},                     deities = {"Cazic Thule", "Innoruuk", "Rallos Zek"}, cities = {"Grobb"} },
    [10]  = { name = "Ogre",       classes = {1,5,10,15},                     deities = {"Cazic Thule", "Rallos Zek"}, cities = {"Oggok"} },
    [11]  = { name = "Halfling",   classes = {1,2,4,6,9},                     deities = {"Brell Serilis", "Karana", "Mithaniel Marr"}, cities = {"Rivervale"} },
    [12]  = { name = "Gnome",      classes = {1,2,9,11,12,13,14},             deities = {"Bertoxxulous", "Brell Serilis"}, cities = {"Akanon"} },
    [128] = { name = "Iksar",      classes = {1,5,7,10,11,15},                deities = {"Cazic Thule"}, cities = {"Cabilis"} }
}
local classes_map = { ["warrior"]=1, ["cleric"]=2, ["paladin"]=3, ["ranger"]=4, ["shadowknight"]=5, ["druid"]=6, ["monk"]=7, ["bard"]=8, ["rogue"]=9, ["shaman"]=10, ["necromancer"]=11, ["wizard"]=12, ["magician"]=13, ["enchanter"]=14, ["beastlord"]=15 }
local races_map = { ["human"]=1, ["barbarian"]=2, ["erudite"]=3, ["wood elf"]=4, ["high elf"]=5, ["dark elf"]=6, ["half elf"]=7, ["dwarf"]=8, ["troll"]=9, ["ogre"]=10, ["halfling"]=11, ["gnome"]=12, ["iksar"]=128 }

local reverse_races_map, reverse_classes_map = {}, {}
for name, id in pairs(races_map) do reverse_races_map[id] = name:gsub("^%l", string.upper) end
for name, id in pairs(classes_map) do reverse_classes_map[id] = name:gsub("^%l", string.upper) end

function ShowStatMenu(e)
    local points_rem = tonumber(e.other:GetBucket("reborn_points_rem")) or 0
    e.self:Say("You have " .. points_rem .. " attribute points remaining to spend. (Max " .. MAX_POINTS_PER_STAT .. " per stat)")
    local current_stats = {}; for _, stat in ipairs(STATS) do local value = tonumber(e.other:GetBucket("reborn_points_" .. stat:lower())) or 0; if value > 0 then table.insert(current_stats, stat .. ": " .. value) end end
    if #current_stats > 0 then e.other:Message(15, "Current Allocation: " .. table.concat(current_stats, ", ")) end
    if points_rem == 0 then
        e.self:Say("Your points are fully allocated. This is your final choice. When you are ready, confirm your rebirth.")
        e.other:Message(15, "[" .. eq.say_link("reborn_confirm", false, "Confirm Rebirth") .. "] or [" .. eq.say_link("reborn_reset", false, "Start Over") .. "]")
    else
        local links = {}; for _, stat in ipairs(STATS) do local current_val = tonumber(e.other:GetBucket("reborn_points_" .. stat:lower())) or 0; local stat_links = ""; if current_val < MAX_POINTS_PER_STAT and points_rem > 0 then stat_links = "[" .. eq.say_link("reborn_add_"..stat.."_1", false, stat .. " +1") .. "]"; if points_rem >= 5 and current_val <= (MAX_POINTS_PER_STAT - 5) then stat_links = stat_links .. "[" .. eq.say_link("reborn_add_"..stat.."_5", false, "+5") .. "]" end else stat_links = stat .. " (Max)" end table.insert(links, stat_links) end
        e.other:Message(15, table.concat(links, " | "))
    end
end

function event_say(e)
	local is_special_flag_response = false;
    local link_reset = eq.say_link("reborn_reset", false, "Start Over"); local link_tome = eq.say_link("tome", false, "Tome of Order and Discord"); local link_return = eq.say_link("return", false, "return"); local link_king = eq.say_link("king", false, "king"); local link_queen = eq.say_link("queen", false, "queen"); local link_reborn = eq.say_link("reborn", false, "reborn"); local link_challenges = eq.say_link("challenges", false, "challenges"); local link_rites = eq.say_link("rites", false, "rites"); local link_names = eq.say_link("names", false, "names")
	if e.message:findi("name") or e.message:findi("title") then if titles.HandleName(e) then return; end end

	if e.message:findi("hail") then
		e.self:Say("Greetings, " .. e.other:GetCleanName() .. ". If you seek Discord, give me your ["..link_tome.."]. Or perhaps ["..link_return.."] to Order.");
		e.other:Message(0, "To reshape yourself, speak of the ["..link_king.."] or ["..link_queen.."]. The self can be ["..link_reborn.."].");
		e.other:Message(0, "Inquire about secret ["..link_challenges.."], ["..link_rites.."], and your many ["..link_names.."].");
	
    elseif e.message:findi("^reborn_confirm$") then
        local race_id_str = e.other:GetBucket("reborn_race"); local class_id_str = e.other:GetBucket("reborn_class"); local deity_name = e.other:GetBucket("reborn_deity"); local gender_name = e.other:GetBucket("reborn_gender"); local city_name = e.other:GetBucket("reborn_city")
        if not race_id_str or not class_id_str or not deity_name or not gender_name or not city_name then e.self:Say("Your selection has expired."); return; end
        local race_name = reverse_races_map[tonumber(race_id_str)]; local class_name = reverse_classes_map[tonumber(class_id_str)]
        local stat_string = ""; for _, stat in ipairs(STATS) do local value = tonumber(e.other:GetBucket("reborn_points_" .. stat:lower())) or 0; if value > 0 then stat_string = stat_string .. value .. " " .. stat:lower() .. " " end end
        e.message = "reborn race " .. race_name .. " class " .. class_name .. " gender " .. gender_name .. " deity " .. deity_name .. " home city " .. city_name .. " " .. stat_string:gsub("^%s*(.-)%s*$", "%1")
        newgameplus.HandleReborn(e)
        e.other:DeleteBucket("reborn_race"); e.other:DeleteBucket("reborn_class"); e.other:DeleteBucket("reborn_deity"); e.other:DeleteBucket("reborn_gender"); e.other:DeleteBucket("reborn_city");
        for _, stat in ipairs(STATS) do e.other:DeleteBucket("reborn_points_" .. stat:lower()) end; e.other:DeleteBucket("reborn_points_rem")

    elseif e.message:findi("^reborn_add_") then
        local _, _, stat, amount = e.message:find("reborn_add_([A-Z]+)_([0-9]+)"); if not stat or not amount then return end; stat = stat:lower(); amount = tonumber(amount)
        local points_rem = tonumber(e.other:GetBucket("reborn_points_rem")) or 0
        if amount > points_rem then e.self:Say("You do not have enough points."); ShowStatMenu(e); return end
        local current_stat_val = tonumber(e.other:GetBucket("reborn_points_" .. stat)) or 0
        if (current_stat_val + amount) > MAX_POINTS_PER_STAT then e.self:Say("You cannot allocate more than " .. MAX_POINTS_PER_STAT .. " points to a single attribute."); ShowStatMenu(e); return end
        e.other:SetBucket("reborn_points_" .. stat, tostring(current_stat_val + amount), "5m"); e.other:SetBucket("reborn_points_rem", tostring(points_rem - amount), "5m"); ShowStatMenu(e)
        
    elseif e.message:findi("^reborn_city_") then
        if not e.other:GetBucket("reborn_gender") then e.self:Say("Your selection has expired."); return; end
        e.other:SetBucket("reborn_city", e.message:gsub("reborn_city_", ""), "5m")
        e.self:Say("Your path is chosen. Now, you must decide how your attributes will be reshaped.")
        e.other:SetBucket("reborn_points_rem", tostring(REBORN_ATTRIBUTE_POINTS), "5m")
        for _, stat in ipairs(STATS) do e.other:SetBucket("reborn_points_" .. stat:lower(), "0", "5m") end; ShowStatMenu(e)

    elseif e.message:findi("^reborn_gender_") then
        if not e.other:GetBucket("reborn_deity") then e.self:Say("Your selection has expired."); return; end
        e.other:SetBucket("reborn_gender", e.message:gsub("reborn_gender_", ""), "5m")
        e.self:Say(e.other:GetBucket("reborn_gender") .. ", it is. Where will your new life begin?")
        local race_id = tonumber(e.other:GetBucket("reborn_race")); if not race_id or not valid_combos[race_id] or not valid_combos[race_id].cities then e.self:Say("Internal error: No city data."); return; end
        local city_links = {}; for _, city in ipairs(valid_combos[race_id].cities) do table.insert(city_links, "[" .. eq.say_link("reborn_city_" .. city, false, city) .. "]") end
        e.other:Message(15, "Home Cities: " .. table.concat(city_links, ", "))

    elseif e.message:findi("^reborn_deity_") then
        if not e.other:GetBucket("reborn_class") then e.self:Say("Your selection has expired."); return end
        e.other:SetBucket("reborn_deity", e.message:gsub("reborn_deity_", ""), "5m")
        e.self:Say(e.other:GetBucket("reborn_deity") .. " it is. What is your form? [" .. eq.say_link("reborn_gender_Male", false, "Male") .. "] or [" .. eq.say_link("reborn_gender_Female", false, "Female") .. "]?")

    elseif e.message:findi("^reborn_race_") then
        local race_name = e.message:gsub("reborn_race_", "")
        local race_id;
        for id, data in pairs(valid_combos) do if data.name:lower() == race_name:lower() then race_id = id; break; end end
        if not race_id then return end

        local current_class_id = e.other:GetClass()
        local current_class_name = reverse_classes_map[current_class_id]
        if not current_class_name then e.self:Say("Internal error: Cannot identify your current class."); return; end

        local race_data = valid_combos[race_id]
        local is_class_valid = false
        if race_data and race_data.classes then
            for _, valid_class in ipairs(race_data.classes) do if valid_class == current_class_id then is_class_valid = true; break; end end
        end

        if not is_class_valid then
            e.self:Say("That race is not a valid choice. Your current class ("..current_class_name..") cannot be a "..race_name..".")
            return
        end

        e.other:SetBucket("reborn_race", tostring(race_id), "5m"); e.other:SetBucket("reborn_class", tostring(current_class_id), "5m")
        e.self:Say("A " .. race_name .. ". Your class will remain " .. current_class_name .. ". To which deity will you pledge your soul?")
        local deity_links = {}; if race_data and race_data.deities then for _, deity in ipairs(race_data.deities) do table.insert(deity_links, "[" .. eq.say_link("reborn_deity_" .. deity, false, deity) .. "]") end end
        e.other:Message(15, "Deities: " .. table.concat(deity_links, ", "))

    elseif e.message:findi("^reborn$") or e.message:findi("^reborn_reset$") then
        e.other:DeleteBucket("reborn_race"); e.other:DeleteBucket("reborn_class"); e.other:DeleteBucket("reborn_deity"); e.other:DeleteBucket("reborn_gender"); e.other:DeleteBucket("reborn_city");
        for _, stat in ipairs(STATS) do e.other:DeleteBucket("reborn_points_" .. stat:lower()) end; e.other:DeleteBucket("reborn_points_rem")
        e.self:Say("To be reborn is to reshape yourself entirely. First, choose your new race.")
        local race_links = {}; for _, data in pairs(valid_combos) do table.insert(race_links, "[" .. eq.say_link("reborn_race_" .. data.name, false, data.name) .. "]") end
        e.other:Message(15, "Races: " .. table.concat(race_links, ", "))
	
    -- == Original Challenge Logic can be merged here ==
	end
end

function event_trade(e)
	if item_lib.check_turn_in(e.self, e.trade, {item1 = 18700}) then
		e.self:Say("Welcome to Discord! You can now be harmed by those who have also heard the call of Discord.");
		e.other:SetPVP(true); e.other:Ding();
	elseif item_lib.check_turn_in_nomq(e.self, e.trade, {item1 = 14402, item2 = 13992}) then
		e.other:PermaGender(0);
	elseif item_lib.check_turn_in_nomq(e.self, e.trade, {item1 = 14402, item2 = 13993}) then
		e.other:PermaGender(1);
	end
	item_lib.return_items(e.self, e.other, e.trade);
end
