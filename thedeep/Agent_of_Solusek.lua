-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". Do not speak further with me, for I have no [patience] for you. My Sister, the Goddess of Magic, has instructed me to tell you that your bodies from this temple are in The Grey. This entrance only provides a means of entry into the caverns below the Shissar Temple.");
	elseif(e.message:findi("patience")) then
		e.other:Message(13, "You have slightly angered the God of Fire.");
		e.other:Faction(e.self,415,-1,0); -- Faction: Temple of Sol Ro
		e.self:CastSpell(982,e.other:GetID(),0,1);
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
