function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "King Mortenson says, 'I am DA BESTEST BARD! I SING GUD! MOVED HERE FROM KERRA, I DID. You [BASH HARD]?'");
	elseif(e.message:findi("Bash hard")) then
		e.other:Message(0,"Mortenson says, 'GUD! CONTINUE BASHING! THESE SCRIPTS WONT WRITE THEMSELVES!'");
		e.other:Message(15,"You notice something interesting about the bard, that he may not be what he seems. [Who did he used to be?]");
	elseif(e.message:findi("who")) then
		e.other:Message(15,"Intrusive thoughts from an extraplanar dimension enter your mind, 'That's Mortenson. He was an early friend of ours. Our CSR lead and I met while working under him. In a way, he's responsible for me continuing to learn and eventually creating Project Quarm. So, thank you, in the weirdest way, KingMort.'");
		e.other:Message(0,"Mortenson says, 'Buuuuurp! That [drinky bit] waz great!'");
	elseif(e.message:findi("drinky bit")) then
		e.other:Message(0,"Mortenson says, 'YEAH! You want dat drinky bit too? Here yooz go!'");
		e.other:SummonCursorItem(8991);
	end
end
