local M = {}

local playerVehPos
local playerVehDir
local currentValueRight = 0


local function takeStep(targetValue, target, dt, currentValue, clampMin, clampMax, smoothness)
  
      --Clamp the targetValue according to the min and max which allows for an offset to occur.
      local step = (targetValue - currentValue) * dt * smoothness --5.2
  
      --local newValue = math.clamp(currentValue + step, clampMin, clampMax)
      --Testing if I can rely only on clamping the target value
      local newValue = (currentValue+step)%360
      print(newValue)
        
      return newValue
end

local function updateGFX(dt)
      
    val = val + direction   
  
    if val == 360 or val == 0 then
      direction = -direction
    end

    val2 = val2 + direction2   
  
    if val2 == 180 or val2 == 0 then
      direction2 = -direction2
    end
    --print(electrics.values.testvalue)

    --print(electrics.values.testvalue)
    --print(tostring(electrics.values.testvalue2) .. "<-")

    --c = math.sqrt((0.6^2 + 5^2) - (2 * 5 * 0.6 * math.cos(math.rad(val))))
    --c2 = math.sqrt((0.6^2 + 5^2) - (2 * 5 * 0.6 * math.cos(math.rad(val2))))
    sth = 360
    --c = math.sqrt((0.6^2 + 5^2) - (2 * 5 * 0.6 * math.cos(math.rad(sth))))
    --c2 = math.sqrt((0.6^2 + 5^2) - (2 * 5 * 0.6 * math.cos(math.rad((sth+90)%360))))
    --print(c)

    --val = (val + 1)%360
    --val2 = ((val + 1)-180)%360
    --print(electrics.values.testvalue)
    
    --electrics.values.testvalue = c-5.03587132
    --electrics.values.testvalue2 = c2-5.03587132

    val3 = (val3 + 1)%360 

    currentValueRight = takeStep(270, "testvalue", dt, currentValueRight, 0, 360, 0.5)
    electrics.values.testvalue = math.sin(math.rad(currentValueRight))*0.6
    electrics.values.testvalue2 = math.cos(math.rad(currentValueRight))*0.6
    --electrics.values.testvalue = math.sin(math.rad(val3))*0.6
    --electrics.values.testvalue2 = math.cos(math.rad(val3))*0.6
end




local function init()
    currentValueRight = 0
    direction = 1
    direction2 = 1  
    val = 0
    val3 = 0
    val2 = 90
    electrics.values.testvalue = 0
end


M.reset = init
M.init = init
M.updateGFX = updateGFX

return M
