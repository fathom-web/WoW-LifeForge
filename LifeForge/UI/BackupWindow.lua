local LF = _G.LifeForge
local backupWindow, exportParts, exportIndex, importBatch
local GOLD={0.89,0.73,0.46}
local function makeText(parent,value,x,y,w,h,size,color)
  local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  f:SetPoint("TOPLEFT",x,y);f:SetSize(w,h)
  f:SetJustifyH("LEFT");f:SetJustifyV("TOP");f:SetText(value or "")
  if color then f:SetTextColor(color[1],color[2],color[3]) end
  return f
end
local function btn(parent,value,x,y,w,action)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,25);b:SetPoint("TOPLEFT",x,y);b:SetText(value)
  b:SetScript("OnClick",action);return b
end
local function makeEdit(parent)
  local scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",20,-92);scroll:SetSize(625,218)
  local edit=CreateFrame("EditBox",nil,scroll)
  edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(605);edit:SetHeight(210);edit:SetMaxLetters(0)
  scroll:SetScrollChild(edit)
  return edit
end
function LF:ShowBackup()
  if not backupWindow then
    local f=CreateFrame("Frame","LifeForgeBackupFrame",UIParent,"BackdropTemplate")
    f:SetSize(720,440);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
    if type(_G.UISpecialFrames)=="table" then table.insert(_G.UISpecialFrames,"LifeForgeBackupFrame") end
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,
      edgeSize=32,insets={left=12,right=12,top=12,bottom=12}})
    makeText(f,"BACKUP & RESTORE — life history is local to this installation",20,-18,650,40,12,GOLD)
    local note=makeText(f,"Copy each export part. Paste each import part and click Accept Part.",20,-56,650,30,11)
    local edit=makeEdit(f)
    importBatch=LF:NewImport()
    local function showPart()
      if not exportParts then note:SetText("No export generated");return end
      edit:SetText(exportParts[exportIndex]);edit:HighlightText();edit:SetFocus()
      note:SetText("Export part "..exportIndex.." of "..#exportParts.." — select and copy. Keep ALL parts.")
    end
    btn(f,"Generate Export",20,-326,125,function()
      local ok,parts=LF:BuildExport()
      if not ok then note:SetText("Export failed: "..tostring(parts));return end
      exportParts=parts;exportIndex=1;showPart()
    end)
    btn(f,"Previous",155,-326,100,function()
      if exportParts then exportIndex=math.max(1,exportIndex-1);showPart() end
    end)
    btn(f,"Next",265,-326,100,function()
      if exportParts then exportIndex=math.min(#exportParts,exportIndex+1);showPart() end
    end)
    btn(f,"Accept Part",375,-326,115,function()
      local ok,message=LF:AcceptPart(importBatch,LF:Trim(edit:GetText()))
      if ok then
        local accepted=0
        for _ in pairs(importBatch.pieces or {}) do accepted=accepted+1 end
        local total=importBatch.total or '?'
        note:SetText("Accepted "..accepted.." / "..tostring(total).." parts. "..tostring(message or ''))
        edit:SetText("")
      else note:SetText("Rejected: "..tostring(message)) end
    end)
    btn(f,"New Import",500,-326,110,function()
      importBatch=LF:NewImport();edit:SetText("");note:SetText("New import started. Paste part 1.")
    end)
    local function preview(mode)
      local ok,report=LF:PrepareImport(importBatch,mode)
      if not ok then note:SetText("Invalid import: "..tostring(report));return end
      note:SetText("READY: "..report.newCharacters.." new, "..report.existingCharacters.." existing. "..report.message)
      StaticPopupDialogs["LIFEFORGE_RESTORE_CONFIRM"]={
        text="Restore prepared backup as "..mode.."? Merge keeps local characters. Replacement overwrites all local data. Export a safety copy first. Reload immediately after restore.",
        button1="Confirm Restore",button2="Cancel",timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnAccept=function()
          local success,message=LF:CommitImport(importBatch,true)
          note:SetText(tostring(message))
          if success then LF:Log(message) end
        end
      }
      StaticPopup_Show("LIFEFORGE_RESTORE_CONFIRM")
    end
    btn(f,"Preview Merge",20,-367,150,function()preview("merge")end)
    btn(f,"Preview Replace",180,-367,150,function()preview("replace")end)
    btn(f,"Close",600,-367,90,function()f:Hide()end)
    backupWindow=f
  end
  backupWindow:Show()
end
