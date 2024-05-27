-- Authored by NickRyge

local M = {}

local playerVehPos
local playerVehDir
local spotLight
local localDt
--- Horizontal angle in degrees
local prev_hor 
--- Vertical angle in degrees
local prev_ver


-- Import test controller 
require "controller.test"


---comment
---@param low number Lowest possible value
---@param n number Real value
---@param high number Highest possible value
---@return number clampValue The clamped value
function math.clamp(low, n, high) return math.min(math.max(n, low), high) end



function normalize(value, rangeMin, rangeMax)
    local range = rangeMax - rangeMin
    return ((value - rangeMin) % range + range) % range + rangeMin
end

function takeStep(targetValue, dt, currentValue, clampMin, clampMax, smoothness)
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

    prev_hor = takeStep(hor, localDt, prev_hor, 0, 360, 5)
    prev_ver = takeStep(ver, localDt, prev_ver, -90, 90, 5)
    local radVer = math.rad(prev_ver)
    local rotX = math.rad(prev_hor)
    local rotY = math.sin(rotX)*radVer
    local rotZ = math.cos(rotX)*radVer*-1

    UpdateProp(spotLight.id, 0, 0, 0, rotX, rotY, rotZ, false, 1, 1)
    

    --UpdateProp(spotLight.id, 0, 0, 0, 
    --            0, -- Yaw - Positive: Left. Negative: Right. 
    --            0, -- Roll - Irrelevant.  
    --            0, -- Pitch - Negative: Up. Positive: Down. 
    --            false, 1, 1)
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
    if not playerInfo.anyPlayerSeated then
        return 0, 0
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
    print(spotlightVec)

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

    --print(cameraPos-vehiclePos)
    --print("Omdrejning: " .. hor_angle_wrapped)
    --print("Op-ned: " .. ver_angle)
    --print(hor_angle_wrapped)

    return hor_angle_wrapped, ver_angle
    --return spotlightVec
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
end

local function reset()
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M