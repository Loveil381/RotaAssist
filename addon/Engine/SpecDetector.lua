------------------------------------------------------------------------
-- RotaAssist - Spec Detector
-- Detects the current player specialization and reloads APL data when
-- spec or talents change.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local SpecDetector = {}
RA:RegisterModule("SpecDetector", SpecDetector)

---@class SpecInfo
---@field classID number
---@field specID number
---@field className string
---@field specName string
---@field role string
---@field classFile string
---@field icon number

---@type SpecInfo|nil
local currentSpec = nil

---@return SpecInfo|nil
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
    return {
        classID = classID,
        specID = specID,
        className = className,
        specName = specName,
        role = role,
        classFile = className,
        icon = specIcon,
    }
end

---@param specInfo SpecInfo
local function loadAPLForSpec(specInfo)
    if not RA.APLData then
        RA:PrintDebug("SpecDetector: No APL data table found")
        return
    end

    local aplData = RA.APLData[specInfo.specID]
    if not aplData then
        RA:PrintDebug(string.format("SpecDetector: No APL found for specID %d", specInfo.specID))
        return
    end

    local validClass = aplData.class
    if validClass and validClass ~= specInfo.classFile then
        RA:PrintDebug(string.format(
            "SpecDetector: APL class mismatch for specID %d (APL=%s, player=%s) - skipping",
            specInfo.specID, validClass, specInfo.classFile))
        return
    end

    RA:PrintDebug(string.format("SpecDetector: Loaded APL for %s %s (specID %d)",
        specInfo.className, specInfo.specName, specInfo.specID))

    local aplEngine = RA:GetModule("APLEngine")
    if aplEngine and aplEngine.SetAPL then
        aplEngine:SetAPL(specInfo.specID, aplData, specInfo.classID)
        if aplEngine.RefreshProfileFromTalents then
            local profileName = aplEngine:RefreshProfileFromTalents()
            RA:PrintDebug("SpecDetector: Active APL profile = " .. tostring(profileName))
        end
    end
end

---@param forceReload boolean|nil
local function refreshSpec(forceReload)
    local newSpec = detectSpec()
    if not newSpec then
        return
    end

    local changed = (not currentSpec) or (currentSpec.specID ~= newSpec.specID)
    currentSpec = newSpec

    if changed or forceReload then
        RA:PrintDebug(string.format("SpecDetector: Detected %s %s (%s)",
            currentSpec.className, currentSpec.specName, currentSpec.role))

        loadAPLForSpec(currentSpec)

        local eh = RA:GetModule("EventHandler")
        if eh and eh.Fire then
            eh:Fire("ROTAASSIST_SPEC_CHANGED", currentSpec)
        end
    end
end

function SpecDetector:OnInitialize()
end

function SpecDetector:OnEnable()
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_SPECIALIZATION_CHANGED", "SpecDetector", function()
            RA:PrintDebug("SpecDetector: Specialization changed event")
            refreshSpec()
        end)

        eh:Subscribe("TRAIT_CONFIG_UPDATED", "SpecDetector", function()
            RA:PrintDebug("SpecDetector: Talent configuration changed")
            refreshSpec(true)
        end)

        eh:Subscribe("PLAYER_ENTERING_WORLD", "SpecDetector", function()
            RA:PrintDebug("SpecDetector: PLAYER_ENTERING_WORLD - scheduling delayed refresh")
            C_Timer.After(0.5, function()
                refreshSpec()
            end)
        end)
    end

    refreshSpec()
end

function SpecDetector:OnPlayerEnteringWorld()
    refreshSpec()
end

---@return SpecInfo|nil
function SpecDetector:GetCurrentSpec()
    if not currentSpec then
        refreshSpec()
    end
    return currentSpec
end

---@param role string
---@return boolean
function SpecDetector:IsRole(role)
    return currentSpec and currentSpec.role == role
end

---@return number|nil
function SpecDetector:GetSpecID()
    return currentSpec and currentSpec.specID
end

---@return number|nil
function SpecDetector:GetPrimaryPowerType()
    if not currentSpec or not RA.SpecEnhancements then
        return nil
    end
    local enhData = RA.SpecEnhancements[currentSpec.specID]
    if enhData and enhData.resource then
        return enhData.resource.type or enhData.resource.powerType
    end
    return nil
end
