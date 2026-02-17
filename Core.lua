local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceConsole-3.0", "AceEvent-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)

local defaults = {
    profile = {
        active = true,
        hardmode = true,
        soundFile = "Goat Bleeting",
        radius = 0,
        enabledBars = {
            ["ActionButton"] = true,
            ["MultiBarBottomLeftButton"] = true,
            ["MultiBarBottomRightButton"] = true,
            ["MultiBarRightButton"] = true,
            ["MultiBarLeftButton"] = true,
            ["MultiBar5Button"] = true,
            ["MultiBar6Button"] = true,
            ["MultiBar7Button"] = true,
        },
    },
}

local lastClickTime = 0
local CLICK_THRESHOLD = 0.5 -- Time window in seconds to attribute a click
local INITIAL_RADIUS = 50
local RADIUS_STEP = 30

-- List of Action Bar names (Modern WoW Standard)
local actionBars = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local bindingMap = {
    ["ActionButton"] = "ACTIONBUTTON",
    ["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
    ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
    ["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
    ["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
    ["MultiBar5Button"] = "MULTIACTIONBAR5BUTTON",
    ["MultiBar6Button"] = "MULTIACTIONBAR6BUTTON",
    ["MultiBar7Button"] = "MULTIACTIONBAR7BUTTON",
}

function ACH:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AntiClickHelperDB", defaults, true)
    self.db.profile.radius = 0 -- Reset radius on load
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AntiClickHelper", self:GetOptions())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AntiClickHelper", "AntiClickHelper")

    self:RegisterChatCommand("ach", "OpenConfig")
    
    self:CreateHardmodeFrame()
    self:ScanActionBars()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function OnButtonMouseDown(self, button)
    if not ACH.db.profile.active then return end
    if not UnitAffectingCombat("player") then return end
    
    -- Check if there is an action on the button (prevents spam on empty slots)
    local slot = self.action
    if slot and HasAction(slot) then
        local name = self:GetName()
        local id = self:GetID()
        local hasBind = false

        if name and id and id > 0 then
            for framePrefix, bindPrefix in pairs(bindingMap) do
                if name == (framePrefix .. id) then
                    if not ACH.db.profile.enabledBars[framePrefix] then return end
                    
                    if GetBindingKey(bindPrefix .. id) then hasBind = true end
                    break
                end
            end
        end

        if not hasBind then return end

        local sound = LSM and LSM:Fetch("sound", ACH.db.profile.soundFile)
        if sound then
            PlaySoundFile(sound, "Master")
        end
        
        if ACH.db.profile.hardmode then
            if ACH.db.profile.radius == 0 then
                ACH.db.profile.radius = INITIAL_RADIUS
            else
                ACH.db.profile.radius = ACH.db.profile.radius + RADIUS_STEP
            end
            ACH:UpdateCursorFrame()
        end
    end

    lastClickTime = GetTime()
end

function ACH:ScanActionBars()
    for _, barName in ipairs(actionBars) do
        for i = 1, 12 do
            local buttonName = barName .. i
            local button = _G[buttonName]
            
            if button and not button.ACH_Hooked then
                -- HookScript is safer than SetScript as it doesn't overwrite the original function (avoids taint)
                button:HookScript("OnMouseDown", OnButtonMouseDown)
                button.ACH_Hooked = true
            end
        end
    end
end

function ACH:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not self.db.profile.active then return end
    if not UnitAffectingCombat("player") then return end

    local now = GetTime()
    local timeDiff = now - lastClickTime

    -- Logic: If the last mouse click was a long time ago (> Threshold), it was a keybind.
    -- If it was recent (< Threshold), we already warned in OnMouseDown.
    if timeDiff >= CLICK_THRESHOLD then
        -- IT WAS A KEYBIND (or a macro/hardware event)
        
        if self.db.profile.hardmode and self.db.profile.radius > 0 then
            self.db.profile.radius = self.db.profile.radius - RADIUS_STEP
            if self.db.profile.radius < INITIAL_RADIUS then
                self.db.profile.radius = 0
            end
            self:UpdateCursorFrame()
        end
    end
end

function ACH:PLAYER_REGEN_DISABLED()
end

function ACH:PLAYER_REGEN_ENABLED()
    self.db.profile.radius = 0
    self:UpdateCursorFrame()
end
