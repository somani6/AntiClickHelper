local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)

local actionBars = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
    "MultiBarBottomActionButton",
    "MultiBarBottomRightActionButton",
    "MultiBarBottomLeftActionButton",
    "MultiBarRightActionButton",
    "MultiBarLeftActionButton",
}

function ACH:GetBlizzardBindingInfo(button)
    local id = ACH:GetActionID(button)
    if not id then return nil, nil end

    if id >= 1 and id <= 12 then
        return "ACTIONBUTTON" .. id, "ActionButton"
    elseif id >= 13 and id <= 24 then
        -- Page 2 (usually no own bar, reached via paging)
        return "ACTIONBUTTON" .. (id - 12), "ActionButton" 
    elseif id >= 25 and id <= 36 then
        return "MULTIACTIONBAR3BUTTON" .. (id - 24), "MultiBarRightButton"
    elseif id >= 37 and id <= 48 then
        return "MULTIACTIONBAR4BUTTON" .. (id - 36), "MultiBarLeftButton"
    elseif id >= 49 and id <= 60 then
        return "MULTIACTIONBAR2BUTTON" .. (id - 48), "MultiBarBottomRightButton"
    elseif id >= 61 and id <= 72 then
        return "MULTIACTIONBAR1BUTTON" .. (id - 60), "MultiBarBottomLeftButton"
    elseif id >= 73 and id <= 84 then
        return "MULTIACTIONBAR5BUTTON" .. (id - 72), "MultiBar5Button"
    elseif id >= 85 and id <= 96 then
        return "MULTIACTIONBAR6BUTTON" .. (id - 84), "MultiBar6Button"
    end
    
    return nil, nil
end

function ACH:GetBlizzardConfig(button)
    local _, configKey = self:GetBlizzardBindingInfo(button)
    if not configKey then return nil end
    return self.db.profile.enabledBars[configKey]
end

function ACH:ScanBlizzardButtons(callback)
    for _, barName in ipairs(actionBars) do
        for i = 1, 12 do
            local buttonName = barName .. i
            local button = _G[buttonName]
            if button and not button.ACH_Hooked then
                button:HookScript("OnMouseDown", callback)
                button.ACH_Hooked = true
            end
        end
    end
end