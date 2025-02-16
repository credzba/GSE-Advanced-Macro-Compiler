local GSE = GSE
local Statics = GSE.Static

local L = GSE.L

local GNOME = "Storage"

--- Delete a sequence from the library
function GSE.DeleteSequence(classid, sequenceName)
    GSE.Library[tonumber(classid)][sequenceName] = nil
    GSESequences[tonumber(classid)][sequenceName] = nil
end

local missingVariables = {}
local function manageMissingVariable(varname)
    if not missingVariables[varname] then
        GSE.Print(L["Missing Variable "] .. varname, "GSE " .. Statics.DebugModules["API"])
        missingVariables[varname] = 0
    end
    missingVariables[varname] = missingVariables[varname] + 1
    if missingVariables[varname] > 100 then
        GSE.Print(L["Missing Variable "] .. varname, "GSE " .. Statics.DebugModules["API"])
        missingVariables[varname] = 0
    end
end

function GSE.CloneSequence(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[GSE.CloneSequence(orig_key)] = GSE.CloneSequence(orig_value)
        end
        setmetatable(copy, GSE.CloneSequence(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- Add a sequence to the library
function GSE.AddSequenceToCollection(sequenceName, sequence, classid)
    local vals = {}
    vals.action = "Save"
    vals.sequencename = sequenceName
    vals.sequence = sequence
    vals.classid = classid
    table.insert(GSE.OOCQueue, vals)
end

function GSE.PerformMergeAction(action, classid, sequenceName, newSequence)
    local vals = {}
    vals.action = "MergeSequence"
    vals.sequencename = sequenceName
    vals.newSequence = newSequence
    vals.classid = classid
    vals.mergeaction = action
    table.insert(GSE.OOCQueue, vals)
end

--- Replace a current version of a Macro
function GSE.ReplaceSequence(classid, sequenceName, sequence)
    GSESequences[classid][sequenceName] = GSE.EncodeMessage({sequenceName, sequence})
    GSE.Library[classid][sequenceName] = sequence
    if GSE.GUI and GSE.GUIEditFrame then
        if GSE.GUIEditFrame:IsVisible() then
            GSE.GUIEditFrame:SetStatusText(sequenceName .. " " .. L["Saved"])
            C_Timer.After(
                5,
                function()
                    GSE.GUIEditFrame:SetStatusText("")
                end
            )
            GSE.ShowSequences()
        end
    end
end

--- Load the GSEStorage into a new table.
function GSE.LoadStorage(destination)
    GSE.LoadVariables()
    if GSE.isEmpty(destination) then
        destination = {}
    end
    if GSE.isEmpty(GSESequences) then
        GSESequences = {}
        for iind = 0, 11 do -- MoP only has 11 classes
            GSESequences[iind] = {}
        end
    end
    for k = 0, 11 do -- MoP only has 11 classes
        if GSE.isEmpty(destination[k]) then
            destination[k] = {}
        end
        local v = GSESequences[k]
        for i, j in pairs(v) do
            local status, err =
                pcall(
                function()
                    local localsuccess, uncompressedVersion = GSE.DecodeMessage(j)
                    destination[k][i] = uncompressedVersion[2]
                end
            )
            if err then
                GSE.Print(
                    "There was an error processing " ..
                        i .. ", You will need to reimport this macro from another source.",
                    err
                )
            end
        end
    end
end

--- Return the Active Sequence Version for a Sequence.
function GSE.GetActiveSequenceVersion(sequenceName)
    local classid = GSE.GetCurrentClassID()
    if GSE.isEmpty(GSE.Library[GSE.GetCurrentClassID()][sequenceName]) then
        classid = 0
    end
    -- Set to default or 1 if no default
    local vers = 1
    if GSE.isEmpty(GSE.Library[classid][sequenceName]) then
        return
    end
    if not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Default) then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Default
    end
    if not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Scenario) and GSE.inScenario then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Scenario
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Arena) and GSE.inArena then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Arena
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].PVP) and GSE.PVPFlag then
        vers = GSE.Library[classid][sequenceName]["MetaData"].PVP
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Raid) and GSE.inRaid then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Raid
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Heroic) and GSE.inHeroic then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Heroic
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Dungeon) and GSE.inDungeon then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Dungeon
    elseif not GSE.isEmpty(GSE.Library[classid][sequenceName]["MetaData"].Party) and GSE.inParty then
        vers = GSE.Library[classid][sequenceName]["MetaData"].Party
    end
    if vers == 0 then
        vers = 1
    end
    return vers
end

--- Return whether to store the macro in Personal Character Macros or Account Macros
function GSE.SetMacroLocation()
    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local returnval
    returnval = 1
    if numCharacterMacros >= MAX_CHARACTER_MACROS - 1 and GSEOptions.overflowPersonalMacros then
        returnval = nil
    end
    return returnval
end

