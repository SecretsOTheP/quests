-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Greetings " .. e.other:GetCleanName() .. ". If you're looking for your bodies from your encounter in the Sanctus Seru, or your encounter with Grieg Veneficus, you may wish to look near the druid port-in. There seems to be a temporal flux preventing the distribution of corpses to this specific area. Did you happen to murder [Praetorian Ligma] while in Sanctus Seru?");
	elseif(e.message:findi("Ligma")) then
		e.self:Say("You will find no 'Ligma' jokes here.");
		e.self:CastSpell(982,e.other:GetID(),0,1);
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade)
end
