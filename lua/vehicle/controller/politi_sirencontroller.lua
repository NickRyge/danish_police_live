-- Authored by NickRyge

local M = {}

local createdSounds = false

local currentSiren
local sirenArray = {} 
local prevSirenCount = 0

--how long the player can hold the horn before it no longer counts as a "tap"
local maxHornTapTime -- is set in init

local hornHoldTimer = 0
local isHornHeld = false
local hasExceededHoldTime = false
local prevHornStatus = 0


--local currentSirenCount = 0 -- <- Synchronize this value and ensure it plays from the updateGFX. For multiplayer!


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

    local horn = electrics.values.horn

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

    -- The Chattiest of GPT code blocks. I wanted to do this myself, but prototyping is easier this way.
    -- ALso, there is nothing as permanent as temporary solutions.
    -- Basically tries to determine whether we are holding the horn or not. IRL the horn can be held without switching sirens.
    --
    -- MULTIPLAYER (BeamMP): only the client whose local player is actually seated in
    -- this vehicle may mutate currentSirenCount. On a remote player's car (their copy
    -- running on our PC) playerInfo.firstPlayerSeated is false, so we skip the horn
    -- logic and let the synced currentSirenCount electrics value drive the sound below.
    -- Otherwise the horn edge would be counted once locally AND again on every remote
    -- copy, double-stepping the siren. See MULTIPLAYER_SIREN_SYNC_NOTES.txt.
    if playerInfo.firstPlayerSeated then
        if horn == 1 then
            if not isHornHeld then
                isHornHeld = true
                hornHoldTimer = 0
                hasExceededHoldTime = false
            else
                hornHoldTimer = hornHoldTimer + dt
                if hornHoldTimer > maxHornTapTime then
                    hasExceededHoldTime = true
                end
            end
        elseif horn == 0 and prevHornStatus == 1 then
            if isHornHeld and not hasExceededHoldTime then
                UpdateSirenCount(1)
            end
            -- Reset state
            isHornHeld = false
            hornHoldTimer = 0
            hasExceededHoldTime = false
        end
    end

    -- Runs on every client (seated or not): followers play the synced siren index.
    UpdateSirenSound(electrics.values.currentSirenCount)

    -- Tracked every frame regardless of seating, so entering the vehicle can't
    -- fire a stale horn edge from a press that happened while we weren't seated.
    prevHornStatus = horn
end


---Function to init the controller.
local function init(jbeamData)
    electrics.values.currentSirenCount = 0
    maxHornTapTime = jbeamData.maxHornTime or 0.5
end


M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M