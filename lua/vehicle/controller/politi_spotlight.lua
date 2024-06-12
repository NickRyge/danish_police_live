-- Authored by NickRyge

local M = {}

local playerVehPos
local playerVehDir
local spotLight
local spotLightBrick
local spotLightBase
local localDt
--- Horizontal angle in degrees
local prev_hor 
--- Vertical angle in degrees
local prev_ver

local ver_offset = 0
local prev_targetx, prev_targety = 0,0

-- Global variables -- 
Spotlight_on = false
Spotlight_move = true


-- Import test controller 
require "controller.test"


---Clamp function
---@param low number Lowest possible value
---@param n number Real value
---@param high number Highest possible value
---@return number clampValue The clamped value
function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

---Takes the input (prefferably from some input mapping), and adds it to the ver_offset. 
---Clamped to -30, 30
---@param val number The number to add to the ver_offset
function UpdateVerOffset(val) 
    ver_offset = math.clamp(-30, ver_offset + val, 30)
    gui.message("Spotlight offset: " .. ver_offset .. "°")
end

---Resets the vertical offset variable for the spotlight
function ResetVerOffset()
    ver_offset = 0
    gui.message("Spotlight offset: " .. ver_offset .. "°")
end

local function normalize(value, rangeMin, rangeMax)
    local range = rangeMax - rangeMin
    return ((value - rangeMin) % range + range) % range + rangeMin
end

---"Takes a step" from the currentValue to the targetValue. Smoothes according to dt and smoothness
---@param targetValue number The target for the
---@param dt number DeltaTime
---@param currentValue number The current value. Keep in a local variable.
---@param clampMin number min clamp value
---@param clampMax number max clamp value
---@param smoothness number Smoothness factor. Around 5 seems good.
---@return number newValue The value of the step
local function takeStep(targetValue, dt, currentValue, clampMin, clampMax, smoothness)
    -- Normalize the targetValue and currentValue to the range [clampMin, clampMax)
    targetValue = normalize(targetValue, clampMin, clampMax)
    currentValue = normalize(currentValue, clampMin, clampMax)

    -- Calculate the shortest path difference
    local delta = targetValue - currentValue
    local range = clampMax - clampMin
    if delta > range / 2 then
        delta = delta - range
    elseif delta < -range / 2 then
        delta = delta + range
    end

    -- Calculate the step
    local step = delta * dt * smoothness

    -- Compute the new value and normalize it to the range [clampMin, clampMax)
    local newValue = normalize(currentValue + step, clampMin, clampMax)

    return newValue
end


--This has to be global.
-- Callback from the gameengine lua that gets cued on updateGFX
function SetDirVec(vector)

    if not playerInfo.anyPlayerSeated then
        return
    end

    --Seperate the strings on ":" to get each respective vector. 
    local separatorPos = string.find(vector, ":")
    local dirStr = string.sub(vector, 1, separatorPos-1)
    local posStr = string.sub(vector, separatorPos+1)

    --Do this horrible mess to convert the string back to a vector:
    --extract the numbers with regex and convert them to a vec3 using tonumber() on each value.
    local x1, y1, z1 = dirStr:match("vec3%((-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)%)")
    local dirVec = vec3(tonumber(x1), tonumber(y1), tonumber(z1))

    local x2, y2, z2 = posStr:match("vec3%((-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)%)")
    local posVec = vec3(tonumber(x2), tonumber(y2), tonumber(z2))

    --get objects from the mapmgr, then get player vehicle pos and dir vectors.
    --sidenote - objectId always refers to THIS object, as in the object this controller sits on. 
    mapmgr.getObjects()
    if mapmgr.objects[objectId] == nil then
        return
    end
    playerVehPos = mapmgr.objects[objectId].pos
    playerVehDir = mapmgr.objects[objectId].dirVec

    local dirToVeh = vec3(playerVehPos.x - posVec.x, playerVehPos.y - posVec.y, playerVehPos.z - posVec.z)
    dirToVeh:normalize()

    local hor, ver = UpdateSpotlight(posVec, dirVec, playerVehPos, playerVehDir)
    --local vect = UpdateSpotlight(posVec, dirVec, playerVehPos, playerVehDir)

    prev_hor = takeStep(hor, localDt, prev_hor, 0, 360, 4)
    prev_ver = takeStep(ver, localDt, prev_ver, -90, 90, 4)
    local radVer = math.rad(prev_ver)
    local rotX = math.rad(prev_hor)
    local rotY = math.sin(rotX)*radVer
    local rotZ = math.cos(rotX)*radVer*-1

    UpdateProp(spotLight.id, 0, 0, 0, rotX, rotY, rotZ, true, Spotlight_on and 1 or 0, 1)

    UpdateProp(spotLightBase.id, 0, 0, 0, 0, 0, -rotX, true, 0, 1)
    UpdateProp(spotLightBrick.id, 0, 0, 0, radVer, 0, -rotX, true, 0, 1)
