local GNOME,_ = ...
GSSE = LibStub("AceAddon-3.0"):NewAddon("GSSE", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("GS-SE")
local currentSequence = ""
local importStr = ""
local otherversionlistboxvalue = ""

GSSequenceEditorLoaded = false
local sequenceboxtext = AceGUI:Create("MultiLineEditBox")
local remotesequenceboxtext = AceGUI:Create("MultiLineEditBox")
local boxes = {}

function GSSE:parsetext(editbox)
  if GSMasterOptions.RealtimeParse then
    text = GSTRUnEscapeString(editbox:GetText())
    returntext = GSTranslateString(text , GetLocale(), GetLocale(), true)
    editbox:SetText(returntext)
    editbox:SetCursorPosition(string.len(returntext)+2)
  end
end

function GSSE:getSequenceNames()
  local keyset={}
  local currentSpec = GetSpecialization()
  local currentSpecID = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or ""
  if not GSisEmpty(currentSpecID) then
    local _, _, _, _, _, _, pspecclass = GetSpecializationInfoByID(currentSpecID)
    for k,v in pairs(GSMasterOptions.ActiveSequenceVersions) do

      local sid, specname, specdescription, specicon, sbackground, specrole, specclass = GetSpecializationInfoByID(GSMasterOptions.SequenceLibrary[k][v].specID)
      if not GSMasterOptions.filterList["All"] then
        if GSMasterOptions.filterList["Class"] then
          if pspecclass == specclass then
            keyset[k]=k
          end
        elseif GSMasterOptions.SequenceLibrary[k][v].specID == currentSpecID then
          keyset[k]=k
        end
      else
        keyset[k]=k
      end
    end
  end
  -- Filter Keyset
  return keyset
end
-- Create functions for tabs
function GSSE:drawstandardwindow(container)
  local sequencebox = AceGUI:Create("MultiLineEditBox")
  sequencebox:SetLabel(L["Sequence"])
  sequencebox:SetNumLines(20)
  sequencebox:DisableButton(true)
  sequencebox:SetFullWidth(true)
  sequencebox:SetText(sequenceboxtext:GetText())
  sequencebox:SetCallback("OnEnter", function() sequencebox:HighlightText(1, string.len(sequencebox:GetText())) end)
  container:AddChild(sequencebox)

  local buttonGroup = AceGUI:Create("SimpleGroup")
  buttonGroup:SetFullWidth(true)
  buttonGroup:SetLayout("Flow")

  local updbutton = AceGUI:Create("Button")
  updbutton:SetText(L["Create / Edit"])
  updbutton:SetWidth(200)
  updbutton:SetCallback("OnClick", function() GSSE:LoadEditor(currentSequence) end)
  buttonGroup:AddChild(updbutton)

  local impbutton = AceGUI:Create("Button")
  impbutton:SetText(L["Import"])
  impbutton:SetWidth(200)
  impbutton:SetCallback("OnClick", function() importStr = sequenceboxtext:GetText(); GSSE:importSequence() end)
  buttonGroup:AddChild(impbutton)

  local versbutton = AceGUI:Create("Button")
  versbutton:SetText(L["Manage Versions"])
  versbutton:SetWidth(200)
  versbutton:SetCallback("OnClick", function() GSSE:ManageSequenceVersion() end)
  buttonGroup:AddChild(versbutton)

  container:AddChild(buttonGroup)

  sequenceboxtext = sequencebox
end

function GSSE:drawsecondarywindow(container)
  local languages = GSTRListCachedLanguages()
  local listbox = AceGUI:Create("Dropdown")
  listbox:SetLabel(L["Choose Language"])
  listbox:SetWidth(250)
  listbox:SetList(languages)
  listbox:SetCallback("OnValueChanged", function (obj,event,key) GSSE:loadTranslatedSequence(GSTRListCachedLanguages()[key]) end)
  container:AddChild(listbox)

  local remotesequencebox = AceGUI:Create("MultiLineEditBox")
  remotesequencebox:SetLabel(L["Translated Sequence"])
  remotesequencebox:SetText(remotesequenceboxtext:GetText())
  remotesequencebox:SetNumLines(20)
  remotesequencebox:DisableButton(true)
  remotesequencebox:SetFullWidth(true)
  container:AddChild(remotesequencebox)
  remotesequenceboxtext = remotesequencebox

end

-- Callback function for OnGroupSelected
function GSSE:SelectGroup(container, event, group)
   local tremote = remotesequenceboxtext:GetText()
   local tlocal = sequenceboxtext:GetText()
   container:ReleaseChildren()
   GSPrintDebugMessage(L["Selecting tab: "] .. group, GNOME)
   if group == "localtab" then
      GSSE:drawstandardwindow(container)
   elseif group == "remotetab" then
      GSSE:drawsecondarywindow(container)
   end
   remotesequenceboxtext:SetText(tremote)
   sequenceboxtext:SetText(tlocal)
end
-- function that draws the widgets for the first tab


local frame = AceGUI:Create("Frame")
local curentSequence
frame:SetTitle(L["Sequence Viewer"])
frame:SetStatusText(L["Gnome Sequencer: Sequence Viewer"])
frame:SetCallback("OnClose", function(widget) frame:Hide() end)
frame:SetLayout("List")


local listbox = AceGUI:Create("Dropdown")
listbox:SetLabel(L["Load Sequence"])
listbox:SetWidth(250)
listbox:SetCallback("OnValueChanged", function (obj,event,key) GSSE:loadSequence(key) currentSequence = key end)
frame:AddChild(listbox)



if GSTranslatorAvailable and GSMasterOptions.useTranslator and GSAdditionalLanguagesAvailable then
  local tab =  AceGUI:Create("TabGroup")
  tab:SetLayout("Flow")
  -- Setup which tabs to show
  tab:SetTabs({{text=GetLocale(), value="localtab"}, {text=L["Translate to"], value="remotetab"}})
  -- Register callback
  tab:SetCallback("OnGroupSelected",  function (container, event, group) GSSE:SelectGroup(container, event, group) end)
  -- Set initial Tab (this will fire the OnGroupSelected callback)
  tab:SelectTab("localtab")
  tab:SetFullWidth(true)
  -- add to the frame container
  frame:AddChild(tab)
else
  GSSE:drawstandardwindow(frame)
end

-------------end viewer-------------
-------------begin editor--------------------
local editframe = AceGUI:Create("Frame")
local stepvalue

local headerGroup = AceGUI:Create("SimpleGroup")
headerGroup:SetFullWidth(true)
headerGroup:SetLayout("Flow")

local firstheadercolumn = AceGUI:Create("SimpleGroup")
--firstheadercolumn:SetFullWidth(true)
firstheadercolumn:SetLayout("List")

editframe:SetTitle(L["Sequence Editor"])
editframe:SetStatusText(L["Gnome Sequencer: Sequence Editor. Press the Close button to Save -->"])
editframe:SetCallback("OnClose", function() GSSE:UpdateSequenceDefinition(currentSequence, GSSequenceEditorLoaded) end)
editframe:SetLayout("List")

local nameeditbox = AceGUI:Create("EditBox")
nameeditbox:SetLabel(L["Sequence Name"])
nameeditbox:SetWidth(250)
firstheadercolumn:AddChild(nameeditbox)

local stepdropdown = AceGUI:Create("Dropdown")
stepdropdown:SetLabel(L["Step Function"])
stepdropdown:SetWidth(250)
stepdropdown:SetList({
  ["1"] = L["Sequential (1 2 3 4)"],
  ["2"] = L["Priority List (1 12 123 1234)"],

})

stepdropdown:SetCallback("OnValueChanged", function (obj,event,key) stepvalue = key end)
firstheadercolumn:AddChild(stepdropdown)

local specClassGroup = AceGUI:Create("SimpleGroup")
specClassGroup:SetFullWidth(true)
specClassGroup:SetLayout("Flow")

local specradio = AceGUI:Create("CheckBox")
specradio:SetType("radio")
specradio:SetLabel(L["Specialization Specific Macro"])
specradio:SetValue(true)
specradio:SetWidth(250)
specradio:SetCallback("OnValueChanged", function (obj,event,key) GSSE:toggleClasses("spec")  end)

local classradio = AceGUI:Create("CheckBox")
classradio:SetType("radio")
classradio:SetLabel(L["Classwide Macro"])
classradio:SetValue(false)
classradio:SetWidth(250)
classradio:SetCallback("OnValueChanged", function (obj,event,key) GSSE:toggleClasses("class")  end)


specClassGroup:AddChild(specradio)
specClassGroup:AddChild(classradio)


headerGroup:AddChild(firstheadercolumn)

local iconpicker = AceGUI:Create("Icon")
--iconpicker:SetImage()
iconpicker:SetLabel(L["Macro Icon"])
--iconpicker:OnClick(MacroPopupButton_SelectTexture(editframe:GetID() + (FauxScrollFrame_GetOffset(MacroPopupScrollFrame) * NUM_ICONS_PER_ROW)))

headerGroup:AddChild(iconpicker)
editframe:AddChild(headerGroup)
editframe:AddChild(specClassGroup)

local premacrobox = AceGUI:Create("MultiLineEditBox")
premacrobox:SetLabel(L["PreMacro"])
premacrobox:SetNumLines(3)
premacrobox:DisableButton(true)
premacrobox:SetFullWidth(true)
--premacrobox.editBox:SetScript("OnLeave", OnTextChanged)

editframe:AddChild(premacrobox)
premacrobox.editBox:SetScript( "OnLeave",  function(self) GSSE:parsetext(self) end)


local spellbox = AceGUI:Create("MultiLineEditBox")
spellbox:SetLabel(L["Sequence"])
spellbox:SetNumLines(9)
spellbox:DisableButton(true)
spellbox:SetFullWidth(true)
spellbox.editBox:SetScript( "OnLeave",  function(self) GSSE:parsetext(self) end)
editframe:AddChild(spellbox)

local postmacrobox = AceGUI:Create("MultiLineEditBox")
postmacrobox:SetLabel(L["PostMacro"])
postmacrobox:SetNumLines(3)
postmacrobox:DisableButton(true)
postmacrobox:SetFullWidth(true)
postmacrobox.editBox:SetScript( "OnLeave",  function(self) GSSE:parsetext(self) end)
editframe:AddChild(postmacrobox)

-------------end editor-----------------

local versionframe = AceGUI:Create("Frame")
versionframe:SetTitle(L["Manage Versions"])
versionframe:SetStatusText(L["Gnome Sequencer: Sequence Version Manager"])
versionframe:SetCallback("OnClose", function(widget)  versionframe:Hide(); frame:Show() end)
versionframe:SetLayout("List")

local columnGroup = AceGUI:Create("SimpleGroup")
columnGroup:SetFullWidth(true)
columnGroup:SetLayout("Flow")

local leftGroup = AceGUI:Create("SimpleGroup")
leftGroup:SetFullWidth(true)
leftGroup:SetLayout("List")

local rightGroup = AceGUI:Create("SimpleGroup")
rightGroup:SetFullWidth(true)
rightGroup:SetLayout("List")


local activesequencebox = AceGUI:Create("MultiLineEditBox")
activesequencebox:SetLabel(L["Active Version: "] .. GSGetActiveSequenceVersion(currentSequence) )
activesequencebox:SetNumLines(11)
activesequencebox:DisableButton(true)
activesequencebox:SetFullWidth(true)
leftGroup:AddChild(activesequencebox)

local otherSequenceVersions = AceGUI:Create("MultiLineEditBox")
otherSequenceVersions:SetLabel(L["Other Versions"])
otherSequenceVersions:SetNumLines(11)
otherSequenceVersions:DisableButton(true)
otherSequenceVersions:SetFullWidth(true)
rightGroup:AddChild(otherSequenceVersions)

local otherversionlistbox = AceGUI:Create("Dropdown")
otherversionlistbox:SetWidth(250)
otherversionlistbox:SetCallback("OnValueChanged", function (obj,event,key) GSSE:ChangeOtherSequence(key) end)
rightGroup:AddChild(otherversionlistbox)

columnGroup:AddChild(leftGroup)
columnGroup:AddChild(rightGroup)

versionframe:AddChild(columnGroup)

local othersequencebuttonGroup = AceGUI:Create("SimpleGroup")
othersequencebuttonGroup:SetFullWidth(true)
othersequencebuttonGroup:SetLayout("Flow")

local actbutton = AceGUI:Create("Button")
actbutton:SetText(L["Make Active"])
actbutton:SetWidth(200)
actbutton:SetCallback("OnClick", function() GSSE:SetActiveSequence(otherversionlistboxvalue) end)
othersequencebuttonGroup:AddChild(actbutton)

local delbutton = AceGUI:Create("Button")
delbutton:SetText(L["Delete Version"])
delbutton:SetWidth(200)
delbutton:SetCallback("OnClick", function() GSDeleteSequenceVersion(currentSequence, otherversionlistboxvalue); otherversionlistbox:SetList(GSGetKnownSequenceVersions(currentSequence)); otherSequenceVersions:SetText("")  end)
othersequencebuttonGroup:AddChild(delbutton)



versionframe:AddChild(othersequencebuttonGroup)

-- Slash Commands

GSSE:RegisterChatCommand("gsse", "GSSlash")

-- Functions
function GSSE:SetActiveSequence(key)
  GSSetActiveSequenceVersion(currentSequence, key)
  GSUpdateSequence(currentSequence, GSMasterOptions.SequenceLibrary[currentSequence][key])
  activesequencebox:SetLabel(L["Active Version: "] .. GSGetActiveSequenceVersion(currentSequence) )
  activesequencebox:SetText(GSExportSequencebySeq(GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary[currentSequence][GSGetActiveSequenceVersion(currentSequence)], GetLocale(), GetLocale()), currentSequence))
  otherversionlistbox:SetList(GSGetKnownSequenceVersions(currentSequence))