function GSE.CreateMacroString(macroname)
    local returnVal = "#showtooltip\n/click "
    local state = GSE.GetMacroStringFormat()
    local t = state == "DOWN" and "t" or "f"

    if GSE.GetMacroStringFormat() == "DOWN" or GSEOptions.MacroResetModifiers["LeftButton"] then
        returnVal = returnVal .. "[button:1] " .. macroname .. " LeftButton " .. t .. "; "
    end
    if GSEOptions.MacroResetModifiers["RightButton"] then
        returnVal = returnVal .. "[button:2] " .. macroname .. " RightButton " .. t .. "; "
    end
    if GSEOptions.MacroResetModifiers["MiddleButton"] then
        returnVal = returnVal .. "[button:3] " .. macroname .. " MiddleButton " .. t .. "; "
    end
    if GSEOptions.MacroResetModifiers["Button4"] then
        returnVal = returnVal .. "[button:4] " .. macroname .. " Button4 " .. t .. "; "
    end
    if GSEOptions.MacroResetModifiers["Button5"] then
        returnVal = returnVal .. "[button:5] " .. macroname .. " Button5 " .. t .. "; "
    end
    if GSEOptions.virtualButtonSupport then
        returnVal = returnVal .. "[nobutton:1] " .. macroname .. "; "
    end

    returnVal = returnVal .. macroname
    return returnVal
end

--- Return the Macro Icon for the specified Sequence
function GSE.GetMacroIcon(classid, sequenceIndex)
    classid = tonumber(classid)
    GSE.PrintDebugMessage("sequenceIndex: " .. (GSE.isEmpty(sequenceIndex) and "No value" or sequenceIndex), GNOME)
    classid = tonumber(classid)
    local macindex = GetMacroIndexByName(sequenceIndex)
    local a, iconid, c = GetMacroInfo(macindex)
    if not GSE.isEmpty(a) then
        GSE.PrintDebugMessage(
            "Macro Found " ..
                a ..
                    " with iconid " ..
                        (GSE.isEmpty(iconid) and "of no value" or iconid) ..
                            " " .. (GSE.isEmpty(iconid) and L["with no body"] or c),
            GNOME
        )
    else
        GSE.PrintDebugMessage("No Macro Found. Possibly different spec for Sequence " .. sequenceIndex, GNOME)
        return GSEOptions.DefaultDisabledMacroIcon
    end

    local sequence = GSE.Library[classid][sequenceIndex]
    if GSE.isEmpty(sequence) then
        GSE.PrintDebugMessage("No Macro Found. Possibly different spec for Sequence " .. sequenceIndex, GNOME)
        return GSEOptions.DefaultDisabledMacroIcon
    end
    if GSE.isEmpty(sequence.Icon) and GSE.isEmpty(iconid) then
        GSE.PrintDebugMessage("SequenceSpecID: " .. sequence.Metadata.SpecID, GNOME)
        if sequence.Metadata.SpecID == 0 then
            return "INV_MISC_QUESTIONMARK"
        else
            local _, _, _, specicon, _, _, _ = GetTalentTabInfo(sequence.Metadata.SpecID)
            GSE.PrintDebugMessage("No Sequence Icon setting to " .. strsub(specicon, 17), GNOME)
            return strsub(specicon, 17)
        end
    elseif GSE.isEmpty(iconid) and not GSE.isEmpty(sequence.Icon) then
        return sequence.Icon
    else
        return iconid
    end
end

function GSE.GetSpellsFromString(str)
    local spellinfo = {}
    if string.sub(str, 14) == "/click GSE.Pau" then
        spellinfo.name = "GSE Pause"
        spellinfo.iconID = Statics.ActionsIcons.Pause
    else
        for cmd, oetc in gmatch(str or "", "/(%w+)%s+([^\n]+)") do
            if strlower(cmd) == "castsequence" then
                local returnspells = {}
                local processed = {}
                for _, y in ipairs(GSE.split(oetc, ";")) do
                    for _, v in ipairs(GSE.SplitCastSequence(y)) do
                        local _, _, etc = GSE.GetConditionalsFromString(v)
                        local elements = GSE.split(etc, ",")

                        for _, v1 in ipairs(elements) do
                            -- Replace C_Spell.GetSpellInfo with GetSpellInfo
                            local spellstuff = {GetSpellInfo(string.trim(v1))}
                            if spellstuff and spellstuff[1] and not processed[v1] then
                                table.insert(returnspells, {name = spellstuff[1], icon = spellstuff[3]})
                                processed[v1] = true
                            end
                        end
                    end
                end
                return returnspells
            elseif Statics.CastCmds[strlower(cmd)] then
                local _, _, etc = GSE.GetConditionalsFromString("/" .. cmd .. " " .. oetc)
                if string.sub(etc, 1, 1) == "/" then
                    etc = oetc
                end
                if cmd and etc and strlower(cmd) == "use" and tonumber(etc) and tonumber(etc) <= 16 then
                    -- we have a trinket
                else
                    local spell, _ = SecureCmdOptionParse(etc)
                    if spell then
                        -- Replace C_Spell.GetSpellInfo with GetSpellInfo
                        spellinfo.name, _, spellinfo.icon = GetSpellInfo(spell)
                    end
                end
            end
        end
    end
    if spellinfo and spellinfo.name then
        return spellinfo
    end
end

function GSE.CheckMacroCreated(SequenceName, create)
    local vals = {}
    vals.action = "CheckMacroCreated"
    vals.sequencename = SequenceName
    vals.create = create
    table.insert(GSE.OOCQueue, vals)
end

-- Rest of functions remain the same

GSE.DebugProfile("Storage")