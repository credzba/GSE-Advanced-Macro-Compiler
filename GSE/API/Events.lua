local GNOME, _ = ...

local GSE = GSE
local L = GSE.L
local Statics = GSE.Static

function GSE:UNIT_FACTION()
    if UnitIsPVP("player") then
        GSE.PVPFlag = true
    else
        GSE.PVPFlag = false
    end
    GSE.PrintDebugMessage("PVP Flag toggled to " .. tostring(GSE.PVPFlag), Statics.DebugModules["API"])
    GSE.ReloadSequences()
end

function GSE:ZONE_CHANGED_NEW_AREA()
    local _, type, difficulty, _, _, _, _, _, _ = GetInstanceInfo()
    if type == "pvp" then
        GSE.PVPFlag = true
    else
        GSE.PVPFlag = false
    end
    if difficulty == 2 then -- Heroic
        GSE.inHeroic = true
    else
        GSE.inHeroic = false
    end
    if difficulty == 1 then -- Normal
        GSE.inDungeon = true
    else
        GSE.inDungeon = false
    end
    if type == "raid" then
        GSE.inRaid = true
    else
        GSE.inRaid = false
    end
    if IsInGroup() then
        GSE.inParty = true
    else
        GSE.inParty = false
    end
    if type == "arena" then
        GSE.inArena = true
    else
        GSE.inArena = false
    end
    if type == "scenario" then
        GSE.inScenario = true
    else
        GSE.inScenario = false
    end

    GSE.PrintDebugMessage(
        table.concat(
            {
                "PVP: ",
                tostring(GSE.PVPFlag),
                " inRaid: ",
                tostring(GSE.inRaid),
                " inDungeon ",
                tostring(GSE.inDungeon),
                " inHeroic ",
                tostring(GSE.inHeroic),
                " inArena ",
                tostring(GSE.inArena),
                " inScenario ",
                tostring(GSE.inScenario)
            }
        ),
        Statics.DebugModules["API"]
    )
    -- Force Reload of all Sequences
    GSE.UnsavedOptions.ReloadQueued = nil
    GSE.ReloadSequences()
end

local function GetSpec()
    if GSE.GameMode < 7 then
        return "1"
    else
        return tostring(GetActiveTalentGroup())
    end
end

local function overrideActionButton(savedBind, force)
    if GSE.isEmpty(GSE.ButtonOverrides) then
        GSE.ButtonOverrides = {}
    end
    local Button = savedBind.Bind
    if not _G[Button] then
        return
    end
    local Sequence = savedBind.Sequence
    local state =
        savedBind.State and savedBind.State or string.sub(Button, 1, 3) == "BT4" and "0" or
        string.sub(Button, 1, 4) == "CPB_" and "" or
        "1"

    if (string.sub(Button, 1, 3) == "BT4") or string.sub(Button, 1, 5) == "ElvUI" or
            (string.sub(Button, 1, 3) == "BT4") or
            string.sub(Button, 1, 4) == "CPB_"
     then
        if _G[Button] and _G[Button].SetState then
            _G[Button]:SetAttribute("gse-button", Sequence)
            _G[Button]:SetState(
                state,
                "custom",
                {
                    func = function(self)
                        if not InCombatLockdown() then
                            self:SetAttribute("type", "click")
                            self:SetAttribute("clickbutton", _G[self:GetAttribute("gse-button")])
                        end
                    end,
                    tooltip = "GSE: " .. Sequence,
                    texture = "Interface\\Addons\\GSE_GUI\\Assets\\GSE_Logo_Dark_512.blp",
                    type = "click",
                    clickbutton = _G[Sequence]
                }
            )
            GSE.ButtonOverrides[Button] = Sequence
            _G[Button]:SetAttribute("type", "click")
            _G[Button]:SetAttribute("clickbutton", _G[Sequence])
        end
    else
        if not InCombatLockdown() then
            if (not GSE.ButtonOverrides[Button] or force) then
                _G[Button]:SetAttribute("type", "click")
                GSE.ButtonOverrides[Button] = Sequence
            end
            _G[Button]:SetAttribute("clickbutton", _G[Sequence])
        end
    end
end

