local t = { ignored_words = { set = true, lastname = true } };

-- The title system works dynamically based on a tag system.
-- Words can be appended to the lastname as long as the tag system does not block that tag.
-- As words are added, more and more tags are disabled, to prevent using incompatible titles/words together, or in the wrong order.

-- Example: /say set lastname Smith the_Reborn III
-- [set lastname] is the NPC keyword
-- If 'Smith' is their current lastname, 'Smith' matches to it.
-- 'the_Reborn' matches to an unlocked title if they have done NG+.
-- 'III' matches to an unlocked word (their NG+ reward roman numeral)
-- Their name becomes John Smith the Reborn III.

-- Invalid Example: /say set lastname the_Reborn Smith
-- When 'the_Reborn' is added, the tag 'lastname' is disabled
-- Attempting to add 'Smith' will fail in this position.

-- This function computes a player's options for titles.
-- Due to title combination complexity, the logic of how they combine is all defined here, based on the tags they get.
function t.GetOptions(e)

	local state = { has_lastname = false, names = {}, blocked_tags = {} };

	-- Allow their current base lastname.
	local lastname = e.other:GetProfileLastName(); -- Returns just their base last-name, without all the titles.
	if (lastname and lastname:len() > 0) then
		t.Register(e, state, lastname, {"lastname"}, {});
		state.has_lastname = true;
	end

	-- Allow their NG+ Rewards
	local rebirthCount = e.other:GetTimesRebirthed();
	if (rebirthCount >= 1) then
		-- Main title and unlocked numerals
		t.Register(e, state, "the_Reborn", {"title"}, {"lastname","the_ng_numeral"});
		for i = 1, rebirthCount do
			local numeral = t.RomanNumeral(e, i);
			local the_numeral = "the_" .. numeral;
			t.Register(e, state, numeral, {"ng_numeral"}, {"lastname"});
			t.Register(e, state, the_numeral, {"ng_numeral", "the_ng_numeral"}, {"lastname", "title"});
		end
	end
	return state;
end

-- This function registers a selectable word for the the player to build a lastname with.
-- * name: The word/title to add to the name.
-- * my_tags: The tags associated with this word. The word can only be added to the name if none of these tags have been used or blocked.
-- * exclude_tags: Once this word is added to the name, the exclude_tags will also be blocked from being added to the name, in addition to its 'my_tags'.
function t.Register(e, state, name, my_tags, exclude_tags)
	state.names[name] = { name = name, tags = my_tags, exclude_tags = exclude_tags };
end

-- Entrypoint for all quest dialog
function t.HandleName(e)
	if (e.message:findi("set lastname")) then
		if (t.TryApply(e)) then
			return true;
		end
	elseif (e.message:findi("remove surname")) then
		if (e.message:findi("correct")) then
			e.other:ChangeLastName("");
			e.other:Message(15, "Your surname has been removed.");
		else
			e.other:Message(15, "Your surname will be removed, are you sure? Repeat this message with 'correct' to confirm. There is a 7-day cooldown between uses of /surname.");
		end
		return true;
	end
	t.PrintOptions(e);
	return true;
end

