local addonName = ...
local ACH = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LSM = LibStub("LibSharedMedia-3.0", true)

function ACH:GetOptions()
    local options = {
        name = "AntiClickHelper",
        handler = ACH,
        type = 'group',
        args = {
            general = {
                type = 'group',
                name = L["General"],
                inline = true,
                order = 1,
                args = {
                    active = {
                        type = 'toggle',
                        name = L["Enable Addon"],
                        desc = L["Toggles the functionality of the addon."],
                        get = function(info) return ACH.db.profile.active end,
                        set = function(info, val) ACH.db.profile.active = val end,
                        order = 1,
                    },
                    punishUnbound = {
                        type = 'toggle',
                        name = L["Punish Unbound"],
                        desc = L["Punish clicks even if the button has no keybind."],
                        get = function(info) return ACH.db.profile.punishUnbound end,
                        set = function(info, val) ACH.db.profile.punishUnbound = val end,
                        order = 2,
                    },
                },
            },
            hardmodeSettings = {
                type = 'group',
                name = L["Hardmode"],
                inline = true,
                order = 2,
                args = {
                    hardmode = {
                        type = 'toggle',
                        name = L["Enable Hardmode"],
                        desc = L["Shows a black circle around the mouse that grows on clicks."],
                        get = function(info) return ACH.db.profile.hardmode end,
                        set = function(info, val) ACH.db.profile.hardmode = val; ACH:UpdateCursorFrame() end,
                        order = 1,
                    },
                },
            },
            soundSettings = {
                type = 'group',
                name = L["Sound Settings"],
                inline = true,
                order = 3,
                args = {
                    soundFile = {
                        type = 'select',
                        dialogControl = LibStub("AceGUI-3.0"):GetWidgetVersion("LSM30_Sound") and "LSM30_Sound" or nil,
                        name = L["Sound Selection"],
                        desc = L["Select the sound to play."],
                        values = function()
                            if LSM then
                                local list = {}
                                for name, _ in pairs(LSM:HashTable("sound")) do
                                    list[name] = name
                                end
                                return list
                            else
                                return { ["None"] = L["LibSharedMedia missing"] }
                            end
                        end,
                        get = function(info) return ACH.db.profile.soundFile end,
                        set = function(info, val) 
                            ACH.db.profile.soundFile = val
                            local sound = LSM and LSM:Fetch("sound", val)
                            if sound then
                                PlaySoundFile(sound, "Master") 
                            end
                        end, -- Play preview
                        order = 1,
                    },
                },
            },
            barSettings = {
                type = 'group',
                name = L["Blizzard Action Bars"],
                order = 4,
                args = {
                    desc = {
                        type = 'description',
                        name = L["Select which action bars to monitor."],
                        order = 0,
                    },
                    bar1 = {
                        type = 'toggle',
                        name = L["Action Bar 1"],
                        get = function(info) return ACH.db.profile.enabledBars["ActionButton"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["ActionButton"] = val end,
                        order = 1,
                    },
                    barBL = {
                        type = 'toggle',
                        name = L["Action Bar 2"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBarBottomLeftButton"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBarBottomLeftButton"] = val end,
                        order = 2,
                    },
                    barBR = {
                        type = 'toggle',
                        name = L["Action Bar 3"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBarBottomRightButton"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBarBottomRightButton"] = val end,
                        order = 3,
                    },
                    barR1 = {
                        type = 'toggle',
                        name = L["Action Bar 4"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBarRightButton"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBarRightButton"] = val end,
                        order = 4,
                    },
                    barR2 = {
                        type = 'toggle',
                        name = L["Action Bar 5"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBarLeftButton"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBarLeftButton"] = val end,
                        order = 5,
                    },
                    bar5 = {
                        type = 'toggle',
                        name = L["Action Bar 6"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBar5Button"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBar5Button"] = val end,
                        order = 6,
                    },
                    bar6 = {
                        type = 'toggle',
                        name = L["Action Bar 7"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBar6Button"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBar6Button"] = val end,
                        order = 7,
                    },
                    bar7 = {
                        type = 'toggle',
                        name = L["Action Bar 8"],
                        get = function(info) return ACH.db.profile.enabledBars["MultiBar7Button"] end,
                        set = function(info, val) ACH.db.profile.enabledBars["MultiBar7Button"] = val end,
                        order = 8,
                    },
                },
            },
            dominosSettings = {
                type = 'group',
                name = L["Dominos"],
                order = 5,
                hidden = function() return not C_AddOns.IsAddOnLoaded("Dominos") end,
                args = {
                    desc = {
                        type = 'description',
                        name = L["Select which action bars to monitor."],
                        order = 0,
                    },
                },
            },
        },
    }

    -- Generiere Optionen für Dominos Leisten 1-14
    for i = 1, 14 do
        options.args.dominosSettings.args["bar" .. i] = {
            type = 'toggle',
            name = L["Action Bar " .. i],
            get = function(info) return ACH.db.profile.enabledBars["DominosBar" .. i] end,
            set = function(info, val) ACH.db.profile.enabledBars["DominosBar" .. i] = val end,
            order = i,
        }
    end

    return options
end

function ACH:OpenConfig()
    -- Opens the Blizzard options menu directly in the addon's category
    if Settings and Settings.OpenToCategory then
        -- Try to open the category (works in 10.0+)
        if self.optionsFrame.category then
             Settings.OpenToCategory(self.optionsFrame.category:GetID())
        else
             -- Fallback
             Settings.OpenToCategory(self.optionsFrame.name)
        end
    else
        -- Fallback for older versions
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end
