local addonName, addon = ...
local ACH = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceConsole-3.0", "AceEvent-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)

local defaults = {
    profile = {
        active = true,
        hardmode = true,
        punishUnbound = false,
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
            ["DominosBar1"] = true,
            ["DominosBar2"] = true,
            ["DominosBar3"] = true,
            ["DominosBar4"] = true,
            ["DominosBar5"] = true,
            ["DominosBar6"] = true,
            ["DominosBar7"] = true,
            ["DominosBar8"] = true,
            ["DominosBar9"] = true,
            ["DominosBar10"] = true,
            ["DominosBar11"] = true,
            ["DominosBar12"] = true,
            ["DominosBar13"] = true,
            ["DominosBar14"] = true,
            ["BartenderBar1"] = true,
            ["BartenderBar2"] = true,
            ["BartenderBar3"] = true,
            ["BartenderBar4"] = true,
            ["BartenderBar5"] = true,
            ["BartenderBar6"] = true,
            ["BartenderBar7"] = true,
            ["BartenderBar8"] = true,
            ["BartenderBar9"] = true,
            ["BartenderBar10"] = true,
            ["ElvUIBar1"] = true,
            ["ElvUIBar2"] = true,
            ["ElvUIBar3"] = true,
            ["ElvUIBar4"] = true,
            ["ElvUIBar5"] = true,
            ["ElvUIBar6"] = true,
            ["ElvUIBar7"] = true,
            ["ElvUIBar8"] = true,
            ["ElvUIBar9"] = true,
            ["ElvUIBar10"] = true,
            ["ElvUIBar11"] = true,
            ["ElvUIBar12"] = true,
            ["ElvUIBar13"] = true,
            ["ElvUIBar14"] = true,
            ["ElvUIBar15"] = true,
        },
    },
}

local lastClickTime = 0
local CLICK_THRESHOLD = 0.5
local INITIAL_RADIUS = 50
local RADIUS_STEP = 30

function ACH:OnInitialize()
    if LSM and not C_AddOns.IsAddOnLoaded("WeakAuras_SharedMedia") then
        LSM:Register("sound", "Goat Bleeting", "Interface\\AddOns\\AntiClickHelper\\Sounds\\GoatBleating.ogg")
    end

    self.db = LibStub("AceDB-3.0"):New("AntiClickHelperDB", defaults, true)
    self.db.profile.radius = 0
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AntiClickHelper", self:GetOptions())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AntiClickHelper", "AntiClickHelper")

    self:RegisterChatCommand("ach", "OpenConfig")
    
    self:CreateHardmodeFrame()
    self:ScanActionBars()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function ACH:GetActionID(button)
    if type(button.action) == "number" then return button.action end
    if button.GetAttribute then
        local action = button:GetAttribute("action")
        if type(action) == "number" then return action end
    end
    -- Dominos Fallback
    local name = button:GetName()
    if name and name:match("^DominosActionButton") then
        local id = tonumber(name:match("%d+$"))
        if id then return id end
    end
    return nil
end

function ACH:IsButtonMonitored(button)
    local isEnabled = nil
    local command = nil

    -- Check Addons (Priority: Dominos > Bartender > Blizzard)
    if C_AddOns.IsAddOnLoaded("Dominos") and self.GetDominosConfig then
        isEnabled = self:GetDominosConfig(button)
    elseif C_AddOns.IsAddOnLoaded("Bartender4") and self.GetBartenderConfig then
        isEnabled = self:GetBartenderConfig(button)
    elseif C_AddOns.IsAddOnLoaded("ElvUI") and self.GetElvUIConfig then
        isEnabled = self:GetElvUIConfig(button)
    elseif self.GetBlizzardConfig then
        isEnabled, command = self:GetBlizzardConfig(button)
    end

    if isEnabled ~= true then return false, nil end

    if not command and self.GetBlizzardBindingInfo then
        command = self:GetBlizzardBindingInfo(button)
    end

    return true, command
end

function ACH:ButtonHasBind(button, command)
    if button.GetBindingAction then
        local bindingAction = button:GetBindingAction()
        if bindingAction and GetBindingKey(bindingAction) then return true end
    end

    if command and GetBindingKey(command) then return true end
    
    local name = button:GetName()
    if name then
        if GetBindingKey("CLICK "..name..":LeftButton") then return true end
        if GetBindingKey("CLICK "..name) then return true end
    end

    if button.HotKey and button.HotKey.GetText then
        local text = button.HotKey:GetText()
        if text and text ~= "" and text ~= RANGE_INDICATOR then return true end
    end

    if self.db.profile.punishUnbound then return true end

    return false
end

function ACH:Punish()
    local sound = LSM and LSM:Fetch("sound", ACH.db.profile.soundFile)
    if sound then
        PlaySoundFile(sound, "Master")
    end
    
    if self.db.profile.hardmode then
        if self.db.profile.radius == 0 then
            self.db.profile.radius = INITIAL_RADIUS
        else
            self.db.profile.radius = self.db.profile.radius + RADIUS_STEP
        end
        self:UpdateCursorFrame()
    end
end

local function OnButtonMouseDown(self, button)
    if not IsMouseButtonDown(button) then return end
    if not ACH.db.profile.active or not UnitAffectingCombat("player") then return end
    
    lastClickTime = GetTime()

    local slot = ACH:GetActionID(self)
    local isDominos = self:GetName() and self:GetName():match("^DominosActionButton")
    local isElvUI = self:GetName() and self:GetName():match("^ElvUI_Bar")
    
    if not slot and not isDominos and not isElvUI then return end
    if not isDominos and not isElvUI and not HasAction(slot) then return end

    local monitored, command = ACH:IsButtonMonitored(self)
    if not monitored then return end

    if not ACH:ButtonHasBind(self, command) then return end

    ACH:Punish()
end

function ACH:ScanActionBars()
    if C_AddOns.IsAddOnLoaded("Dominos") and self.ScanDominosButtons then
        self:ScanDominosButtons(OnButtonMouseDown)
    elseif C_AddOns.IsAddOnLoaded("Bartender4") and self.ScanBartenderButtons then
        self:ScanBartenderButtons(OnButtonMouseDown)
    elseif C_AddOns.IsAddOnLoaded("ElvUI") and self.ScanElvUIButtons then
        self:ScanElvUIButtons(OnButtonMouseDown)
    elseif self.ScanBlizzardButtons then
        self:ScanBlizzardButtons(OnButtonMouseDown)
    end
end

function ACH:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not self.db.profile.active then return end
    if not UnitAffectingCombat("player") then return end

    local now = GetTime()
    local timeDiff = now - lastClickTime

    -- If last click was long ago, it was a keybind
    if timeDiff >= CLICK_THRESHOLD and self.db.profile.hardmode and self.db.profile.radius > 0 then
        self.db.profile.radius = self.db.profile.radius - RADIUS_STEP
        if self.db.profile.radius < INITIAL_RADIUS then
            self.db.profile.radius = 0
        end
        self:UpdateCursorFrame()
    end
end

function ACH:PLAYER_REGEN_DISABLED()
end

function ACH:PLAYER_REGEN_ENABLED()
    self.db.profile.radius = 0
    self:UpdateCursorFrame()
end

function ACH:PLAYER_ENTERING_WORLD()
    self:ScanActionBars()
    C_Timer.After(2, function() self:ScanActionBars() end)
end
