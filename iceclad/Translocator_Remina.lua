function event_say(e)
	if(e.message:findi("hail")) then
			   e.self:Say("It seems like the boats here are malfunctioning. Must be those gnomes, I tell you! I can take you to [North Ro] if you would like.")
	elseif(e.message:findi("North Ro")) then
			   e.self:Say("Teleporting you to North Ro - safe travels!")
			   e.other:MovePC(34, -920, 790, 1, 396)
	end
end