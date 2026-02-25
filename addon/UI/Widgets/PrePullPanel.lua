------------------------------------------------------------------------
-- RotaAssist - PrePullPanel Widget
-- Out-of-combat checklist panel displaying consummable buffs.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.PrePullPanel = {}
local PrePullPanel = RA.UI.PrePullPanel
PrePullPanel.__index = PrePullPanel

---Create a new Pre-Pull Panel.
---@param parent table
---@return table widget
function PrePullPanel:Create(parent)
    local obj = setmetatable({}, self)
    
    obj.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    obj.frame:SetSize(150, 20) -- dynamic height later
    obj.frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    obj.frame:SetBackdropColor(0, 0, 0, 0.7)
    obj.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    
    -- Title
    obj.title = obj.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    obj.title:SetPoint("TOP", obj.frame, "TOP", 0, -5)
    
    -- Localized Title
    local titleStr = "Pre-Pull Checklist"
    if RA.L and RA.L["PREPULL_CHECKLIST"] then
        titleStr = RA.L["PREPULL_CHECKLIST"]
    end
    obj.title:SetText(titleStr)
    
    -- Rows storage
    obj.rows = {}
    
    -- Status text at bottom
    obj.statusText = obj.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    obj.statusText:SetPoint("BOTTOM", obj.frame, "BOTTOM", 0, 5)
    
    obj.frame:Hide()
    return obj
end

---Create a single row if it doesn't exist.
---@param index number
---@return table row
function PrePullPanel:GetOrCreateRow(index)
    if self.rows[index] then return self.rows[index] end
    
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetSize(130, 16)
    
    if index == 1 then
        row:SetPoint("TOP", self.title, "BOTTOM", 0, -5)
    else
        row:SetPoint("TOP", self.rows[index-1], "BOTTOM", 0, -2)
    end
    
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    
    row.symbol = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.symbol:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.symbol, "RIGHT", 4, 0)
    row.text:SetJustifyH("LEFT")
    
    self.rows[index] = row
    return row
end

---Update the checklist display.
---@param checkResults table[] From PrePullChecker:RunChecks()
function PrePullPanel:Update(checkResults)
    if not checkResults or #checkResults == 0 then
        self.frame:Hide()
        return
    end
    
    local allPassed = true
    local failCount = 0
    
    for i, res in ipairs(checkResults) do
        local row = self:GetOrCreateRow(i)
        
        -- Text and Icon
        row.icon:SetTexture(res.icon or 134400)
        row.text:SetText(res.name or "Unknown")
        
        -- Status
        if res.passed then
            row.symbol:SetText("✓")
            row.symbol:SetTextColor(0.2, 0.9, 0.2)
            row.text:SetTextColor(0.8, 0.8, 0.8)
            row.icon:SetDesaturated(false)
        else
            row.symbol:SetText("✕")
            row.symbol:SetTextColor(0.9, 0.2, 0.2)
            row.text:SetTextColor(1, 1, 1)
            row.icon:SetDesaturated(true)
            allPassed = false
            failCount = failCount + 1
        end
        
        row:Show()
    end
    
    -- Hide any extra rows
    for i = #checkResults + 1, #self.rows do
        self.rows[i]:Hide()
    end
    
    -- Update overall status
    if allPassed then
        self.statusText:SetText("✓ Ready!")
        self.statusText:SetTextColor(0.2, 0.9, 0.2)
    else
        if RA.L and RA.L["MISSING_ITEMS"] then
            self.statusText:SetText(string.format(RA.L["MISSING_ITEMS"], failCount))
        else
            self.statusText:SetText(string.format("Missing %d items", failCount))
        end
        self.statusText:SetTextColor(1, 0.8, 0.2)
    end
    
    -- Adjust frame height based on rows + padding
    local totalHeight = 15 + (#checkResults * 18) + 15
    self.frame:SetHeight(totalHeight)
end

function PrePullPanel:Show()
    self.frame:Show()
end

function PrePullPanel:Hide()
    self.frame:Hide()
end