end

---comment 
---@param cameraPos any
---@param cameraDir any
---@param vehiclePos any
---@param vehicleDir any
---@return number hor_angle_wrapped The horizontal angle in degrees
---@return number ver_angle The verticle angle in degrees
function UpdateSpotlight(cameraPos, cameraDir, vehiclePos, vehicleDir)
    --First check if the update is valid and there is a player in the car.
    --This is necessary because the function can get called with or without a player, since the lua from GE is queued, and it may be delayed.
    if not playerInfo.anyPlayerSeated or not Spotlight_on then
        return 0, 0
    end

    if not Spotlight_move then
        return prev_targetx, prev_targety
    end

    --Desperate normalize just to make doubly sure.
    cameraDir:normalize()
    vehicleDir:normalize()

    --Get horizontal vectors, cross and dot products.
    --Normalize without the z values to get true angle.
    local horizontalCamVec = vec3(cameraDir.x, cameraDir.y, 0)
    horizontalCamVec:normalize()
    local horizontalVehVec = vec3(vehicleDir.x, vehicleDir.y, 0)
    horizontalVehVec:normalize()

    local horizontalDotproduct= horizontalCamVec.x * horizontalVehVec.x + horizontalCamVec.y * horizontalVehVec.y
    local horizontalCrossproduct = horizontalVehVec:cross(horizontalCamVec)
    local hor_angle = math.deg(math.asin(horizontalCrossproduct.z))
    
    -- EMILS TINGELING:
    -- Meta code: We need to find the angle to rotate the spotlight.
    -- POV position
    -- POV vector
    -- Target position  = POV position + POV vector * dist
    -- Spot vector = Target position - CAR position
    -- Angles between Spot vector and CAR direction

    local targetPos = cameraPos + (cameraDir * 55)
    local spotlightVec = targetPos - vehiclePos
    --local angle1 = (spotlightVec.x * vehicleDir.x + spotlightVec.y + vehicleDir.y) / ()
    --print(spotlightVec.y)
    --print(spotlightVec)

    --Wrap the angle properly
    if horizontalDotproduct < 0 then
        hor_angle = 180 - hor_angle
      end
    local hor_angle_wrapped = hor_angle%360

    if hor_angle_wrapped < 0.01 then
        hor_angle_wrapped = 0.1
    end

    --Vertical angle is a lot easier because it's just two values we depend on, so they can just be subtracted from eachother.
    local ver_angle = math.deg(math.sin(cameraDir.z - vehicleDir.z))
    ver_angle = ver_angle + ver_offset

    prev_targetx, prev_targety = hor_angle_wrapped, ver_angle
    return hor_angle_wrapped, ver_angle
end


local function updateGFX(dt)
    localDt = dt

    --Ideally we need the camera position and direction vectors in order to calculate where the pointlight should look.
    --Unfortunately, core_camera is out of scope of the vehicle VMs, because it sits in the GameEngine VM.

    --Check if there is a player in the car to save resources on GE calls.
    if playerInfo.anyPlayerSeated then

        --Do this function call in order to get access to the core_camera values:
        --Queue lua in GE      |       Queue vehicle lua from GE       |     Call function in this class with an escaped string of the desired vectors seperated on ":" 
        obj:queueGameEngineLua("be:getObjectByID("..tostring(objectId).."):queueLuaCommand('SetDirVec(\"'..tostring(core_camera.getQuat() * vec3(0,1,0))..\":\"..tostring(core_camera.getPosition())..'\")')")
    end
    --The reason it is an escaped string that has to be converted back to a vec3 object is because I don't know how else to escape to get the core_camera value from inside the GE VM.
    --Perhaps I am not smart enough, but at the very least it works. I don't believe it to be too performance expensive, but you never know with hackjobs like these.
end


local function init()
    prev_hor, prev_ver = 0, 0
    localDt = 0
    dirVec = 0
    SetPropsList(v.data.props)
    spotLight = HijackSingleProp("politi_spotlight", "politiSpot")
    spotLightBrick = HijackSingleProp("politi_spotlight_light", "politiSpotBrick")
    spotLightBase = HijackSingleProp("politi_spotlight_base", "politiSpotBase")

end


local function reset()
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M