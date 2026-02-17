local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)

function ACH:GetElvUIConfig(button)
    if not C_AddOns.IsAddOnLoaded("ElvUI") then return nil end

    local name = button:GetName()
    if not name then return nil end

    -- ElvUI naming convention: ElvUI_Bar1Button1
    local barID = name:match("^ElvUI_Bar(%d+)Button")
    
    if barID then
        local configKey = "ElvUIBar" .. barID
        return self.db.profile.enabledBars[configKey]
    end

    return nil
end

function ACH:ScanElvUIButtons(callback)
    if not C_AddOns.IsAddOnLoaded("ElvUI") then return end
    
    for i = 1, 15 do
        for j = 1, 12 do
            local button = _G["ElvUI_Bar" .. i .. "Button" .. j]
            if button and not button.ACH_Hooked then
                button:HookScript("OnMouseDown", callback)
                button.ACH_Hooked = true
            end
        end
    end
end