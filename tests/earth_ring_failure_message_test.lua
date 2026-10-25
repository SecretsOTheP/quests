-- Lua 5.1: lua tests/earth_ring_failure_message_test.lua /path/to/Quests
local root = arg[1] or ".";
local checks = 0;
local function check(ok, message) assert(ok, message); checks = checks + 1; end
for _, ring in ipairs({"Mud", "Stone", "Dust", "Vine"}) do
    local file = assert(io.open(root.."/poeartha/encounters/"..ring.."Ring.lua"));
    local source = file:read("*a"); file:close();
    local helper = assert(source:match("(local function FailureMessage%(reason%).-)\nFailRing = function"));
    local format = assert(loadstring(helper.."\nreturn FailureMessage"))();
    local controller = ({Mud=218394, Stone=218395, Dust=218397, Vine=218396})[ring];
    local cases = {
        {"98-minute controller timeout", "The allotted time has passed."},
        {"98-minute attempt expired", "The allotted time has passed."},
        {"orphaned event after script load", "interrupted trial cannot be resumed"},
        {"untracked encounter NPCs after reload", "interrupted trial cannot be resumed"},
        {"required NPC type="..controller.." entity=4107 missing without a confirmed kill", "trial has faded"},
        {"timeout controller failed to spawn", "trial has faded"},
        {"required NPC type=123456 entity=4108 missing without a confirmed kill", "before its defeat"},
        {"encounter callback failed: file.lua:123: required NPC failed to spawn", "The trial cannot continue."},
        {"required gorgers spawn failed", "The trial cannot continue."},
        {"callback error: file.lua:123: unexpected value", "falters unexpectedly"}
    };
    if ring == "Mud" then
        cases[#cases+1] = {"required mudlet expired without a kill", "remained unchallenged for too long"};
        cases[#cases+1] = {"lurker died before required split waves", "before its transformations are complete"};
    end
    for _, case in ipairs(cases) do
        local text = format(case[1]);
        check(text:find(case[2], 1, true), ring.." explains actual failure category");
        check(text:find("The "..ring.." Ring has reset; you may attempt it again in 15 minutes.", 1, true), "retry notice retained");
        check(not text:find("type=") and not text:find("entity=") and not text:find("file.lua", 1, true) and not text:find("Phase:"), "technical details remain private");
    end
end
print("PASS: "..checks.." Earth ring RP message checks");
