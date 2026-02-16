local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)

-- Creates the black circle around the mouse cursor
function ACH:CreateHardmodeFrame()
    local f = CreateFrame("Frame", "ACH_HardmodeFrame", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetSize(10, 10)
    
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(0, 0, 0, 1)
    t:SetAllPoints(f)
    
    -- Mask for circle shape
    local mask = f:CreateMaskTexture()
    mask:SetTexture("Interface\\Masks\\CircleMaskScalable")
    mask:SetAllPoints(t)
    t:AddMaskTexture(mask)
    
    f.texture = t
    f:Hide()

    f:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end)

    self.cursorFrame = f
end

function ACH:UpdateCursorFrame()
    if not self.cursorFrame then return end

    local profile = self.db.profile
    if not profile.active or not profile.hardmode or profile.radius <= 0 then 
        self.cursorFrame:Hide()
        return 
    end

    self.cursorFrame:Show()
    self.cursorFrame:SetSize(profile.radius, profile.radius)
end