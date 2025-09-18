function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "Teleportr says, 'None of us are in control of our bodies, just our mouths. [She]'s summoned us here to do her dirty work. I was supposed to be the friendly druid that ports you, but the very essence of my being is mostly gone. Seek the smuggler. Though, if you can't find him, I have some of my power left, and can send you to where I think is my [home]. Mittens is there, he'll guide you.'");
	elseif(e.message:findi("she")) then
		e.other:Message(0, "Teleportr sighs a bit. 'Druzzil. When we breached the Plane of Time, we were teleported here instead of back to where we obtained the Quintessence of Time. She put us to work, teleporting other realities here. Though, for multiple days, we sat - locked in place - until one day for what feels like years when many mortals congregate for maybe two weeks of celebration. She is not in her right mind. Keep an eye on her. The many Norraths we have depend on that.'");
	elseif(e.message:findi("home")) then
		e.other:Message(0,"Teleportr says, 'Farewell, friend. It's the only bit of magic I have. I hope it gets you to the right place. Say hi to Mittens for me.'");
		e.other:MovePC(36, 0, 0, 0, 0);
	end
end
