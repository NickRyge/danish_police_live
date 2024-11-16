-- Authored by NickRyge

local M = {}

local createdSounds = false

local currentSiren
local sirenArray = {}
local prevHornStatus = 0
local prevSirenCount = 0

--local currentSirenCount = 0 -- <- Synchronize this value and ensure it plays from the updateGFX. 


---Function that plays a specified soundscape sound.
---@param siren v.data.soundscape Siren from the soundscape table to play.
local function playSiren(siren)
    currentSiren = siren
    obj:setVolume(currentSiren, 1)
    obj:playSFX(currentSiren)
    print(currentSiren)
end


---Funciton that stops a specified soundscape sound.
---@param siren v.data.soundscape Siren from the soundscape table to stop.
local function stopSiren(siren)
    print("stopped " .. siren)
    obj:cutSFX(siren)
end


---Called to reset the sirenController back to 0.
local function reset()
    electrics.values.currentSirenCount = 0

    if currentSiren ~= nil then
        stopSiren(currentSiren)
    end
end


---Updates which siren currently plays. Skips the val amount of sirens ahead.
---@param val number The number of sirens to skip. Default is 1, to play the next siren.
function UpdateSirenCount(val)
    electrics.values.currentSirenCount = ((electrics.values.currentSirenCount + val) % (#sirenArray + 1))
    print(electrics.values.currentSirenCount)
end



local function UpdateSirenSound(val)
    if (prevSirenCount ~= val and currentSiren ~= nil) then
        stopSiren(sirenArray[prevSirenCount]) -- bad
    end
    if (val == 0) then
        currentSiren = nil
    elseif prevSirenCount ~= val then
        playSiren(sirenArray[val]) -- bad
    end
    prevSirenCount = val
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

    -- Ideally the below should be replaced with a controller that the multiplayer
    -- clients cant interfere with.
    if currentSiren ~= nil and electrics.values["lightbar"] < 1 then
        reset()
    elseif electrics.values["lightbar"] < 1 then
        return
    end

    -- This might create conflicting sounds for the multiplayer vehicles.
    if electrics.values.horn == 1 and prevHornStatus ~= 1 then
        UpdateSirenCount(1)
    end

    UpdateSirenSound(electrics.values.currentSirenCount)

    prevHornStatus = electrics.values.horn
end


---Function to init the controller.
local function init()
    electrics.values.currentSirenCount = 0
end


M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M