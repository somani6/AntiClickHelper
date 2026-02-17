local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)

-- Helper: Sucht rekursiv nach dem Dominos-Parent
function ACH:GetDominosOwner(button)
    local curr = button:GetParent()
    while curr do
        local name = curr:GetName()
        if name and name:match("^DominosFrame") then
            return tonumber(name:match("%d+$"))
        end
        -- Dominos speichert die ID oft in .id, aber wir prüfen sicherheitshalber auf den Frame-Namen oder Kontext
        if curr.id and type(curr.id) == "number" and (name and name:match("^Dominos")) then
             return curr.id
        end
        curr = curr:GetParent()
    end
    return nil
end

function ACH:GetDominosConfig(button)
    if not C_AddOns.IsAddOnLoaded("Dominos") then return nil end

    local dominosBarID = self:GetDominosOwner(button)
    
    if dominosBarID then
        local configKey = "DominosBar" .. dominosBarID
        return self.db.profile.enabledBars[configKey]
    end

    -- Fallback: Check by name if owner detection failed
    local name = button:GetName()
    if name and name:match("^DominosActionButton") then
        -- Fallback: Es ist ein Dominos Button, aber wir konnten die Leiste nicht ermitteln.
        -- Wir gehen davon aus, dass er überwacht werden soll.
        return true
    end

    return nil
end

-- Scannt und hookt Dominos Buttons
function ACH:ScanDominosButtons(callback)
    if not C_AddOns.IsAddOnLoaded("Dominos") then return end
    
    local count = 0
    for i = 1, 120 do
        local button = _G["DominosActionButton" .. i]
        if button and not button.ACH_Hooked then
            button:HookScript("OnMouseDown", callback)
            button.ACH_Hooked = true
            count = count + 1
        end
    end
end