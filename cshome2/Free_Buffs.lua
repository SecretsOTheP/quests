function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "Free Buffs says, 'Please... kill me... or... just say [buffs], Gods help me... she's-... she's forced us to do her bidding. Seek the smuggler for escape.'");
	elseif(e.message:findi("buffs")) then
		e.other:SpellFinished(226, e.other);
		e.other:Message(0,"Free Buffs says, 'It's all I have left to spare... she's drained me of all my mana and put me in servitude here. Go. Leave this place. Find the smuggler.'");
	end
end
