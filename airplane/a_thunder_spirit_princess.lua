-- Necromancer Epic NPC

function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Greetings, travelers, welcome to the Plane of Sky! We are thunder spirits - this first island is our home. You are welcome to stay here as long as you like. If you wish to go to other islands you may purchase keys from the Key Master.");
	elseif(e.message:findi("gkzzallk")) then
		e.self:Say("Gkzzallk lives far above here. We often take him tea because he's so nice to us fairies! He likes to chat with the others who live here and can often be found in the temple up above. If you give me a bit of money, I can go make sure he is home.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {gold = 10})) then
		e.self:Say("Thank you, " .. e.other:GetCleanName() .. ". I will tell him to expect visitors.");
		eq.unique_spawn(71073,0,0,287.9,662.5,-54.1,109.3); -- NPC: Gkzzallk
	end
end

function event_death_complete(e)
	local sirranName = "sirran";
	sirranName = sirranName .. eq.get_zone_guild_id();
	eq.set_global(sirranName,"1",3,"M20");
	eq.spawn2(71058,0,0,e.self:GetX(), e.self:GetY(), e.self:GetZ(), e.self:GetHeading()); -- NPC: Sirran_the_Lunatic
end

-------------------------------------------------------------------------------------------------
-- Converted to .lua using MATLAB converter written by Stryd
-- Find/replace data for .pl --> .lua conversions provided by Speedz, Stryd, Sorvani and Robregen
-------------------------------------------------------------------------------------------------
