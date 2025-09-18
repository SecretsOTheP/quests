local module = {}

function module.check_dialog(self, other, message)
    if not eq.is_the_scars_of_velious_enabled() then
        return false;
    end

    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if not is_self_found then
        return false;
    end

    local is_level_requirement_met = other:GetLevel() >= 46;
    if message:findi("mind melt") and is_level_requirement_met then
        self:Say("Mind melt poison is what you seek? Ha!! Rogue Extraordinaire I am, and those I can make. Before my hibernal journey, a [fair trade] can we make.");
        return true;
    elseif message:findi("mind melt") and not is_level_requirement_met then
        self:Say("Mind melt poison is what you seek? Ha!! Extras have I but you are too weak!!");
        return true;
    elseif message:findi("fair trade") and is_level_requirement_met then
        self:Say("I call for five things and the poison is yours. I call for Mt. Death Mineral Salts, a Drop of Mercury, an Othmir Fur Cap, a Velium Mastodon Fur,.. and Gold.. 5555 Gold Coins!! This the trade that I call.");
        return true;
    end

    return false;
end

function module.check_turn_in(item_lib, self, other, trade)
    if not eq.is_the_scars_of_velious_enabled() then
        return false;
    end

    local is_self_found = other:IsSelfFound() >= 1 or other:IsSoloOnly() == 1;
    if not is_self_found then
        return false;
    end

    local is_level_requirement_met = other:GetLevel() >= 46;
    if not is_level_requirement_met then
        return false;
    end

    if item_lib.check_turn_in(self, trade, {item1 = 16972, item2 = 22517, item3 = 24989, item4 = 26998, gold = 5555}) then
        self:Say("The time to trade has come!! I am now warm and you are now poor. Take this poison and bother me no more.");
        other:QuestReward(self,0,0,0,0,14098);

        return true;
    end

    return false;
end

return module;