function event_say(e)
	local enchant_bars_lib = require("self_found_enchant_bars");
	enchant_bars_lib.check_bars_quest_dialogue(e.self, e.other, e.message);
end

function event_trade(e)
	local item_lib = require("items");
	local enchant_bars_lib = require("self_found_enchant_bars");

	enchant_bars_lib.check_for_bars_to_enchant(item_lib, e.self, e.other, e.trade);

	item_lib.return_items(e.self, e.other, e.trade);
end
