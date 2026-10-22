function event_say(e)
	local qglobals = eq.get_qglobals(e.other);
	local thelinFlag = tonumber(qglobals.thelin) or 0;
	local imbue_gems_lib = require("self_found_imbue_gems");
	local imbue_gems_subject = "Terris-Thule";

	if ( e.message:findi("hail") ) then
		if ( thelinFlag >= 3 ) then
			e.other:Message(0, "Thelin tells you, 'I apologize but I cannot stand to greet you. I am still quite weak and recovery will be a long and painful road, though it is a most welcome venture. I want you to know how much I appreciate your bravery in helping me. I am forever in your debt.'");
			if ( thelinFlag == 3 ) then
				eq.set_global("thelin", "4", 5, "F");
			end
			e.other:Message(15, "You receive a character flag!");
		else
			e.other:Message(0, "Adroha gives a soft sigh of woe, 'You won't be getting any response from Thelin.  Ever since his injury he has been in a deep [coma] with no sign of ever recovering.'");
			e.other:Message(0, "Thelin tosses and turns violently on the floor, then is still.");
		end
		imbue_gems_lib.hail_dialog(e.self, e.other, e.message, imbue_gems_subject);
	elseif ( imbue_gems_lib.check_dialog(e.self, e.other, e.message, imbue_gems_subject) ) then
	end
end

function event_trade(e)
	local item_lib = require("items");
	local imbue_gems_lib = require("self_found_imbue_gems");
	local imbue_gems_subject = "Terris-Thule";

	if ( imbue_gems_lib.check_turn_in(item_lib, e.self, e.other, e.trade, imbue_gems_subject) ) then
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
