
local function randomFloatWithPrecision(min, max)
  -- Ensure min is less than max
  if min >= max then
    error("Min value must be less than max value")
    return nil
  end

  -- 1. Generate a random float between 0.0 (inclusive) and 1.0 (exclusive).
  local randomBase = math.random()

  -- 2. Scale the random number to the desired range [min, max).
  local scaledNum = min + randomBase * (max - min)

  -- 3. Format the number to exactly two decimal places.
  -- string.format returns a string, so we convert it back to a number.
  local formattedNumString = string.format("%.2f", scaledNum)
  local finalNum = tonumber(formattedNumString)

  return finalNum
end

function event_spawn(e)

local min_value = 1.0
local max_value = 1.25
local random_float = math.random(1, math.floor((max_value - min_value) * 100)) / 100 + min_value
e.self:SetRunspeed(random_float)

end