local function LoadOverrides(force)
    if GSE.isEmpty(GSE.ButtonOverrides) then
        GSE.ButtonOverrides = {}
    end
    if GSE.isEmpty(GSE_C["ActionBarBinds"]) then
        GSE_C["ActionBarBinds"] = {}
    end
    if GSE.isEmpty(GSE_C["ActionBarBinds"]["Specialisations"]) then
        GSE_C["ActionBarBinds"]["Specialisations"] = {}
    end
    if GSE.isEmpty(GSE_C["ActionBarBinds"]["Specialisations"][GetSpec()]) then
        GSE_C["ActionBarBinds"]["Specialisations"][GetSpec()] = {}
    end

    if not InCombatLockdown() then
        for k, _ in pairs(GSE.ButtonOverrides) do
            -- revert all buttons
            if string.sub(k, 1, 5) == "ElvUI" or string.sub(k, 1, 4) == "CPB_" or string.sub(k, 1, 3) == "BT4" then
                local state = "1"
                if string.sub(k, 1, 3) == "BT4" then
                    state = "0"
                elseif string.sub(k, 1, 4) == "CPB_" then
                    state = ""
                end
                _G[k]:SetState(state, "action", tonumber(string.match(k, "%d+$")))
            else
                _G[k]:SetAttribute("type", "action")
            end
        end
        GSE.ButtonOverrides = {}

        for _, v in pairs(GSE_C["ActionBarBinds"]["Specialisations"][GetSpec()]) do
            overrideActionButton(v, force)
        end
    end
end

function GSE.ReloadOverrides(force)
    LoadOverrides(force)
end

function GSE:PLAYER_ENTERING_WORLD()
    GSE.PrintAvailable = true
    GSE.PerformPrint()
    GSE.currentZone = GetRealZoneText()
    GSE.PlayerEntered = true
    GSE.PerformReloadSequences(true)
    LoadOverrides()
    GSE:ZONE_CHANGED_NEW_AREA()
end

function GSE:ADDON_LOADED(event, addon)
    if addon == GNOME then
        local char = UnitFullName("player")
        local realm = GetRealmName()

        GSE.PerformOneOffEvents()
        if GSE_C and GSE_C["KeyBindings"] and GSE_C["KeyBindings"][char .. "-" .. realm] then
            GSE_C["KeyBindings"][char .. "-" .. realm] = nil
        end

        if GSE.isEmpty(GSESpellCache) then
            GSESpellCache = {
                ["enUS"] = {}
            }
        end

        if GSE.isEmpty(GSESpellCache[GetLocale()]) then
            GSESpellCache[GetLocale()] = {}
        end

        GSE.LoadStorage(GSE.Library)

        if GSE.isEmpty(GSESequences[GSE.GetCurrentClassID()]) then
            GSESequences[GSE.GetCurrentClassID()] = {}
        end
        if GSE.isEmpty(GSE.Library[GSE.GetCurrentClassID()]) then
            GSE.Library[GSE.GetCurrentClassID()] = {}
        end
        if GSE.isEmpty(GSE.Library[0]) then
            GSE.Library[0] = {}
        end
        if GSE.isEmpty(GSEVariables) then
            GSEVariables = {}
        end
        if GSE.isEmpty(GSEMacros) then
            GSEMacros = {}
        end
        if GSE.isEmpty(GSEMacros[char .. "-" .. realm]) then
            GSEMacros[char .. "-" .. realm] = {}
        end
        
        -- Register the Sample Macros
        if not GSEOptions.HideLoginMessage then
            GSE.Print(
                L["Advanced Macro Compiler loaded.|r  Type "] ..
                    GSEOptions.CommandColour .. L["/gse help|r to get started."],
                Statics.GSEString
            )
        end

        if GSE.isEmpty(GSEOptions) then
            GSE.SetDefaultOptions()
        end

        if GSEOptions.shownew then
            GSE:ShowUpdateNotes()
        end
        GSE:RegisterEvent("UPDATE_MACROS")
        GSE.PrintDebugMessage("I am loaded")
        GSE:SendMessage(Statics.CoreLoadedMessage)
    end
end

