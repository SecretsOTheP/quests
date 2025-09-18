-- Wolf Meat for Wista

function event_say(e)
	if(e.message:findi("hail")) then
		if(e.other:GetFactionValue(e.self) >= 0) then -- not sure exact faction
			e.self:Say("Hi, " .. e.other:GetCleanName() .. ", do ya likes eatin', or puhaps Hukulk sent ya? I makes many gud eats. Doh, sum I can'ts make cause sum tings I ain't gots. I cud makes some berry tastie stuff wid only [sum wolf meat].");
		else
			e.self:Say("You die! Me Grobb Tradah!  We no frend to you.  You run now!");	
		end
	elseif(e.message:findi("sum wolf meat")) then
		if(e.other:GetFactionValue(e.self) >= 0) then -- not sure exact faction		
			e.self:Say("Gets me two wolf meats sos I cans makes me foods. I gib ya sumting.");
		else
			e.self:Say("You die! Me Grobb Tradah!  We no frend to you.  You run now!");		
		end
	end
end

function event_trade(e)
	local item_lib = require("items");

	local wolf_meat = item_lib.count_handed_item(e.self, e.trade, {13403}, 2);
	if(wolf_meat > 0) then
		repeat
			e.self:Say("Deez berry gud. Makes berry good suff. Me berry happy. Yous gets more bring dem ta mees. Yous takes dis and tanks fer da meats.");
			e.other:Faction(e.self,376,5); -- Faction: Grobb Merchants 
			e.other:QuestReward(e.self,0,math.random(1,3),0,0,0,500);
			wolf_meat = wolf_meat - 1
		until wolf_meat == 0
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
