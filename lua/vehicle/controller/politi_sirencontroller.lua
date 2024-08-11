-- Authored by NickRyge

local M = {}

local createdSounds = false

local currentSiren
local sirenArray = {}
local prevHornStatus = 0
local currentSirenCount = 0


---Function that plays a specified soundscape sound.
---@param siren v.data.soundscape Siren from the soundscape table to play.
local function playSiren(siren)
    currentSiren = siren
    obj:setVolume(currentSiren, 1)
    obj:playSFX(currentSiren)
    -- print(currentSiren)
end


---Funciton that stops a specified soundscape sound.
---@param siren v.data.soundscape Siren from the soundscape table to stop.
local function stopSiren(siren)
    obj:cutSFX(siren)
end


---Called to reset the sirenController back to 0.
local function reset()
    currentSirenCount = 0

    if currentSiren ~= nil then
        stopSiren(currentSiren)
    end
end


---Updates which siren currently plays. Skips the val amount of sirens ahead.
---@param val number The number of sirens to skip. Default is 1, to play the next siren.
local function UpdateSirenSound(val)

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


---Initializes the controller by creating the soundscapesounds for each siren found.
---Dynamically discovers all sirens a car has and readies them.
local function startup()
    for soundName, _ in pairs(v.data.soundscape) do
        if (string.find(soundName, "siren")) then
            table.insert(sirenArray, sounds.createSoundscapeSound(soundName))
        end
    end
end


---The beamng-specific updateGFX function, that runs once per graphics tick.
---@param dt number DeltaTime - see https://en.wikipedia.org/wiki/Delta_timing or the beamng docs.
local function updateGFX(dt)
    -- Must be done here, init loads too quickly to work properly.
    if not createdSounds then
        startup()
        createdSounds = true
    end

    if currentSiren ~= nil and electrics.values["lightbar"] < 1 then
        reset()
        return
    end

    if electrics.values.horn == 1 and prevHornStatus ~= 1 then
        UpdateSirenSound(1)
    end

    prevHornStatus = electrics.values.horn
end


---Function to init the controller.
local function init()
    --Placeholder, doesn't do anything right now.
end


M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M