end

function GSSE:ChangeOtherSequence(key)
  otherversionlistboxvalue = key
  otherSequenceVersions:SetText(GSExportSequencebySeq(GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary[currentSequence][key], (GSisEmpty(GSMasterOptions.SequenceLibrary[currentSequence][key].lang) and GetLocale() or GSMasterOptions.SequenceLibrary[currentSequence][key].lang ), GetLocale()), currentSequence))
end

function GSSE:importSequence()
  local functiondefinition =  importStr .. [===[

  return Sequences
  ]===]
  GSPrintDebugMessage (functiondefinition, "GS-SequenceEditor")
  local fake_globals = setmetatable({
    Sequences = {},
    }, {__index = _G})
  local func, err = loadstring (functiondefinition, "GS-SequenceEditor")
  if func then
    -- Make the compiled function see this table as its "globals"
    setfenv (func, fake_globals)

    local TempSequences = assert(func())
    if not GSisEmpty(TempSequences) then
      local newkey = ""
      for k,v in pairs(TempSequences) do

        if GSisEmpty(v.version) then
          v.version = GSGetNextSequenceVersion(k)
        end
        v.source = GSStaticSourceLocal
        GSAddSequenceToCollection(k, v, v.version)
        newkey = k
      end
      names = GSSE:getSequenceNames()
      listbox:SetList(names)
      listbox:SetValue(newkey)
    end
  else
    GSPrintDebugMessage (err, GNOME)
  end

