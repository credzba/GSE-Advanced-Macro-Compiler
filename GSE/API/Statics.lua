local GSE = GSE
local Statics = GSE.Static
local L = GSE.L
GSE.Library = {}

Statics.CastCmds = {
    use = true,
    cast = true,
    spell = true,
    cancelaura = true,
    cancelform = true,
    stopmacro = true,
    petautocastoff = true,
    petautocaston = true,
    usetoy = true,
    toy = true
}

Statics.MacroCommands = {
    "petattack",
    "dismount",
    "shoot",
    "startattack",
    "stopattack",
    "targetenemy",
    "click",
    "castrandom",
    "cancelqueuedspell",
    "cqs",
    "assist",
    "clearfocus",
    "cleartarget",
    "focus",
    "target",
    "targetfriend",
    "targetlasttarget"
}

Statics.CleanStrings = {
    [1] = "/console Sound_EnableSFX 0%;",
    [2] = "/console Sound_EnableSFX 1%;",
    [3] = "/script UIErrorsFrame:Hide%(%)%;",
    [4] = "/run UIErrorsFrame:Clear%(%)%;",
    [5] = "/script UIErrorsFrame:Clear%(%)%;",
    [6] = "/run UIErrorsFrame:Hide%(%)%;",
    [7] = "/console Sound_EnableErrorSpeech 1",
    [8] = "/console Sound_EnableErrorSpeech 0",
    [11] = "/console Sound_EnableSFX 0",
    [12] = "/console Sound_EnableSFX 1",
    [13] = "/script UIErrorsFrame:Hide%(%)",
    [14] = "/run UIErrorsFrame:Clear%(%)",
    [15] = "/script UIErrorsFrame:Clear%(%)",
    [16] = "/run UIErrorsFrame:Hide%(%)",
    [17] = "/console Sound_EnableErrorSpeech 1%;",
    [18] = "/console Sound_EnableErrorSpeech 0%;",
    [19] = [[""]],
    [101] = "\n\n"
}

Statics.GSEString = "|cFFFFFFFFGS|r|cFF00FFFFE|r"
Statics.StringReset = "|r"
Statics.CoreLoadedMessage = "GS-CoreLoaded"

Statics.SystemVariables = {
    ["GCD"] = function()
        return GSE.GetGCD()
    end
}

-- Update SpecIDClassList for MoP
GSE.SpecIDClassList = {
    [0] = 0,
    [1] = 1, -- Warrior
    [2] = 2, -- Paladin
    [3] = 3, -- Hunter
    [4] = 4, -- Rogue
    [5] = 5, -- Priest
    [6] = 6, -- Death Knight
    [7] = 7, -- Shaman
    [8] = 8, -- Mage
    [9] = 9, -- Warlock
    [10] = 10, -- Monk
    [11] = 11, -- Druid
}

local function determineSpecializationName(specID)
    local _, specname = GetTalentTabInfo(specID)
    return specname
end

local function determineClassName(classID)
    if classID == 0 then
        return L["Global"]
    end
    local className = LOCALIZED_CLASS_NAMES_MALE[classID]
    return className
end

function GSE.GetClassName(classID)
    return determineClassName(classID)
end

Statics.SpecIDList = {}

-- MoP only has 11 classes
Statics.SpecIDList = {
    [0] = L["Global"],
    [1] = determineClassName(1),
    [2] = determineClassName(2),
    [3] = determineClassName(3),
    [4] = determineClassName(4),
    [5] = determineClassName(5),
    [6] = determineClassName(6),
    [7] = determineClassName(7),
    [8] = determineClassName(8),
    [9] = determineClassName(9),
    [10] = determineClassName(10),
    [11] = determineClassName(11)
}

Statics.SpecIDHashList = {}
for k, v in pairs(Statics.SpecIDList) do
    Statics.SpecIDHashList[v] = k
end

Statics.SequenceDebug = "SEQUENCEDEBUG"

Statics.Priority = "Priority"
Statics.Sequential = "Sequential"
Statics.ReversePriority = "ReversePriority"
Statics.Random = "Random"

Statics.PrintKeyModifiers = [[
print("Right alt key " .. tostring(IsRightAltKeyDown()))
print("Left alt key " .. tostring(IsLeftAltKeyDown()))
print("Any alt key " .. tostring(IsAltKeyDown()))
print("Right ctrl key " .. tostring(IsRightControlKeyDown()))
print("Left ctrl key " .. tostring(IsLeftControlKeyDown()))
print("Any ctrl key " .. tostring(IsControlKeyDown()))
print("Right shft key " .. tostring(IsRightShiftKeyDown()))
print("Left shft key " .. tostring(IsLeftShiftKeyDown()))
print("Any shft key " .. tostring(IsShiftKeyDown()))
print("Any mod key " .. tostring(IsModifierKeyDown()))
print("GetMouseButtonClicked() " .. GetMouseButtonClicked() )
]]

