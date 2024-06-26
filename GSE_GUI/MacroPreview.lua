local GSE = GSE

local Statics = GSE.Static

local L = GSE.L

local AceGUI = LibStub("AceGUI-3.0")

if GSE.isEmpty(GSEOptions.editorWidth) then
  GSEOptions.editorWidth = 700
end
if GSE.isEmpty(GSEOptions.menuWidth) then
  GSEOptions.menuWidth = 700
end

local PreviewFrame = AceGUI:Create("Frame")
PreviewFrame.frame:SetFrameStrata("MEDIUM")
GSE.MacroPreviewFrame = PreviewFrame

PreviewFrame:SetTitle(L["Compiled Template"])
PreviewFrame:SetCallback(
  "OnClose",
  function(widget)
    PreviewFrame:Hide()
  end
)
PreviewFrame:SetLayout("List")
PreviewFrame.frame:SetClampRectInsets(-10, -10, -10, -10)
PreviewFrame:SetWidth(290)
PreviewFrame:SetHeight(700)
PreviewFrame:Hide()

local PreviewLabel = AceGUI:Create("MultiLineEditBox")
PreviewLabel:SetWidth(270)
PreviewLabel:SetNumLines(40)
PreviewLabel:DisableButton(true)

PreviewFrame.PreviewLabel = PreviewLabel
PreviewFrame:AddChild(PreviewLabel)

IndentationLib.enable(PreviewLabel.editBox, Statics.IndentationColorTable, 4)

PreviewFrame.frame:SetScript(
  "OnSizeChanged",
  function(self, width, height)
    PreviewLabel:SetWidth(width - 20)
  end
)

function GSE.GUIShowCompiledMacroGui(spelllist, title)
  PreviewFrame.text = IndentationLib.encode(GSE.Dump(spelllist))

  local count = #spelllist
  PreviewLabel:SetLabel(L["Compiled"] .. " " .. count .. " " .. L["Actions"])
  if GSE.GUIEditFrame:IsVisible() then
    local point, relativeTo, relativePoint, xOfs, yOfs = GSE.GUIEditFrame:GetPoint()
    PreviewFrame:ClearAllPoints()
    PreviewFrame:SetPoint("TOPLEFT", GSE.GUIEditFrame.frame, GSE.GUIEditFrame.Width + 10, 0)
  end

  if not GSE.isEmpty(spelllist) then
    PreviewLabel:SetText(PreviewFrame.text)
  end
  -- PreviewLabel:SetCallback(
  --   "OnTextChanged",
  --   function()
  --     PreviewLabel:SetText(PreviewFrame.text)
  --   end
  -- )
  PreviewFrame:SetStatusText(title)
  PreviewFrame:Show()
end