end

function GSSE:ManageSequenceVersion()
  frame:Hide()
  versionframe:SetTitle(L["Manage Versions"] .. ": " .. currentSequence )
  activesequencebox:SetText(sequenceboxtext:GetText())
  otherversionlistbox:SetList(GSGetKnownSequenceVersions(currentSequence))
  versionframe:Show()
end

function GSSE:loadTranslatedSequence(key)
  GSPrintDebugMessage(L["GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary["] .. currentSequence .. L["], (GSisEmpty(GSMasterOptions.SequenceLibrary["] .. currentSequence .. L["].lang) and GSMasterOptions.SequenceLibrary["] .. currentSequence .. L["].lang or GetLocale()), key)"] , GNOME)
  remotesequenceboxtext:SetText(GSExportSequencebySeq(GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary[currentSequence][GSGetActiveSequenceVersion(currentSequence)], (GSisEmpty(GSMasterOptions.SequenceLibrary[currentSequence][GSGetActiveSequenceVersion(currentSequence)].lang) and GetLocale() or GSMasterOptions.SequenceLibrary[currentSequence][GSGetActiveSequenceVersion(currentSequence)].lang ), key), currentSequence))
end

function GSSE:loadSequence(SequenceName)
  GSPrintDebugMessage(L["GSSE:loadSequence "] .. SequenceName)
  if GSAdditionalLanguagesAvailable and GSMasterOptions.useTranslator then
    sequenceboxtext:SetText(GSExportSequencebySeq(GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary[SequenceName][GSGetActiveSequenceVersion(SequenceName)], (GSisEmpty(GSMasterOptions.SequenceLibrary[SequenceName][GSGetActiveSequenceVersion(SequenceName)].lang) and "enUS" or GSMasterOptions.SequenceLibrary[SequenceName][GSGetActiveSequenceVersion(SequenceName)].lang), GetLocale()), SequenceName))
  elseif GSTranslatorAvailable then
    sequenceboxtext:SetText(GSExportSequencebySeq(GSTranslateSequenceFromTo(GSMasterOptions.SequenceLibrary[SequenceName][GSGetActiveSequenceVersion(SequenceName)], GetLocale(), GetLocale()), SequenceName))
  else
    sequenceboxtext:SetText(GSExportSequence(SequenceName))
  end