Statics.StringFormatEscapes = {
    ["|c%x%x%x%x%x%x%x%x"] = "", -- Color start
    ["|r"] = "", -- Color end
    ["|H.-|h(.-)|h"] = "%1", -- Links
    ["|T.-|t"] = "", -- Textures
    ["{.-}"] = "" -- Raid target icons
}

Statics.MacroResetSkeleton = [[
if %s then
    self:SetAttribute('step', 1)
    print("|cFFFFFFFFGS|r|cFF00FFFFE|r Resetting " .. self:GetAttribute("name") .. " to step 1.")
end
]]

Statics.SourceLocal = "Local"
Statics.SourceTransmission = "Transmission"
Statics.DebugModules = {}
Statics.DebugModules["Translator"] = "Translator"
Statics.DebugModules["Storage"] = "Storage"
Statics.DebugModules["Editor"] = "Editor"
Statics.DebugModules["Viewer"] = "Viewer"
Statics.DebugModules["Versions"] = "Versions"
Statics.DebugModules[Statics.SourceTransmission] = Statics.SourceTransmission
Statics.DebugModules["API"] = "API"
Statics.DebugModules["GUI"] = "GUI"
Statics.DebugModules["Startup"] = "Startup"

Statics.TranslationKey = "KEY"
Statics.TranslationHash = "HASH"
Statics.TranslationShadow = "SHADOW"

Statics.Spec = "Spec"
Statics.Class = "Class"
Statics.All = "All"
Statics.Global = "Global"

Statics.SampleMacros = {}
Statics.QuestionMark = "INV_MISC_QUESTIONMARK"
Statics.QuestionMarkIconID = 134400
Statics.ReloadMessage = "Reload"
Statics.CommPrefix = "GSE"

-- Remove modern spell override table as it doesn't exist in MoP
Statics.BaseSpellTable = {}

Statics.Actions = {}
Statics.Actions.Loop = "Loop"
Statics.Actions.If = "If"
Statics.Actions.Repeat = "Repeat"
Statics.Actions.Action = "Action"
Statics.Actions.Pause = "Pause"

Statics.ActionsIcons = {}
Statics.ActionsIcons.Loop = "Interface\\Addons\\GSE_GUI\\Assets\\loop.tga"
Statics.ActionsIcons.If = "Interface\\Addons\\GSE_GUI\\Assets\\if.tga"
Statics.ActionsIcons.Repeat = "Interface\\Addons\\GSE_GUI\\Assets\\repeat.tga"
Statics.ActionsIcons.Action = "Interface\\Addons\\GSE_GUI\\Assets\\action.tga"
Statics.ActionsIcons.Pause = "Interface\\Addons\\GSE_GUI\\Assets\\pause.tga"
Statics.ActionsIcons.Up = "Interface\\Addons\\GSE_GUI\\Assets\\up.tga"
Statics.ActionsIcons.Down = "Interface\\Addons\\GSE_GUI\\Assets\\down.tga"
Statics.ActionsIcons.Delete = "Interface\\Addons\\GSE_GUI\\Assets\\delete.tga"
Statics.ActionsIcons.Key = "Interface\\Addons\\GSE_GUI\\Assets\\2key.png"
Statics.ActionsIcons.Settings = "Interface\\Addons\\GSE_GUI\\Assets\\cog.png"

Statics.GSE3OnClick = [[
local step = self:GetAttribute('step')
step = tonumber(step)
self:SetAttribute('macrotext', macros[step] )
step = step % #macros + 1
if not step or not macros[step] then -- User attempted to write a step method that doesn't work, reset to 1
    print('|cffff0000Invalid step assigned by custom step sequence', self:GetName(), step or 'nil', '|r')
    step = 1
end
self:SetAttribute('step', step)
self:CallMethod('UpdateIcon')
]]

Statics.TranslatorMode = {}
Statics.TranslatorMode.Current = "CURRENT"
Statics.TranslatorMode.String = "STRING"
Statics.TranslatorMode.ID = "ID"

StaticPopupDialogs["GSE_ConfirmReloadUIDialog"] = {
    text = L["You need to reload the User Interface to complete this task.  Would you like to do this now?"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

GSE.DebugProfile("Statics")