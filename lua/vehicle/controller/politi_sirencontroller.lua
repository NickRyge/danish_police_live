-- Authored by NickRyge

local M = {}


local createdSounds = false

local currentSiren
local sirenArray = {}
local currentSirenCount = 0




local function playSiren(siren)
    currentSiren = siren
    print(currentSiren)
    obj:setVolume(currentSiren, 1)
    obj:playSFX(currentSiren)
end

local function stopSiren(siren) 
    obj:cutSFX(siren)
end

local function reset()
    currentSirenCount = 0

    if currentSiren ~= nil then
        stopSiren(currentSiren)
    end
end


function UpdateSirenSound(val)


    if (currentSiren ~= nil) then 
        stopSiren(currentSiren)
    end

    currentSirenCount = ((currentSirenCount + val) % (#sirenArray + 1))
    print(currentSirenCount)

    if (currentSirenCount == 0) then
        currentSiren = nil
    else
        playSiren(sirenArray[currentSirenCount])
    end

end


local function startup() 
    for key, value in pairs(v.data.soundscape) do
        if (string.find(key, "siren")) then
            table.insert(sirenArray, sounds.createSoundscapeSound(key))
        end
    end
end


local function updateGFX(dt)
    -- for some reason this must be done once and for all, and doesn't work in INIT. >:|
    if not createdSounds then
        startup()
        createdSounds = true
    end

    if currentSiren ~= nil and electrics.values["lightbar"] < 1 then
        reset()
    end
end



local function init()

end



M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M