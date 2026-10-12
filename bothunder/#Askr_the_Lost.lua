local FlaggingTravel = require("flagging_travel");

function event_say(e)
	if not FlaggingTravel.CanUse(e.self) then return; end
	if ( e.message:findi("hail") ) then 
		e.self:Say("Well done.  I did not believe you could have progressed so far, so quickly.  Evynd was one of Agnarr's greatest lieutenants; your victory could not have been easy.  I fear, however, that your task will only become more difficult from here.  With Evynd dead, I can now help you to ascend to the next level.  When you are ready, simply ask and I will [transport] you to the [next level of Torden], but make haste, I cannot stay here for long.");
		
	elseif ( e.message:findi("transport") ) then
	
		e.other:CastToClient():MovePC(209, -880, -1787, 1729, 192*2);
		if ( e.other:GetPet().valid and not e.other:GetPet():Charmed() ) then
			e.other:GetPet():GMMove(-880, -1787, 1729, 0);
		end
	end
end

function event_spawn(e)
	FlaggingTravel.Start(e.self, 209136);
end

function event_timer(e)
	FlaggingTravel.OnTimer(e);
end
