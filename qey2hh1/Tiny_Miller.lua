function event_say(e)
	if e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() >= 1 then
		if e.message:findi("hail") then
			e.self:Say("Mez not stop to talk. Weez need to finish [work] for Pa before sun go away.")
		elseif e.message:findi("work") then
			e.self:Say("Pa need mez to haul more hay. You help get hay sack wiv mez?")
		end
	end
end

function event_trade(e)
	local item_lib = require("items")
	if e.other:IsSelfFound() >= 1 or e.other:IsSoloOnly() >= 1 then
		if
			e.other:GetFactionValue(e.self) >= 0 -- indifferent
			and item_lib.check_turn_in(e.self, e.trade, { item1 = 13990, item2 = 13990, item3 = 13990, item4 = 13900 }) -- Sack of Hay x4
		then
			e.self:Say("Yooz nice for helping mez. Yooz take dis shinystone mez got from da field.")
			e.other:QuestReward(e.self, 0, 0, 0, 0, 12832, 0) -- Plains Pebble
		end
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
