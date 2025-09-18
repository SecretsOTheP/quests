local dt_spellid = 982;    -- (982: Cazic touch, 2859: Touch of Vinitrias
local dt_recast = 60; -- (in seconds)

local ss_recast = 45;
local hc_recast = 15;

local target_mob = nil;
local target_mobtwo = nil;

local deathtouch_active = 0;


local hp_targone = 100;
local hp_targtwo = 100;


function event_spawn(e)
    timer_on = false;    --DT script
end

function event_killed_merit(e)
    e.other:Message(15, "You gain a lack of character flag! Probably some loot, too..");
end

function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(0, "Druzzil Ro's voice echoes within your mind, 'Begone, mortal. The likes of you have no business talking to the likes of a Goddess. I have been observing you, and it appears as though you have regained some of your power from the last time the timeline was reset. But, do you have the power of a Goddess? Unlikely. Attacking me would be futile.'");
		e.other:Message(15, "Every fiber of your being is filled with rage. A mortal's voice enters and pervades your mind, 'Do it. Remember the Quintessence of Time. What we lost as mortals. We can stop her.'");
	end
end

function event_combat(e)
    if (e.joined) then
        if not timer_on then
            eq.depop_all(1501009);
            deathtouch_active = 0;
            hp_targone = 100;
            hp_targtwo = 100;
            e.self:Shout("I warned you, mortal! HAHAHA! Did you think I was ALONE? I am a GOD.");
	    eq.zone_emote(262, "Druzzil begins channeling raw elemental power into her melee attacks!");
            eq.set_timer("SS",3000);    --set initial cast timer
            eq.set_timer("HC",3000);    --set healthCheck timer
            timer_on = true;
        end
    end
end

function event_timer(e)    
    if e.self:IsEngaged() then 
        if e.timer == "SS" then
            target = e.self:GetHateTop();

            if target == nil then
                target = e.self:GetTarget();
            end

             if target:IsPet() then        --Pet check routine
                target = target:GetOwner();        --If pet is at top of hate list then target will change to owner
            end

            e.self:SpellFinished(863,e.self);
            e.self:SpellFinished(861,e.self);
            e.self:Shout("Feel pure magic in your veins!");
            eq.stop_timer(e.timer);
            eq.set_timer("SS",ss_recast*1000);    --restart DT timer for correct recast    
        end
        if e.timer == "HC" then
            eq.unique_spawn(1501009,0,0,e.self:GetX(),e.self:GetY(),e.self:GetZ(),e.self:GetHeading());
            local entity_list = eq.get_entity_list();
            target = entity_list:GetMobByNpcTypeID(1501009);
            if target ~= nil then
                target:AddToHateList(e.self:GetTarget(), 1);
            
            hp_targone = e.self:GetHPRatio();
            hp_targtwo = target:GetHPRatio();

            target_mob = e.self:GetHateTop();
            target_mobtwo = target:GetHateTop();

            if target_mob:GetID() == target_mobtwo:GetID() and target_mob ~= nil and deathtouch_active == 1 then
                eq.zone_emote(262, "Druzzil combines the bear's strength to coordinate and strike the same target!");
                target_mob:Kill();
            end

                if math.abs(hp_targone - hp_targtwo) > 10 then
                    eq.zone_emote(262, "Druzzil gains strength from her uneven wounds.");
                    e.self:Heal();
                    target:Heal();
                end

            eq.stop_timer(e.timer);
            eq.set_timer("HC",hc_recast*1000);    --restart DT timer for correct recast    
            deathtouch_active = 1;
            end        
        end
    else
        timer_on = false;
        eq.stop_timer("HC");
        eq.stop_timer("SS");
        eq.depop_all(1501009);
        hp_targone = 100;
        hp_targtwo = 100;
        deathtouch_active = 0;
    end
end
