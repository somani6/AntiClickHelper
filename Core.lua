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
        },
    },
}

local lastClickTime = 0
local CLICK_THRESHOLD = 0.5 -- Time window in seconds to attribute a click
local INITIAL_RADIUS = 50
local RADIUS_STEP = 30

function ACH:OnInitialize()
    if LSM and not C_AddOns.IsAddOnLoaded("WeakAuras_SharedMedia") then
        LSM:Register("sound", "Goat Bleeting", "Interface\\AddOns\\AntiClickHelper\\Sounds\\GoatBleating.ogg")
    end

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
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- Helper: Ermittelt die Action ID eines Buttons sicher
function ACH:GetActionID(button)
    if type(button.action) == "number" then return button.action end
    if button.GetAttribute then
        local action = button:GetAttribute("action")
        if type(action) == "number" then return action end
    end
    -- Fallback: Dominos Buttons haben die ID oft im Namen, falls das Attribut nicht direkt lesbar ist
    local name = button:GetName()
    if name and name:match("^DominosActionButton") then
        local id = tonumber(name:match("%d+$"))
        if id then return id end
    end
    return nil
end

local function OnButtonMouseDown(self, button)

    if not ACH.db.profile.active or not UnitAffectingCombat("player") then 
        return 
    end
    
    lastClickTime = GetTime()

    -- Check if there is an action on the button (prevents spam on empty slots)
    local slot = ACH:GetActionID(self)
    -- Relax HasAction check for Dominos buttons as they might use paging/states that HasAction(staticID) doesn't reflect
    local isDominos = self:GetName() and self:GetName():match("^DominosActionButton")
    if not slot then return end
    
    if not isDominos and not HasAction(slot) then 
        return 
    end

    local isEnabled = nil
    local command = nil

    -- 1. Check Dominos
    if ACH.GetDominosConfig then
        isEnabled = ACH:GetDominosConfig(self)
    end

    -- 2. Check Blizzard (if not handled by Dominos)
    if isEnabled == nil and ACH.GetBlizzardConfig then
        isEnabled, command = ACH:GetBlizzardConfig(self)
    end

    if isEnabled == false then return end -- Explicitly disabled
    if isEnabled == nil then return end -- Not monitored

    -- If we have no command yet (e.g. Dominos button), try to get standard command from slot
    if not command and ACH.GetBlizzardBindingInfo then
        command = ACH:GetBlizzardBindingInfo(self)
    end

    if not isEnabled then 
        return 
    end

    local hasBind = false
    
    -- 1. Check Standard WoW Binding
    if command and GetBindingKey(command) then 
        hasBind = true 
    end
    
    -- 2. Check Addon-specific "Click" Binding (e.g. Dominos Hover-Bind)
    if not hasBind and self:GetName() then
        local clickBind = "CLICK "..self:GetName()..":LeftButton"
        if GetBindingKey(clickBind) then hasBind = true end
        
        -- Check alternative binding format (without :LeftButton)
        if not hasBind and GetBindingKey("CLICK "..self:GetName()) then hasBind = true end
    end

    -- 3. Visual Check: Does the button show a HotKey text?
    -- This is a robust fallback for addons like Dominos that might handle bindings internally.
    if not hasBind and self.HotKey and self.HotKey.GetText then
        local text = self.HotKey:GetText()
        if text and text ~= "" and text ~= RANGE_INDICATOR then hasBind = true end
    end

    -- 4. Check Punish Unbound option
    if not hasBind and ACH.db.profile.punishUnbound then
        hasBind = true
    end

    if not hasBind then 
        return 
    end

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

function ACH:ScanActionBars()
    -- Blizzard
    if self.ScanBlizzardButtons then
        self:ScanBlizzardButtons(OnButtonMouseDown)
    end

    -- Dominos
    if self.ScanDominosButtons then
        self:ScanDominosButtons(OnButtonMouseDown)
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
    if timeDiff >= CLICK_THRESHOLD and self.db.profile.hardmode and self.db.profile.radius > 0 then
        -- IT WAS A KEYBIND (or a macro/hardware event)
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
