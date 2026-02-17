local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)

function ACH:GetBartenderOwner(button)
    local name = button:GetName()
    if name then
        local id = tonumber(name:match("^BT4Button(%d+)$"))
        if id then
            if id >= 1 and id <= 12 then return 1
            elseif id >= 61 and id <= 72 then return 2
            elseif id >= 49 and id <= 60 then return 3
            elseif id >= 25 and id <= 36 then return 4
            elseif id >= 37 and id <= 48 then return 5
            elseif id >= 145 and id <= 156 then return 6
            elseif id >= 157 and id <= 168 then return 7
            elseif id >= 169 and id <= 180 then return 8
            end
        end
    end

    local curr = button:GetParent()
    while curr do
        local currName = curr:GetName()
        if curr.id and tonumber(curr.id) then
             return tonumber(curr.id)
        end
        if currName and currName:match("^Bartender4Bar") then
            return tonumber(currName:match("%d+$"))
        end
        curr = curr:GetParent()
    end
    return nil
end

function ACH:GetBartenderConfig(button)
    if not C_AddOns.IsAddOnLoaded("Bartender4") then return nil end

    local barID = self:GetBartenderOwner(button)
    
    if barID then
        local configKey = "BartenderBar" .. barID
        return self.db.profile.enabledBars[configKey]
    end

    local name = button:GetName()
    if name and name:match("^BT4Button") then
        -- Fallback: It is a Bartender button, but we could not determine the bar.
        return false
    end

    return nil
end

function ACH:ScanBartenderButtons(callback)
    if not C_AddOns.IsAddOnLoaded("Bartender4") then return end
    
    -- Scan range increased to cover higher IDs (user reported IDs up to 168+)
    for i = 1, 200 do
        local button = _G["BT4Button" .. i]
        if button and not button.ACH_Hooked then
            button:HookScript("OnMouseDown", callback)
            button.ACH_Hooked = true
        end
    end
end