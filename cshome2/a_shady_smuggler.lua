local function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

local hidesay = true;
local function MLM(e, t)
	local s = "";
	local i = 0;
	for k,v in pairsByKeys(t) do 
		if i > 0 then s = s .. " - " end
		if v.c == nil or e.other:GetGM() or v.c(e) or eq.get_data(e.other:CharacterID() .. "-" .. k) ~= "" then
			s = s .. eq.say_link(k, hidesay, v.s);
		else
			s = s .. v.s
		end
		i = i + 1;
		if i == 5 then
			e.other:Message(15,s);
			s = "";
			i = 0;
		end
	end
	if(i > 0) then
		e.other:Message(15,s);
	end
end

local callbacks = {
	cities = {
		akanon = {s = "Ak'Anon", 					f = function(e) e.other:MovePC(55, -35, 47, 4, 0) end, c = function(e) return true end},
		erudnext = {s = "Erudin", 					f = function(e) e.other:MovePC(24, -338, 75, 20, 0) end, c = function(e) return true end},
		erudnint = {s = "Erudin Palace", 			f = function(e) e.other:MovePC(23, 808, 712, 21, 0) end, c = function(e) return true end},
		felwithea = {s = "Northern Felwithe", 		f = function(e) e.other:MovePC(61, 94, -25, 3, 0) end, c = function(e) return true end},
		felwitheb = {s = "Southern Felwithe", 		f = function(e) e.other:MovePC(62, -790, 320, -10, 0) end, c = function(e) return true end},
		freporte = {s = "East Freeport", 			f = function(e) e.other:MovePC(10, -648, -1097, -52.2, 0) end, c = function(e) return true end},
		freportn = {s = "North Freeport", 			f = function(e) e.other:MovePC(8, 211, -296, 4, 0) end, c = function(e) return true end},
		freportw = {s = "West Freeport", 			f = function(e) e.other:MovePC(9, 181, 335, -24, 0) end, c = function(e) return true end},
		kelethin = {s = "Kelethin", 				f = function(e) e.other:MovePC(54, -136, -30, 78, 255) end, c = function(e) return true end},
		grobb = {s = "Grobb", 						f = function(e) e.other:MovePC(52, 0, -100, 3, 0) end, c = function(e) return true end},
		halas = {s = "Halas", 						f = function(e) e.other:MovePC(29, 0, 0, 3, 0) end, c = function(e) return true end},
		kaladima = {s = "South Kaladim", 			f = function(e) e.other:MovePC(60, -2, -18, 3, 0) end, c = function(e) return true end},
		kaladimb = {s = "North Kaladim", 			f = function(e) e.other:MovePC(67, -267, 414, 3.75, 0) end, c = function(e) return true end},
		neriaka = {s = "Neriak Foreign Quarter", 	f = function(e) e.other:MovePC(40, 157, -3, 31, 0) end, c = function(e) return true end},
		neriakb = {s = "Neriak Commons", 			f = function(e) e.other:MovePC(41, -500, 3, -10, 0) end, c = function(e) return true end},
		neriakc = {s = "Neriak 3rd Gate", 			f = function(e) e.other:MovePC(42, -969, 892, -52, 0) end, c = function(e) return true end},
		oggok = {s = "Oggok", 						f = function(e) e.other:MovePC(49, -99, -345, 4, 0) end, c = function(e) return true end},
		paineel = {s = "Paineel", 					f = function(e) e.other:MovePC(75, 200, 800, 3, 0) end, c = function(e) return true end},
		qcat = {s = "Qeynos Aqueduct System", 		f = function(e) e.other:MovePC(45, 80, 860, -38, 0) end, c = function(e) return true end},
		qeynos = {s = "South Qeynos",				f = function(e) e.other:MovePC(1, 0, 10, 5, 0) end, c = function(e) return true end},
		qeynos2 = {s = "North Qeynos", 				f = function(e) e.other:MovePC(2, -74, 428, 3, 0) end, c = function(e) return true end},
		rivervale = {s = "Rivervale", 				f = function(e) e.other:MovePC(19, 0, 0, 4, 0) end, c = function(e) return true end},
		surefall = {s = "Surefall Glade", 			f = function(e) e.other:MovePC(3, 0, 0, 2, 0) end, c = function(e) return true end},
	}
};
callbacks.menu = {
	cities = {s = eq.say_link("cities", hidesay, "[Ask about Cities..]"), f = function(e) MLM(e, callbacks.cities) end},
	--functions = {s = eq.say_link("functions", hidesay, "[Set the dial to Functions..]"), f = function(e) for k,v in pairsByKeys(eq) do e.other:Message(15,k) end end, c = function(e) return e.other:GetGM() end},
};

function event_say(e)
	if(e.message:findi("hail")) then
		e.other:Message(15,"The shady smuggler whispers to you, 'Greetings, friend. Druzzil has certainly done it again. She's put you in prison! You're lucky you escaped. I can get you out of here. Just tell me where you would like to go.");
		for k,v in pairsByKeys(callbacks.menu) do
			if (v.c == nil or e.other:GetGM() or v.c(e)) then
				e.other:Message(15,v.s);
			end
		end
		return;
	end
	for k,v in pairs(callbacks) do
		if v[e.message] and ( v[e.message].c == nil or e.other:GetGM() or v[e.message].c(e) or eq.get_data(e.other:CharacterID() .. "-" .. e.message) ~= "") then
			v[e.message].f(e);
			return;
		end
	end
end