end

function GSSE:toggleClasses(buttonname)
  if buttonname == "class" then
    classradio:SetValue(true)
    specradio:SetValue(false)
  else
    classradio:SetValue(false)
    specradio:SetValue(true)
  end
end

function GSSE:LoadEditor(SequenceName)
  if GSisEmpty(SequenceName) then
    local _, _, _, specicon, _, _, _ = GetSpecializationInfoByID(GSSE:getSpecID())
    SequenceName = "LiveTest"
    -- Get next version needed here
    GSMasterOptions.SequenceLibrary[SequenceName][1] = {
    specID = GSSE:getSpecID(),
  	author = "Draik",
    icon = 134400,
  	helpTxt = L["Completely New GS Macro."],
  	"/cast Auto Attack",
  	}
    GSSE:loadSequence("LiveTest")
  end
  GSPrintDebugMessage("SequenceName: " .. SequenceName, GNOME)
  frame:Hide()
  local nextseqval = GSGetActiveSequenceVersion(SequenceName)
  if GSisEmpty(GSMasterOptions.SequenceLibrary[SequenceName]) then
    GSMasterOptions.SequenceLibrary[SequenceName] = {}
  end
  GSMasterOptions.SequenceLibrary[SequenceName][nextseqval] = GSMasterOptions.SequenceLibrary[SequenceName][GSGetActiveSequenceVersion(SequenceName)]
  GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].author = GetUnitName("player", true) .. '@' .. GetRealmName()
  reticon = GSSE:getMacroIcon(SequenceName)
  -- if string prefix with "Interface\\Icons\\" if number make it a number
  if not tonumber(reticon) then
    -- we have a starting
    reticon = "Interface\\Icons\\" .. reticon
  end
  GSPrintDebugMessage("returned icon: " .. reticon, GNOME)

  -- show editor
  nameeditbox:SetText(SequenceName)
  if GSisEmpty(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].StepFunction) then
   stepdropdown:SetValue("1")
  else
   stepdropdown:SetValue("2")
  end
  if GSisEmpty(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].PreMacro) then
    GSPrintDebugMessage(L["Moving on - LiveTest.PreMacro already exists."], GNOME)
  else
   premacrobox:SetText(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].PreMacro)
  end
  if GSisEmpty(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].PostMacro) then
    GSPrintDebugMessage(L["Moving on - LiveTest.PosMacro already exists."], GNOME)
  else
   postmacrobox:SetText(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].PostMacro)
  end
  spellbox:SetText(table.concat(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval],"\n"))
  iconpicker:SetImage(GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].icon)
  editframe:Show()
  GSMasterOptions.ActiveSequenceVersions[SequenceName] = nextseqval
  GSMasterOptions.SequenceLibrary[SequenceName][nextseqval].version = nextseqval
