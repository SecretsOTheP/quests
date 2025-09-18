function event_say(e)
	if(e.message:findi("Hail")) then
		e.self:Say("Hello there, " .. e.other:GetCleanName() .. ". There seem to be some strange problems with the boats in this area. The Academy of Arcane Sciences has sent a small team of us to investigate them. In the meantime, I can transport you to my companion there if you wish to [travel to Timorous Deep].");
	elseif(e.message:findi("timorous deep")) then
		e.self:CastSpell(2291,e.other:GetID()); -- Spell: Portal to Timorous (ogre camp)
		e.self:Say("Off you go!");
	elseif(e.message:findi("I am cis")) then
		e.self:Say("Ah. Then you might be needing my brother, Cislocator instead. He should be close by!");
	elseif(e.message:findi("I am trans")) then
		e.self:Say("Ah. Then you came to the right place! I can trans port you to my companion there if you wish to [travel to Timorous Deep].");
	elseif(e.message:findi("I am nonbinary")) then
		e.self:Say("If you are, then how are we communicating?");
	end
end
