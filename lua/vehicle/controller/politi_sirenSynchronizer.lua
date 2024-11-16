-- Authored by NickRyge
-- Intended for use with BeamMP multiplayer, in order to enable that functionality.

local M = {}
local prevHornStatus = 0

local function reset()

end


---The beamng-specific updateGFX function, that runs once per graphics tick.
---@param dt number DeltaTime - see https://en.wikipedia.org/wiki/Delta_timing or the beamng docs.
local function updateGFX(dt)

    -- This might create conflicting sounds for the multiplayer vehicles.
    if electrics.values.horn == 1 and prevHornStatus ~= 1 then
        UpdateSirenCount(1)
    end
    
    prevHornStatus = electrics.values.horn
end


local function init()
end


M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M