end

function GSSE:UpdateSequenceDefinition(SequenceName, loaded)
    --process Lines
    if loaded then
      nextVal = GSGetNextSequenceVersion(currentSequence)
      local sequence = {}
      GSSE:lines(sequence, spellbox:GetText())
      -- update sequence
      if stepvalue == "2" then
        sequence.StepFunction = GSStaticPriority
      else
        sequence.StepFunction = nil
      end
      sequence.PreMacro = premacrobox:GetText()
      sequence.author = GetUnitName("player", true) .. '@' .. GetRealmName()
      sequence.source = GSStaticSourceLocal
      sequence.specID = GSSE:getSpecID()
      sequence.helpTxt = "Talents: " .. GSSE:getCurrentTalents()
      if not tonumber(sequence.icon) then
        sequence.icon = "INV_MISC_QUESTIONMARK"
      end
      sequence.PostMacro = postmacrobox:GetText()
      sequence.version = nextVal
      GSTRUnEscapeSequence(sequence)
      GSAddSequenceToCollection(SequenceName, sequence, nextVal)
      GSSE:loadSequence(SequenceName)
      editframe:Hide()
      frame:Show()
    else
      GSSequenceEditorLoaded = true
    end
end

function GSSE:GSSlash(input)
    if input == "hide" then
      frame:Hide()
    else
      if not InCombatLockdown() then
        local names = GSSE:getSequenceNames()
        listbox:SetList(names)
        frame:Show()
      else
        print(GSMasterOptions.TitleColour .. GNOME .. L[":|r Please wait till you have left combat before using the Sequence Editor."])
      end
    end
