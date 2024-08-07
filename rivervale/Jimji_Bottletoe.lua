function event_say(e)
	if(eq.is_the_shadows_of_luclin_enabled()) then
		if(e.message:findi("bravefoot helm")) then
			e.self:Say("To assemble a Bravefoot Helm you will need to obtain two bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this Crude Helm Mold. Once that is done combine the Crude Iron Helm with a Ruined Wolf Pelt and a Large Yellowjacket Tergite in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19631); -- Item: Crude Helm Mold
		elseif(e.message:findi("forge")) then
			e.self:Say("There is a forge at the Tagglefoots Farm near the vegetable stand and the main house of the farm.");
		elseif(e.message:findi("bravefoot mail bracer")) then
			e.self:Say("To assemble a Bravefoot Mail Bracer you will need to obtain a brick of crude iron ore and smelt it in a [forge] with a Water Flask and this Crude Bracer Mold. Once that is done. combine the Crude Iron Bracer with a Ruined Wolf Pelt and a Large Yellowjacket Sternite in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19632); -- Item: Crude Bracer Mold
		elseif(e.message:findi("bravefoot gauntlets")) then
			e.self:Say("To assemble Bravefoot Gauntlets you will need to obtain two bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this crude Gauntlet Mold. Once that is done combine the Crude Iron Gauntlets with a Ruined Wolf Pelt and two Large Yellowjacket Tarsi in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19633); -- Item: Crude Gauntlets Mold
		elseif(e.message:findi("bravefoot vambraces")) then
			e.self:Say("To assemble Bravefoot Vambraces you will need to obtain two bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this Crude Vambrace Mold. Once that is done combine the Crude Iron Vambraces with a Low Quality Wolf Pelt and two Giant Yellowjacket Tergites in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19635); -- Item: Crude Vambrace Mold
		elseif(e.message:findi("bravefoot greaves")) then
			e.self:Say("To assemble Bravefoot Greaves you will need to obtain two bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this Crude Greaves Mold. Once that is done combine the Crude Iron Greaves with two Low Quality Wolf Pelts and two Giant Yellowjacket Sternites in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19636); -- Item: Crude Greaves Mold
		elseif(e.message:findi("bravefoot breastplate")) then
			e.self:Say("To assemble a Bravefoot Breastplate you will need to obtain four bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this Crude Breastplate Mold. Once that is done combine the Crude Iron Breastplate with a Medium Quality Wolf Pelt and a Giant Yellowjacket Thorax in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19637); -- Item: Crude Breastplate Mold
		elseif(e.message:findi("bravefoot mail boots")) then
			e.self:Say("To assemble Bravefoot Mail Boots you will need to obtain two bricks of crude iron ore and smelt them in a [forge] with a Water Flask and this crude Boot Mold. Once that is done combine the Crude Iron Boots with two Ruined Wolf Pelts. and two Giant Yellowjacket Tarsi in the Mail Assembly Kit.");
			e.other:SummonCursorItem(19634); -- Item: Crude Boot Mold
		end
	end
end

function event_trade(e)
	local item_lib = require("items");
	
	if(eq.is_the_shadows_of_luclin_enabled() and item_lib.check_turn_in(e.self, e.trade, {item1 = 19628})) then
		e.self:Say("Pleased to meet you " .. e.other:GetCleanName() .. "! You must be one of Kayas new trainees. Kaya has asked me to help get you outfitted in a suit of armor to protect you from the vile weapons of Rivervales foes. I have assembled a kit for you that will allow you to construct the armor pieces once you have gathered the necessary components. The required components vary according to which piece of Bravefoot Mail armor you are planning on assembling. Do you wish to craft a [bravefoot helm]. a [bravefoot mail bracer]. [bravefoot gauntlets]. [bravefoot mail boots]. [bravefoot vambraces]. [bravefoot greaves]. or a [bravefoot breastplate].");
		e.other:QuestReward(e.self,0,0,0,0,17124); -- Item: Mail Assembly Kit 
	end
	item_lib.return_items(e.self, e.other, e.trade)
end

-- END of FILE Zone:rivervale  ID:19047 -- Jimji_Bottletoe 