function t.PrintOptions(e)

	local state = t.GetOptions(e);

	-- Make a sorted list by length of all their word options.
	local strings = {};
	local count = 0;
	for word,_ in pairs(state.names) do
		count = count + 1;
		strings[count] = word;
	end
	table.sort(strings, function(a, b) 
		return #a > #b;
	end);

	local has_titles = (count > 1) or (count >= 1 and not state.has_lastname);
	if (has_titles) then
		e.self:Say("Many titles suit one such as you, " .. e.other:GetCleanName() .. ". Decide which will adorn your name.");
	else
		e.self:Say("You lack renown, " .. e.other:GetCleanName() .. ". Venture forth into the world, face its challenges, and earn the titles that will define your legacy.");
	end

	local cur_lastname = e.other:GetLastName(); -- Their full last name, if any.
	local cur_profile_lastname = e.other:GetProfileLastName(); -- Just their /surname value, if any.

	if (count == 0) then
		e.other:Message(15, "Available name components: None");
		if (cur_lastname and cur_lastname:len() > 0) then
			e.other:Message(15, "To clear your current lastname, say 'set lastname'.");
			e.other:Message(15, "You will have a chance to confirm your choice before it is applied.");
		end
	else
		e.other:Message(15, "You may choose combinations of the following words to create your full last name:");
		for i, str in ipairs(strings) do
			e.other:Message(15, " - " .. str .. "");
		end
		if (count > 1) then
			e.other:Message(15, "Some words can only be used in certain orders or combinations.");
		end
		if (cur_lastname and cur_lastname:len() > 0) then
			e.other:Message(15, "Say 'set lastname' followed by the words you choose, in the order you would like them. For an empty name, just say 'set lastname'.");
		else
			e.other:Message(15, "Say 'set lastname' followed by the words you choose, in the order you would like them.");
		end
		if (not cur_profile_lastname or cur_profile_lastname:len() == 0) then
			e.other:Message(15, "You may also use your surname in this combination, but first you must create one with /surname. There is a 7-day cooldown between /surname uses.");
		else
			e.other:Message(15, "Say 'remove surname' to choose a new surname with /surname. There is a 7-day cooldown between /surname uses.");
		end
		e.other:Message(15, "You will have a chance to confirm your choice before it is applied.");
	end
end

function t.EqConcat(str1, str2)
	if (str1:len() == 0) then
		return str2;
	elseif (str2:len() == 0) then
		return str1;
	else
		return str1 .. "_" .. str2;
	end
end

function t.TryApply(e)

	local state = t.GetOptions(e);
	local confirmed = false;
	local builder = "";

	for word in string.gmatch(e.message, "%S+") do
		if (word == "correct") then
			confirmed = true;

		elseif (state.names[word]) then
			local cfg = state.names[word];
			-- See if this word is blocked
			for _, tag in ipairs(cfg.tags) do
				for blocked_tag, blocked_by in pairs(state.blocked_tags) do
					if (tag == blocked_tag) then
						e.other:Message(13, "You cannot use '" .. word .. "' in this position. This is not allowed after '" .. blocked_by .. "' has been used.");
						return true;
					end
				end
			end
			-- Word is allowed, append it
			builder = t.EqConcat(builder, word);
			-- Block all the tags associated with the word we just added
			for _, tag in ipairs(cfg.tags) do
				state.blocked_tags[tag] = word;
			end
			for _, tag in ipairs(cfg.exclude_tags) do
				state.blocked_tags[tag] = word;
			end

		elseif (not t.ignored_words[word]) then
			e.other:Message(13, "Unknown keyword used: '" .. word .. "'");
			return false;
		end
	end

	if (builder:len() > 31) then
		e.other:Message(13, "Your name is too long, pick a shorter name.");
		return true;
	end

	local pretty_full_name = t.EqConcat(e.other:GetCleanName(), builder):gsub("_", " ");
	if (not confirmed) then	
		e.other:Message(15, "Your full name will become: " .. pretty_full_name .. ". Is this 'correct'? Repeat the same message with 'correct' to continue.");
	else
		if (builder:len() > 0) then
			e.other:SetTemporaryCustomizedLastName(builder);
		else
			e.other:SetTemporaryCustomizedLastName("_");
		end
		e.other:Message(15, "Your are now: " .. pretty_full_name .. ".");
	end
	return true;
end

function t.RomanNumeral(e, num)

    -- Table of Roman numeral mappings
    local romanNumerals = {
        {1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"},
        {100, "C"}, {90, "XC"}, {50, "L"}, {40, "XL"},
        {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"},
        {1, "I"}
    };

    local result = "";

    -- Iterate through the numeral mappings
    for _, pair in ipairs(romanNumerals) do
        local value, symbol = pair[1], pair[2];
        while num >= value do
            result = result .. symbol;
            num = num - value;
        end
    end

    return result;
end

return t;