function GSE:PLAYER_REGEN_ENABLED(unit, event, addon)
    GSE:UnregisterEvent("PLAYER_REGEN_ENABLED")
    GSE.ResetButtons()
    GSE:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function GSE:PLAYER_LOGOUT()
    if not GSE.UnsavedOptions["GUI"] then
        if GSE["MenuFrame"] then
            if GSE.isEmpty(GSEOptions.frameLocations) then
                GSEOptions.frameLocations = {}
            end

            if GSE.isEmpty(GSEOptions.frameLocations.menu) then
                GSEOptions.frameLocations.menu = {}
            end
            GSEOptions.frameLocations.menu.top = GSE.MenuFrame.frame:GetTop()
            GSEOptions.frameLocations.menu.left = GSE.MenuFrame.frame:GetLeft()
        end
        if GSE["GUIEditFrame"] and GSE.GUIEditFrame.frame then
            if GSE.isEmpty(GSEOptions.frameLocations.sequenceeditor) then
                GSEOptions.frameLocations.sequenceeditor = {}
            end
            GSEOptions.frameLocations.sequenceeditor.top = GSE.GUIEditFrame.frame:GetTop()
            GSEOptions.frameLocations.sequenceeditor.left = GSE.GUIEditFrame.frame:GetLeft()
        end
        if GSE["GUIVariableFrame"] then
            if GSE.isEmpty(GSEOptions.frameLocations.variablesframe) then
                GSEOptions.frameLocations.variablesframe = {}
            end

            GSEOptions.frameLocations.variablesframe.top = GSE.GUIVariableFrame.frame:GetTop()
            GSEOptions.frameLocations.variablesframe.left = GSE.GUIVariableFrame.frame:GetLeft()
        end
        if GSE["GUIMacroFrame"] then
            if GSE.isEmpty(GSEOptions.frameLocations.macroframe) then
                GSEOptions.frameLocations.macroframe = {}
            end
            GSEOptions.frameLocations.macroframe.top = GSE.GUIMacroFrame.frame:GetTop()
            GSEOptions.frameLocations.macroframe.left = GSE.GUIMacroFrame.frame:GetLeft()
        end
        if GSE["GUIDebugFrame"] then
            if GSE.isEmpty(GSEOptions.frameLocations.debug) then
                GSEOptions.frameLocations.debug = {}
            end
            GSEOptions.frameLocations.debug.top = GSE.GUIDebugFrame.frame:GetTop()
            GSEOptions.frameLocations.debug.left = GSE.GUIDebugFrame.frame:GetLeft()
        end
        if GSE["GUIkeybindingframe"] then
            if GSE.isEmpty(GSEOptions.frameLocations.keybindingframe) then
                GSEOptions.frameLocations.keybindingframe = {}
            end
            GSEOptions.frameLocations.keybindingframe.top = GSE.GUIkeybindingframe.frame:GetTop()
            GSEOptions.frameLocations.keybindingframe.left = GSE.GUIkeybindingframe.frame:GetLeft()
        end
    end
end

-- MoP Specific events for talent changes
function GSE:ACTIVE_TALENT_GROUP_CHANGED()
    LoadOverrides()
    GSE.ReloadSequences()
end

function GSE:PLAYER_TALENT_UPDATE()
    LoadOverrides()
    GSE.ReloadSequences()
end

function GSE:PLAYER_LEVEL_UP()
    GSE.ReloadSequences()
end

function GSE:CHARACTER_POINTS_CHANGED()
    GSE.ReloadSequences()
end

function GSE:GROUP_ROSTER_UPDATE(...)
    -- Serialisation stuff
    GSE.sendVersionCheck()
    for k, _ in pairs(GSE.UnsavedOptions["PartyUsers"]) do
        if not (UnitInParty(k) or UnitInRaid(k)) then
            -- Take them out of the list
            GSE.UnsavedOptions["PartyUsers"][k] = nil
        end
    end
    local channel
    if IsInRaid() then
        channel = "RAID"
    else
        channel = "PARTY"
    end
    if #GSE.UnsavedOptions["PartyUsers"] > 1 then
        GSE.SendSpellCache(channel)
    end
    -- Group Team stuff
    GSE:ZONE_CHANGED_NEW_AREA()
end

function GSE:GUILD_ROSTER_UPDATE(...)
    -- Serialisation stuff
    GSE.sendVersionCheck("GUILD")
end

function GSE:UPDATE_MACROS()
    GSE.ManageMacros()
end

GSE:RegisterEvent("GROUP_ROSTER_UPDATE")
GSE:RegisterEvent("PLAYER_LOGOUT")
GSE:RegisterEvent("PLAYER_ENTERING_WORLD")
GSE:RegisterEvent("PLAYER_REGEN_ENABLED")
GSE:RegisterEvent("ADDON_LOADED")
GSE:RegisterEvent("ZONE_CHANGED_NEW_AREA")
GSE:RegisterEvent("UNIT_FACTION")
GSE:RegisterEvent("PLAYER_LEVEL_UP")
GSE:RegisterEvent("GUILD_ROSTER_UPDATE")
GSE:RegisterEvent("CHARACTER_POINTS_CHANGED")
GSE:RegisterEvent("PLAYER_TALENT_UPDATE")
GSE:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
GSE:RegisterEvent("UPDATE_MACROS")

function GSE:OnEnable()
    GSE.StartOOCTimer()
end

--- Start the OOC Queue Timer
function GSE.StartOOCTimer()
    GSE.OOCTimer =