local GSE = GSE
local L = GSE.L
local GNOME, _ = ...

local Statics = GSE.Static

--- Return the characters current spec id
function GSE.GetCurrentSpecID()
    if GSE.GameMode <= 4 then
        return GSE.GetCurrentClassID() and GSE.GetCurrentClassID()
    else
        -- MoP uses GetActiveTalentGroup() instead of GetSpecialization()
        local currentSpec = GetActiveTalentGroup()
        -- In MoP we return the talent group directly (1 or 2)
        return currentSpec or 0
    end
end

--- Return the current GCD for the current character
function GSE.GetGCD()
    local gcd
    local haste = UnitSpellHaste("player")
    gcd = 1.5 / (1 + 0.01 * haste)
    return gcd
end

--- Return the characters class id
function GSE.GetCurrentClassID()
    local _, _, currentclassId = UnitClass("player")
    return currentclassId
end

--- Return the characters class normalized name
function GSE.GetCurrentClassNormalisedName()
    local _, classnormalisedname, _ = UnitClass("player")
    return classnormalisedname
end

function GSE.GetClassIDforSpec(specid)
    -- Check for Classic WoW
    local classid = 0
    if GSE.GameMode < 5 then
        -- Classic WoW
        classid = Statics.SpecIDClassList[specid]
    else
        -- MoP doesn't have GetSpecializationInfoByID, use GetTalentTabInfo
        local _, _, _, _, role, class = GetTalentTabInfo(specid)
        if specid <= 11 then  -- MoP only has 11 classes
            classid = specid
        else
            for i = 1, 11, 1 do
                local _, st, _ = GetClassInfo(i)
                if class == st then
                    classid = i
                end
            end
        end
    end
    return classid
end

function GSE.GetClassIcon(classid)
    local classicon = {}
    classicon[1] = "Interface\\Icons\\inv_sword_27" -- Warrior
    classicon[2] = "Interface\\Icons\\ability_thunderbolt" -- Paladin
    classicon[3] = "Interface\\Icons\\inv_weapon_bow_07" -- Hunter
    classicon[4] = "Interface\\Icons\\inv_throwingknife_04" -- Rogue
    classicon[5] = "Interface\\Icons\\inv_staff_30" -- Priest
    classicon[6] = "Interface\\Icons\\inv_sword_27" -- Death Knight
    classicon[7] = "Interface\\Icons\\inv_jewelry_talisman_04" -- Shaman
    classicon[8] = "Interface\\Icons\\inv_staff_13" -- Mage
    classicon[9] = "Interface\\Icons\\spell_nature_drowsy" -- Warlock
    classicon[10] = "Interface\\Icons\\Spell_Holy_FistOfJustice" -- Monk
    classicon[11] = "Interface\\Icons\\inv_misc_monsterclaw_04" -- Druid
    return classicon[classid]
end

--- Check if the specID provided matches the players current class
function GSE.isSpecIDForCurrentClass(specID)
    -- Use GetTalentTabInfo instead of GetSpecializationInfoByID
    local _, specname, _, specicon, _, specrole = GetTalentTabInfo(specID)
    local currentclassDisplayName, currentenglishclass, currentclassId = UnitClass("player")
    
    if specID > 11 then -- MoP only has 11 classes
        GSE.PrintDebugMessage("Checking if specID " .. specID .. " " .. specrole .. " equals " .. currentenglishclass)
    else
        GSE.PrintDebugMessage("Checking if specID " .. specID .. " equals currentclassid " .. currentclassId)
    end
    return (specrole == currentenglishclass or specID == currentclassId)
end

function GSE.GetSpecNames()
    local keyset = {}
    for _, v in pairs(Statics.SpecIDList) do
        keyset[v] = v
    end
    return keyset
end

--- Returns the Character Name in the form Player@server
function GSE.GetCharacterName()
    return GetUnitName("player", true) .. "@" .. GetRealmName()
end

--- Returns the current Talent Selections as a string
function GSE.GetCurrentTalents()
    local talents = ""
    -- In MoP we need to iterate through talent tiers
    for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
            local _, _, _, selected = GetTalentInfo(tier, column, GetActiveSpecGroup())
            if selected then
                talents = talents .. tier .. "," .. column .. "/"
            end
        end
    end
    return talents
end

--- Experimental attempt to load a WeakAuras string.
function GSE.LoadWeakAura(str)
    if IsAddOnLoaded("WeakAuras") then
        WeakAuras.OpenOptions()
        WeakAuras.OpenOptions()
        WeakAuras.Import(str)
    else
        GSE.Print(L["WeakAuras was not found."])
    end
end

if not SaveBindings then
    function SaveBindings(p)
        AttemptToSaveBindings(p)
    end
end

--- This function clears the Shift+n and CTRL+x keybindings.
function GSE.ClearCommonKeyBinds()
    local combinators = {"SHIFT", "CTRL", "ALT"}
    local defaultbuttons = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="}
    for _, p in ipairs(combinators) do
        for _, v in ipairs(defaultbuttons) do
            SetBinding(p .. "-" .. v)
            GSE.PrintDebugMessage("Cleared KeyCombination " .. p .. v)
        end
        SetBinding(p)
    end
    local char = UnitFullName("player")
    local realm = GetRealmName()
    GSE_C = {}
    GSE_C["KeyBindings"] = {}
    GSE_C["KeyBindings"][char .. "-" .. realm] = {}
    GSE_C["KeyBindings"][char .. "-" .. realm][tostring(GetActiveTalentGroup())] = {}
    -- Save for this character
    SaveBindings(2)
    GSE.Print("Common Keybinding combinations cleared for this character.")
end

--- Obtain the Click Rate from GSE Options or from the characters internal options
function GSE.GetClickRate()
    local clickRate = GSEOptions.msClickRate and GSEOptions.msClickRate or 250
    if GSE.isEmpty(GSE_C) then
        GSE_C = {}
    end
    if not GSE.isEmpty(GSE_C.msClickRate) then
        clickRate = GSE_C.msClickRate
    end
    return clickRate
end

function GSE.GetResetOOC()
    if GSE.isEmpty(GSE_C) then
        GSE_C = {}
    end
    return GSE_C.resetOOC and GSE_C.resetOOC or GSEOptions.resetOOC
end

function GSE.setActionButtonUseKeyDown()
    local state = GSEOptions.CvarActionButtonState and GSEOptions.CvarActionButtonState or "DONTFORCE"

    if state == "UP" then
        SetCVar("ActionButtonUseKeyDown", 0)  -- Use SetCVar instead of C_CVar
        GSE.Print(
            L[
                "The UI has been set to KeyUp configuration.  The /click command needs to be `/click TEMPLATENAME` You will need to check your macros and adjust your click commands."
            ],
            L["GSE"] .. " " .. L["Troubleshooting"]
        )
    elseif state == "DOWN" then
        SetCVar("ActionButtonUseKeyDown", 1)  -- Use SetCVar instead of C_CVar
        GSE.Print(
            L[
                "The UI has been set to KeyDown configuration.  The /click command needs to be `/click TEMPLATENAME LeftButton t` (Note the 't' here is required along with the LeftButton.)  You will need to check your macros and adjust your click commands."
            ],
            L["GSE"] .. " " .. L["Troubleshooting"]
        )
    end
    GSE.ReloadSequences()
end

-- Remove functions that use modern talent system APIs
function GSE.GetSelectedLoadoutConfigID()
    return nil  -- MoP doesn't have loadouts
end

GSE.DebugProfile("CharacterFuntions")