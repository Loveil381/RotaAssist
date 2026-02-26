------------------------------------------------------------------------
-- RotaAssist - Spec Detector
-- Detects current player class/specialization and loads APL data.
-- Monitors PLAYER_SPECIALIZATION_CHANGED for live updates.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local SpecDetector = {}
RA:RegisterModule("SpecDetector", SpecDetector)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

---@class SpecInfo
---@field classID number
---@field specID number
---@field className string Localized class name
---@field specName string Localized spec name
---@field role string "DAMAGER" | "HEALER" | "TANK"
---@field classFile string Uppercase english class token (e.g. "WARRIOR")
---@field icon number Texture ID of the specialization icon

---@type SpecInfo|nil
local currentSpec = nil

------------------------------------------------------------------------
-- Detection Logic
------------------------------------------------------------------------

---Query WoW API for the current class/spec details.
---@return SpecInfo|nil specInfo
local function detectSpec()
    local specIndex = GetSpecialization()
    if not specIndex then
        RA:PrintDebug("SpecDetector: No specialization selected")
        return nil
    end

    local specID, specName, _, specIcon, role = GetSpecializationInfo(specIndex)
    if not specID then
        RA:PrintDebug("SpecDetector: GetSpecializationInfo returned nil")
        return nil
    end

    local _, className, classID = UnitClass("player")

    local info = {
        classID   = classID,
        specID    = specID,
        className = className,
        specName  = specName,
        role      = role,
        classFile = className,  -- e.g. "WARRIOR", "MAGE"
        icon      = specIcon,
    }

    return info
end

---Load the APL definition for the current spec (if available).
---@param specInfo SpecInfo
local function loadAPLForSpec(specInfo)
    -- APL modules register themselves in RA.APLData[specID]
    if not RA.APLData then
        RA:PrintDebug("SpecDetector: No APL data table found")
        return
    end

    local aplData = RA.APLData[specInfo.specID]
    if aplData then
        -- NOTE: Devourer DH uses specID 1480 (no conflict with Evoker Augmentation 1473).
        -- classID cross-check is kept as a general safety mechanism.
        local validClass = aplData.class
        if validClass and validClass ~= specInfo.classFile then
            RA:PrintDebug(string.format(
                "SpecDetector: APL class mismatch for specID %d (APL=%s, player=%s) — skipping",
                specInfo.specID, validClass, specInfo.classFile))
            return
        end

        RA:PrintDebug(string.format("SpecDetector: Loaded APL for %s %s (specID %d)",
            specInfo.className, specInfo.specName, specInfo.specID))

        local aplEngine = RA:GetModule("APLEngine")
        if aplEngine and aplEngine.SetAPL then
            aplEngine:SetAPL(specInfo.specID, aplData, specInfo.classID)
        end
    else
        RA:PrintDebug(string.format("SpecDetector: No APL found for specID %d", specInfo.specID))
    end
end

---Run full detection and update internal state.
local function refreshSpec()
    local newSpec = detectSpec()
    if not newSpec then return end

    local changed = (not currentSpec) or (currentSpec.specID ~= newSpec.specID)
    currentSpec = newSpec

    if changed then
        RA:PrintDebug(string.format("SpecDetector: Detected %s %s (%s)",
            currentSpec.className, currentSpec.specName, currentSpec.role))

        loadAPLForSpec(currentSpec)

        -- Notify other modules
        local eh = RA:GetModule("EventHandler")
        if eh and eh.Fire then
            eh:Fire("ROTAASSIST_SPEC_CHANGED", currentSpec)
        end
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function SpecDetector:OnInitialize()
    -- Nothing needed before enable
end

function SpecDetector:OnEnable()
    -- Subscribe to spec change event
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_SPECIALIZATION_CHANGED", "SpecDetector", function()
            RA:PrintDebug("SpecDetector: Specialization changed event")
            refreshSpec()
        end)

        -- Subscribe to PLAYER_ENTERING_WORLD for initial login / reload detection
        eh:Subscribe("PLAYER_ENTERING_WORLD", "SpecDetector", function()
            RA:PrintDebug("SpecDetector: PLAYER_ENTERING_WORLD — scheduling delayed refresh")
            C_Timer.After(0.5, function()
                refreshSpec()
            end)
        end)
    end

    -- Immediate fallback: try to detect spec right now in case events already fired
    refreshSpec()
end

function SpecDetector:OnPlayerEnteringWorld(isInitialLogin, isReloadingUi)
    -- Detect spec on initial load or UI reload
    refreshSpec()
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the current player class/spec information.
---@return SpecInfo|nil info Table with classID, specID, className, specName, role, classFile, icon
function SpecDetector:GetCurrentSpec()
    if not currentSpec then
        refreshSpec()
    end
    return currentSpec
end

---Check if the player is a specific role.
---@param role string "DAMAGER" | "HEALER" | "TANK"
---@return boolean
function SpecDetector:IsRole(role)
    return currentSpec and currentSpec.role == role
end

---Get the spec ID key used for APL data lookup.
---@return number|nil specID
function SpecDetector:GetSpecID()
    return currentSpec and currentSpec.specID
end

---Get the primary power type for the current spec.
---Reads from SpecEnhancements[specID].resource.type.
---@return number|nil powerType  Enum.PowerType value, or nil if unknown
function SpecDetector:GetPrimaryPowerType()
    if not currentSpec then return nil end
    if not RA.SpecEnhancements then return nil end
    local enhData = RA.SpecEnhancements[currentSpec.specID]
    if enhData and enhData.resource and enhData.resource.type then
        return enhData.resource.type
    end
    return nil
end
