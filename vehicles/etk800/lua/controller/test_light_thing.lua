local M = {}

local playerVehPos
local playerVehDir

--This has to be global.
function SetDirVec(vector)

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

    electrics.values["shithead"] = UpdateSpotlight(posVec, dirVec, playerVehPos, playerVehDir)
    --print(electrics.values["shithead"])

end

function UpdateSpotlight(cameraPos, cameraDir, vehiclePos, vehicleDir)
    --First check if the update is valid and there is a player in the car.
    --This is necessary because the function can get called with or without a player, since the lua from GE is queued, and it may be delayed.
    if not playerInfo.anyPlayerSeated then
        return
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

    --Wrap the angle properly
    if horizontalDotproduct < 0 then
        hor_angle = 180 - hor_angle
      end
    local hor_angle_wrapped = hor_angle%360

    if hor_angle_wrapped < 0.01 then
        hor_angle_wrapped = 0.1
    end

    --Vertical angle is a lot easier because it's just two values we depend on, so they can just be subtracted from eachother.
    local ver_angle = math.deg(math.asin(cameraDir.z - vehicleDir.z))



    return hor_angle_wrapped
end

local function updateGFX(dt)
    
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
    dirVec = 0
end

M.reset = init
M.init = init
M.updateGFX = updateGFX

return M
