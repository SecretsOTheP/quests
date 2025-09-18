function event_say(e)
	local enchant_bars_lib = require("self_found_enchant_bars");
	-- enchant_bars_lib.check_bars_quest_dialogue(e.self, e.other, e.message);

	local is_self_found = e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() == 1;
    if(is_self_found) then

        local bar_data_list = enchant_bars_lib._get_bar_data();

        -- Loop through bar types and check for the quest dialogue
        for index, bar_data in ipairs(bar_data_list) do
            check_bar_quest_dialogue(e.self, e.other, e.message, bar_data);
        end

        if(e.message:findi("Hail")) then
            e.self:Say("Psst... I've smuggled in some special [items] that may be of use to you.");
        elseif(e.message:findi("items")) then
            e.self:Say("Want to check out some fancy [metal and ore]? Or perhaps you are looking for enchanted [mana vials]?");
        elseif(e.message:findi("metal")) then
            e.self:Say("You'll never believe what kind of [silver], [electrum], [gold], [platinum], [velium], [clay], [mithril], [adamantite], [steel], and [brellium] that I've brought with me");
        elseif(e.message:findi("mana vials")) then
            if eq.is_the_scars_of_velious_enabled() then
                e.self:Say("My contact gave me some [viscous mana], [cloudy mana], [clear mana], [distilled mana], and [purified mana]. Which do you need?");
            else
                e.self:Say("My contact gave me some [viscous mana], [cloudy mana], [clear mana], and [distilled mana]. Which do you need?");
            end
        end
        
    end
end

function check_bar_quest_dialogue(self, other, message, bar_data)
    if(message:findi(bar_data.bar_name) and not message:findi("Hail")) then
        if (other:GetLevel() >= bar_data.required_level) then
            message = "Alright, you can have it for a " .. bar_data.component_name ..
					
                     " and " .. bar_data.plat_cost .. " platinum pieces. Hand it over quick, before we get caught!";
            self:Say(message);
        else
            self:Say("You'd never be able to handle the power of this item.");
        end
    end 
end 

function event_trade(e)
	local item_lib = require("items");
	local enchant_bars_lib = require("self_found_enchant_bars");

	local require_cast = false;

	enchant_bars_lib.check_for_bars_to_enchant(item_lib, e.self, e.other, e.trade, require_cast);

	item_lib.return_items(e.self, e.other, e.trade);
end

--END of FILE Zone:cabeast   -- Belner_Snuckery 

