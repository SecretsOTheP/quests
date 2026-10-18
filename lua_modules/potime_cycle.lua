-- Fixed guild-cycle metadata, independent of the attempt clock and loot timers.
local cycle = { duration = 6 * 86400 + 18 * 3600, empty_grace = 600 };

function cycle.new(now, checkpoint)
    return { started = now, ends = now + cycle.duration, checkpoint = checkpoint == true };
end

function cycle.decode(value)
    if value == nil then return nil, true end
    if type(value) ~= "string" then return nil, false end
    local started, ends, checkpoint = value:match("^(%d+);(%d+);([01])$");
    started, ends = tonumber(started), tonumber(ends);
    if not started or not ends or started <= 0 or ends == math.huge
        or ends - started ~= cycle.duration then return nil, false end
    return { started = started, ends = ends, checkpoint = checkpoint == "1" }, true;
end

function cycle.encode(value)
    return string.format("%d;%d;%d", value.started, value.ends, value.checkpoint and 1 or 0);
end

function cycle.expired(value, now)
    return value ~= nil and now >= value.ends;
end

return cycle;
