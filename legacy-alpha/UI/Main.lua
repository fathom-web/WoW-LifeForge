local LF=_G.LifeForge
local W,H=680,480
local frame, content, heading, status, edit
local tabs={"overview","chronicle","stats","vault","goals","settings"}
local active="overview"
local scope="character"
local function text(parent,value,x,y,width,height,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 f:SetPoint("TOPLEFT",x,y);f:SetSize(width,height);f:SetJustifyH("LEFT");f:SetJustifyV("TOP");f:SetText(value or "")
 if color then f:SetTextColor(unpack(color)) end
 return f
end
local function button(parent,value,x,y,width,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(width,25);b:SetPoint("TOPLEFT",x,y);b:SetText(value);b:SetScript("OnClick",fn)
 return b
end
local function clear()
 if not content then return end
 for _,child in ipairs({content:GetChildren()}) do child:Hide();child:SetParent(nil) end
 for _,region in ipairs({content:GetRegions()}) do region:Hide() end
end
local function line(value,y,color)
 return text(content,value,10,y,600,35,12,color)
end
local function fmtTime(seconds)
 seconds=math.floor(seconds or 0);return string.format("%dh %02dm",math.floor(seconds/3600),math.floor(seconds%3600/60))
end
local function getEvents()
 local e={}; local c=LF.char
 for _,item in ipairs(c.events or {}) do e[#e+1]=item end
 table.sort(e,function(a,b) return (a.id or 0)>(b.id or 0) end)
 return e
end
function LF:Refresh()
 if not frame or not frame:IsShown() or not self.char then return end
 clear()
 heading:SetText("LifeForge  |  "..active:upper().."  |  "..self.char.name)
 local c=self.char
 if active=="overview" then
  local totals=self:Totals(scope)
  line("YOUR LEGACY — "..scope:upper(),-8,{0.86,0.67,0.39})
  line("Characters: "..totals.characters.."      Tracked: "..fmtTime(totals.active).."      Sessions: "..totals.sessions,-42)
  line("Level: "..c.level.."      Gold: "..string.format("%.2f",(c.gold or 0)/10000).." g      Zone: "..(c.zone or "Unknown"),-75)
  line("Recorded memories: "..totals.events.."     Notes: "..totals.notes.."     Zones: "..totals.zones,-108)
  button(content,"Character",10,-150,100,function() scope="character";LF:Refresh() end)
  button(content,"Realm",120,-150,100,function() scope="realm";LF:Refresh() end)
  button(content,"Account",230,-150,100,function() scope="account";LF:Refresh() end)
  line("THE LATEST CHAPTER",-198,{0.86,0.67,0.39})
  line(self:Chronicle(),-230)
 elseif active=="stats" then
  local s=c.stats
  line("Active: "..fmtTime(s.active).."     AFK: "..fmtTime(s.afk),-8)
  line("Sessions: "..(s.sessions or 0).."     Level gains: "..(s.levelUps or 0),-45)
  line("Gold change since install: "..string.format("%.2f",(s.goldDelta or 0)/10000).." g",-82)
  local y=-120
  local zones={}
  for z,t in pairs(c.zones) do table.insert(zones,{z=z,s=t.seconds or 0}) end
  table.sort(zones,function(a,b)return a.s>b.s end)
  for i=1,math.min(#zones,5) do line(zones[i].z.." — "..fmtTime(zones[i].s),y);y=y-32 end
 elseif active=="chronicle" then
  line("THE CHRONICLE",-8,{0.86,0.67,0.39})
  local events=getEvents()
  for i=1,math.min(8,#events) do
   local e=events[i];line(date("%d %b %Y",e.at).."   "..e.title,-42-(i-1)*35)
  end
 elseif active=="vault" then
  line("YOUR MEMORIES",-8,{0.86,0.67,0.39})
  button(content,"New Memory",10,-44,140,function()
   StaticPopupDialogs["LIFEFORGE_NEW_MEMORY"]={text="Memory title:",button1="Save",button2="Cancel",hasEditBox=true,OnAccept=function(self) LF:AddNote(self.editBox:GetText(),"") end,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
   StaticPopup_Show("LIFEFORGE_NEW_MEMORY")
  end)
  for i=math.max(1,#c.notes-6),#c.notes do
   local n=c.notes[i]; if n then line((n.favorite and "* " or "")..n.title,-90-(i-math.max(1,#c.notes-6))*35) end
  end
  line("Tip: use the memory editor in a later alpha build for longer notes.",-345,{0.7,0.7,0.7})
 elseif active=="goals" then
  line("LEGACY GOALS",-8,{0.86,0.67,0.39})
  local y=-48
  for _,g in ipairs(self.goalPresets) do
   local progress=c.goals[g.id]
   if progress then line((progress.completed and "[DONE] " or "[ ] ")..g.title.." — "..math.min(self:GoalProgress(c,progress),progress.target).." / "..progress.target,y);y=y-45 end
  end
 elseif active=="settings" then
  line("SETTINGS & DATA HEALTH",-8,{0.86,0.67,0.39})
  local function toggle(title,y,get,set)
   button(content,title..": "..(get() and "ON" or "OFF"),10,y,250,function()set(not get());LF:Refresh() end)
  end
  toggle("Tracking",-42,function()return LF.db.settings.tracking end,function(v)LF.db.settings.tracking=v end)
  for i,kind in ipairs({"special","levels","zones","goals"}) do
   toggle("Notify: "..kind,-80-i*35,function()return LF.db.settings.notifications[kind] end,function(v)LF.db.settings.notifications[kind]=v end)
  end
  button(content,"Backup / Restore",10,-281,180,function() LF:ShowBackup() end)
  line("Database schema: "..LF.db.schema.."   Characters: "..#LF:GetKeys("account"),-325)
 end
 status:SetText("Novyx Forge  •  Local data only  •  "..self.version)
end
function LF:BuildUI()
 if frame then return end
 frame=CreateFrame("Frame","LifeForgeMainFrame",UIParent,"BackdropTemplate")
 frame:SetSize(W,H);frame:SetPoint("CENTER");frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton");frame:SetScript("OnDragStart",frame.StartMoving);frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
 frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=12,right=12,top=12,bottom=12}})
 frame:Hide()
 heading=text(frame,"LifeForge",24,-19,575,28,16,{0.86,0.67,0.39})
 button(frame,"X",W-50,-18,26,function()frame:Hide()end)
 for i,tab in ipairs(tabs) do
  button(frame,tab:sub(1,1):upper()..tab:sub(2),15+(i-1)*108,-57,102,function()active=tab;LF:Refresh()end)
 end
 content=CreateFrame("Frame",nil,frame);content:SetPoint("TOPLEFT",24,-104);content:SetSize(625,335)
 status=text(frame,"",24,-450,600,20,11,{0.7,0.6,0.48})
 self:Refresh()
end
function LF:Show(tab)
 if not frame then return end
 if tab and tab~="" then
  local matched=false;for _,t in ipairs(tabs) do if tab==t or (tab=="statistics" and t=="stats") then active=t;matched=true;break end end
  if not matched then active="overview" end
 end
 if frame:IsShown() and (not tab or tab=="") then frame:Hide() else frame:Show();self:Refresh() end
end
function LF:ShowBackup()
 if not self.db then return end
 if not self.backupFrame then
  local f=CreateFrame("Frame","LifeForgeBackupFrame",UIParent,"BackdropTemplate")
  f:SetSize(680,390);f:SetPoint("CENTER",0,60);f:SetFrameStrata("DIALOG")
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=12,right=12,top=12,bottom=12}})
  text(f,"BACKUP & RESTORE — full local database",20,-17,610,25)
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",20,-56);scroll:SetSize(613,245)
  local field=CreateFrame("EditBox",nil,scroll)
  field:SetMultiLine(true);field:SetAutoFocus(false);field:SetFontObject(ChatFontNormal);field:SetWidth(595);field:SetHeight(240);field:SetMaxLetters(0)
  scroll:SetScrollChild(field);f.field=field
  local message=text(f,"Export: copy all text. Import: paste a full LF1 backup, then select Restore.",20,-315,625,30)
  button(f,"Generate Export",20,-348,160,function()
    local ok,data=pcall(function() return LF:Export() end)
    if ok then field:SetText(data);field:HighlightText();field:SetFocus();message:SetText("Select all and copy. Large exports may exceed the edit box limits.") else message:SetText("Export failed: "..tostring(data)) end
  end)
  button(f,"Restore Import",190,-348,160,function()
    StaticPopupDialogs["LIFEFORGE_IMPORT_CONFIRM"]={text="Replace ALL local LifeForge data with the pasted backup?",button1="Replace",button2="Cancel",OnAccept=function()
     local ok,msg=LF:Import(field:GetText());message:SetText(msg)
    end,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    StaticPopup_Show("LIFEFORGE_IMPORT_CONFIRM")
  end)
  button(f,"Close",525,-348,110,function()f:Hide()end)
  self.backupFrame=f
 end
 self.backupFrame:Show()
end