end

function GSSE:OnInitialize()
    versionframe:Hide()
    editframe:Hide()
    frame:Hide()
    print(GSMasterOptions.TitleColour .. GNOME .. L[":|r The Sequence Editor is an addon for GnomeSequencer-Enhanced that allows you to view and edit Sequences in game.  Type "] .. GSMasterOptions.CommandColour .. L["/gsse |r to get started."])
end

function GSSE:getCurrentTalents()
  local talents = ""
  for talentTier = 1, MAX_TALENT_TIERS do
    local available, selected = GetTalentTierInfo(talentTier, 1)
    talents = talents .. (available and selected or "0")
  end
  return talents
end

function GSSE:getSpecID(forceSpec)
    GSPrintDebugMessage(L["Spec = "] .. tostring(specradio:GetValue()), GNOME)
    GSPrintDebugMessage(L["Class = "] .. tostring(classradio:GetValue()), GNOME)
    if specradio:GetValue() or forceSpec then
      local currentSpec = GetSpecialization()
      return currentSpec and select(1, GetSpecializationInfo(currentSpec)) or "None"
    else
      local _, _, currentclassId = UnitClass("player")
      return currentclassId
    end
end

function GSSE:getMacroIcon(sequenceIndex)
  GSPrintDebugMessage(L["sequenceIndex: "] .. (GSisEmpty(sequenceIndex) and L["No value"] or sequenceIndex), GNOME)
  GSPrintDebugMessage(L["Icon: "] .. (GSisEmpty(GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].icon) and L["none"] or GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].icon))
  local macindex = GetMacroIndexByName(sequenceIndex)
  local a, iconid, c =  GetMacroInfo(macindex)
  if not GSisEmpty(a) then
    GSPrintDebugMessage(L["Macro Found "] .. a .. L[" with iconid "] .. (GSisEmpty(iconid) and L["of no value"] or iconid) .. " " .. (GSisEmpty(iconid) and L["with no body"] or c), GNOME)
  else
    GSPrintDebugMessage(L["No Macro Found. Possibly different spec for Sequence "] .. sequenceIndex , GNOME)
  end
  if GSisEmpty(GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].icon) and GSisEmpty(iconid) then
    GSPrintDebugMessage("SequenceSpecID: " .. GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].specID, GNOME)
    local _, _, _, specicon, _, _, _ = GetSpecializationInfoByID((GSisEmpty(GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].specID) and GSSE:getSpecID(true) or GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].specID))
    GSPrintDebugMessage(L["No Sequence Icon setting to "] .. (GSisEmpty(strsub(specicon, 17)) and L["No value"] or strsub(specicon, 17)), GNOME)
    return strsub(specicon, 17)
  elseif GSisEmpty(iconid) and not GSisEmpty(GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].icon) then

      return GSMasterOptions.SequenceLibrary[sequenceIndex][GSGetActiveSequenceVersion(currentSequence)].icon
  else
      return iconid
  end
end

function GSSE:lines(tab, str)
  local function helper(line)
    table.insert(tab, line)
    return ""
  end
  helper((str:gsub("(.-)\r?\n", helper)))
  GST = t
end
