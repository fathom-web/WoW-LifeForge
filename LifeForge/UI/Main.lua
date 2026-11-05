-- LifeForge Build 2. Hybrid Chronicle UI: a fantasy book feel with modern accessible lists.
-- Frames are created once and reused; we do not allocate a new frame for every history item.
local LF=_G.LifeForge
local main, subtitle, sectionTitle, sectionSubtitle, footer, counter, searchBox
local model, listRows={},{}
local tabButtons, scopeButtons, metricLabels={}, {}, {}
local panels, controls = {}, {}
local currentTab='overview'
local scope='character'
local selectedKey, page, filterQuery=nil, 1, ''
local perPage=9
local richTabs={calendar=true,footprint=true,museum=true,wrapped=true}
local accent={0.90,0.72,0.41};local pale={0.94,0.88,0.74};local muted={0.67,0.67,0.65}
local tabs={
 {'overview','Overview'},{'characters','Characters'},{'chronicle','Chronicle'},
 {'timeline','Timeline'},{'statistics','Statistics'},{'companions','Companions'},
 {'goals','Goals'},{'vault','Legacy Vault'},{'museum','Museum'},
 {'footprint','Azeroth'},{'calendar','Calendar'},{'capsules','Time Capsules'},
 {'wrapped','Wrapped'},{'guild','Guild Legacy'},{'records','Records'},
 {'settings','Settings'},
}
local function surface(parent,w,h,x,y,r,g,b,a)
  local f=CreateFrame('Frame',nil,parent)
  f:SetSize(w,h);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local tex=f:CreateTexture(nil,'BACKGROUND')
  tex:SetAllPoints(f);tex:SetColorTexture(r,g,b,a or 1)
  return f
end
local function line(parent,w,x,y)
  return surface(parent,w,1,x,y,0.43,0.32,0.17,0.85)
end
local function label(parent,x,y,w,h,txt,large,color)
  local f=parent:CreateFontString(nil,'OVERLAY',large and 'GameFontNormalLarge' or 'GameFontHighlightSmall')
  f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetSize(w,h);f:SetJustifyH('LEFT')
  f:SetJustifyV('MIDDLE');f:SetText(txt or '')
  color=color or pale;f:SetTextColor(color[1],color[2],color[3]);return f
end
local function button(parent,x,y,w,h,txt,onClick)
  local f=CreateFrame('Button',nil,parent)
  f:SetSize(w,h);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local t=f:CreateTexture(nil,'BACKGROUND');t:SetAllPoints(f);t:SetColorTexture(.17,.15,.13,.94)
  local glow=f:CreateTexture(nil,'BORDER');glow:SetAllPoints(f);glow:SetColorTexture(.34,.26,.15,.4);glow:Hide()
  f.text=label(f,10,-1,w-15,h-2,txt,false,pale)
  f:SetScript('OnEnter',function() glow:Show() end)
  f:SetScript('OnLeave',function() glow:Hide() end)
  f:SetScript('OnClick',onClick)
  f.bg=t;f.highlight=glow
  return f
end
local function safeEdit(parent,x,y,w,h,multiline)
  local f=CreateFrame('EditBox',nil,parent,'InputBoxTemplate')
  f:SetSize(w,h);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  f:SetAutoFocus(false);f:SetMultiLine(multiline==true)
  if multiline then f:SetFontObject(_G.ChatFontNormal or _G.GameFontNormal);f:SetMaxLetters(3000) end
  f:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  return f
end
local function hideDialog() if controls.dialog then controls.dialog:Hide() end end
local function showDialog(title,fields,onSave,confirmLabel)
  local dlg=controls.dialog
  if not dlg then
    dlg=CreateFrame('Frame','LifeForgeEditorDialog',UIParent,'BackdropTemplate')
    dlg:SetSize(620,440);dlg:SetPoint('CENTER');dlg:SetFrameStrata('DIALOG')
    if type(_G.UISpecialFrames)=='table' then table.insert(_G.UISpecialFrames,'LifeForgeEditorDialog') end
    dlg:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',
      edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=24,
      insets={left=10,right=10,top=10,bottom=10}})
    dlg.header=label(dlg,30,-22,545,35,'',true,accent)
    dlg.message=label(dlg,30,-365,545,32,'',false,muted)
    dlg.inputA=safeEdit(dlg,42,-88,525,30,false)
    dlg.inputB=safeEdit(dlg,42,-162,525,100,true)
    dlg.inputC=safeEdit(dlg,42,-310,525,30,false)
    dlg.captionA=label(dlg,30,-58,550,20,'Title',false,pale)
    dlg.captionB=label(dlg,30,-135,550,20,'Description',false,pale)
    dlg.captionC=label(dlg,30,-281,550,20,'Unlock',false,pale)
    dlg.save=button(dlg,318,-400,160,28,'Save',function()
      local a=LF:Trim(dlg.inputA:GetText());local b=LF:Trim(dlg.inputB:GetText())
      local c=LF:Trim(dlg.inputC:GetText())
      local ok,msg=dlg.onSave(a,b,c)
      if ok then hideDialog();LF:Refresh() else dlg.message:SetText(tostring(msg or 'Unable to save')) end
    end)
    button(dlg,488,-400,98,28,'Cancel',hideDialog)
    dlg:SetMovable(true);dlg:EnableMouse(true)
    controls.dialog=dlg
  end
  dlg.onSave=onSave;dlg.header:SetText(title)
  dlg.captionA:SetText(fields.captionA or 'Title');dlg.captionB:SetText(fields.captionB or 'Description')
  dlg.inputA:SetText(fields.a or '');dlg.inputB:SetText(fields.b or '')
  dlg.inputC:SetText(fields.c or '')
  dlg.inputC:SetShown(fields.captionC~=nil);dlg.captionC:SetShown(fields.captionC~=nil)
  dlg.captionC:SetText(fields.captionC or '')
  dlg.message:SetText(fields.help or '')
  dlg.save.text:SetText(confirmLabel or 'Save Memory')
  dlg:Show();dlg.inputA:SetFocus()
end
local function alertConfirm(title,body,action)
  -- No destructive change before the user explicitly clicks Confirm.
  if not _G.StaticPopupDialogs or not _G.StaticPopup_Show then return end
  _G.StaticPopupDialogs.LIFEFORGE_UI_CONFIRM={
    text=title..'\n'..body,button1='Confirm',button2='Cancel',timeout=0,
    whileDead=true,hideOnEscape=true,preferredIndex=3,
    OnAccept=action,
  }
  _G.StaticPopup_Show('LIFEFORGE_UI_CONFIRM')
end
local function findEvent(id)
  local c=LF.char
  for _,e in ipairs(c and c.events or {}) do if e.id==id then return e end end
end
local function onRow(row)
  if not row then return end
  if row.kind=='character' then
    if row.mouseButton=='RightButton' then
      local c=LF.db.characters[row.id]
      if not c then return end
      alertConfirm(c.retired and 'Restore character?' or 'Archive character?',
        'This only changes the archive label. The character history remains intact.',function()
          local ok,reason=LF:SetRetired(row.id,not c.retired)
          if not ok then LF:Log(reason) end
          LF:Refresh()
        end)
    else selectedKey=row.id;page=1;LF:Refresh() end
    return
  end
  if row.kind=='backup' then LF:ShowBackup();return end
  if row.kind=='health' or row.kind=='compat' then
    LF:Command('diagnostics');return
  end
  if row.kind=='prune' then
    alertConfirm('Delete old raw session records?',
      'Only raw session/group details over 365 days old are removed. Aggregates, daily totals, stories, milestones and notes remain.',function()
        local ok,count=LF:PruneRawHistory(365,true)
        LF:Log(ok and ('Removed '..tostring(count)..' old raw records') or tostring(count))
        LF:Refresh()
      end)
    return
  end
  if row.kind=='scale' then
    if LF.runtime.readOnly or LF.runtime.restorePending then return end
    local current=LF.db.settings.scale or 1
    LF.db.settings.scale=current<.95 and 1 or current<1.10 and 1.15 or .85
    if main then main:SetScale(LF.db.settings.scale) end
    LF:Refresh();return
  end
  if row.kind=='minimap' then
    if LF.runtime.readOnly or LF.runtime.restorePending then return end
    LF.db.settings.minimap=not LF.db.settings.minimap
    if LF.db.settings.minimap then LF:BuildMinimap() end
    if LF.minimapButton then LF.minimapButton:SetShown(LF.db.settings.minimap) end
    LF:Refresh();return
  end
  if row.kind=='tracking' or row.kind=='social' then
    if LF.runtime.readOnly or LF.runtime.restorePending then return end
    local prop=row.kind=='tracking' and 'tracking' or 'socialTracking'
    LF.db.settings[prop]=not LF.db.settings[prop]
    if prop=='tracking' then
      if LF.db.settings.tracking then LF:StartSession() else LF:CloseSession() end
    else LF:UpdateGroup() end
    LF:Refresh();return
  end
  if row.kind=='notification' then
    if LF.runtime.readOnly or LF.runtime.restorePending then return end
    local setting=LF.db.settings.notifications
    setting[row.id]=not setting[row.id];LF:Refresh();return
  end
  if row.kind=='goal' and (selectedKey or LF.key)==LF.key then
    local g=LF.char.goals[row.id]
    if not g then return end
    if row.mouseButton=='RightButton' then
      alertConfirm('Remove goal?',g.title..' will be removed from your active goals.',function()
        local ok,reason=LF:DeleteGoal(row.id,true)
        if not ok then LF:Log(reason) end
        LF:Refresh()
      end)
    else
      showDialog('EDIT LEGACY GOAL',{captionA='Goal title',captionB='Target (number)',captionC='Kind: level, time (seconds), zones, notes, companions, gold (copper)',
        a=g.title,b=tostring(g.target),c=g.kind,
        help='Edit the kind or target to reset completion. Goals use actual recorded data.'},
        function(a,b,c) return LF:EditGoal(row.id,a,c,tonumber(b)) end,'Save Goal')
    end
    return
  end
  if row.kind=='note' and (selectedKey or LF.key)==LF.key then
    local n=LF:FindNote(row.id);if not n then return end
    if row.mouseButton=='RightButton' then
      if type(_G.IsShiftKeyDown)=='function' and _G.IsShiftKeyDown() then
        alertConfirm('Delete this memory?', 'This removes the note, not the separate timeline milestone.',function()
          local ok,reason=LF:DeleteNote(n.id,true)
          if not ok then LF:Log(reason) end
          LF:Refresh()
        end)
      else LF:FavoriteNote(n.id,not n.favorite);LF:Refresh() end
      return
    end
    showDialog('EDIT YOUR MEMORY',{a=n.title,b=n.body,c=n.category or 'Personal Memory',captionC='Category',
      help='Right-click to favorite; Shift + right-click to delete with confirmation.'},
      function(a,b,c) return LF:EditNoteFull(n.id,a,b,c) end,'Save Changes')
    return
  end
  if row.kind=='event' and (selectedKey or LF.key)==LF.key then
    local e=findEvent(row.id)
    if e and not LF.runtime.readOnly then e.favorite=not e.favorite;LF:Refresh() end
    return
  end
  if row.kind=='party' and (selectedKey or LF.key)==LF.key then
    local current=LF.char.parties[row.id]
    if not current then return end
    showDialog('NAME YOUR ADVENTURE PARTY',{a=current.name or '',b='',captionA='Party nickname',captionB='Optional note (not saved)',help='Names are local to your character.'},
      function(a) return LF:NameParty(row.id,a) end,'Save Party Name')
    return
  end
  if row.kind=='companion' then
    showDialog('COMPANION PRIVACY',{a=tostring(row.id),b='',captionA='Companion key',captionB='Leave blank',help='This erases observed social records and prevents future tracking of this player.'},
      function(a)
        if a~=row.id then return false,'Key must match the selected companion' end
        alertConfirm('Forget companion?', 'Remove all recorded observations of '..a..'?',function()
          LF:EraseCompanionEverywhere(a,true);LF:Refresh()
        end)
        return true
      end,'Forget Companion')
    return
  end
  if row.kind=='letter' then
    local c=LF.db.characters[selectedKey or LF.key]
    if not c then return end
    if row.mouseButton=='RightButton' and (selectedKey or LF.key)==LF.key then
      alertConfirm('Delete sealed letter?', 'A deleted letter cannot be recovered without a backup.',function()
        local ok,reason=LF:DeleteFutureLetter(row.id,true)
        if not ok then LF:Log(reason) end
        LF:Refresh()
      end)
      return
    end
    for _,letter in ipairs(c.letters or {}) do
      if letter.id==row.id and letter.opened then
        showDialog('A LETTER FROM YOUR PAST',{a=letter.title,b=letter.body,help='Read-only preview; closing does not change the letter.'},
          function()return false,'Letters cannot be edited after sealing.'end,'Sealed')
        return
      end
    end
  end
end
local function action()
  if LF.runtime.readOnly or LF.runtime.restorePending then LF:Log('Database locked');return end
  if selectedKey and selectedKey~=LF.key then LF:Log('Switch to the active character before creating a memory');return end
  if currentTab=='overview' or currentTab=='museum' then
    local ok,reason=LF:QuickBookmark()
    LF:Log(ok and 'Moment bookmarked in your Vault' or tostring(reason))
    LF:Refresh()
  elseif currentTab=='guild' then
    showDialog('SAVE A GUILD MEMORY',{captionA='Memory title',captionB='Description',captionC='Category',c='Guild Memory',
      help='Save a personal guild memory. Current guild is recorded if exposed by the game.'},
      function(a,b,c) return LF:AddNote(a,b,c) end,'Save Guild Memory')
  elseif currentTab=='capsules' then
    showDialog('LETTER TO YOUR FUTURE SELF',{captionA='Title',captionB='Letter text',captionC='Unlock trigger (level:60 | hours:100 | date:2027-01-01)',a='',b='',c='level:'..tostring((LF.char.level or 1)+10),help='Choose a FUTURE target. Hours means active tracked hours; date uses your local calendar.'},
      function(a,b,c)
        local ok,kind,target=LF:ParseLetterTrigger(c)
        if not ok then return false,kind end
        return LF:AddFutureLetter(a,b,kind,target)
      end,'Seal Letter')
  elseif currentTab=='goals' then
    showDialog('FORGE A NEW GOAL',{captionA='Goal title',captionB='Target (number)',captionC='Kind: level, time (seconds), zones, notes, companions, gold (copper)',
      a='',b='60',c='level',help='For time, enter seconds; for gold, enter copper (10000 = 1g).'},
      function(a,b,c) return LF:AddGoal(a,c,tonumber(b)) end,'Create Goal')
  else
    showDialog('SAVE A MEMORY',{captionA='Memory title',captionB='Short description',captionC='Category',c='Personal Memory',
      help='Date, zone, current character and observed party are stored locally.'},
      function(a,b,c)return LF:AddNote(a,b,c) end,'Save Memory')
  end
end
function LF:Refresh()
  if not main or not main:IsShown() or not self.char then return end
  model=self:BuildView(currentTab,scope,selectedKey,filterQuery)
  sectionTitle:SetText(model.title);sectionSubtitle:SetText(model.summary)
  for i,m in ipairs(metricLabels) do
    local metric=model.metrics[i]
    m.key:SetText(metric and tostring(metric[1]) or '')
    m.value:SetText(metric and tostring(metric[2]) or '')
  end
  local pages=math.max(1,math.ceil(#model.rows/perPage))
  page=math.min(page,pages)
  local rich=richTabs[currentTab]==true
  for i,f in ipairs(listRows) do
    local row=model.rows[(page-1)*perPage+i]
    if row and not rich then
      f.title:SetText(row.title);f.detail:SetText(row.detail)
      f.item=row;f:Show()
    else f.item=nil;f:Hide() end
  end
  if self.experienceFrame then
    self.experienceFrame:SetShown(rich)
    if rich then self.experienceFrame:Render(currentTab,scope,selectedKey or self.key) end
  end
  counter:SetShown(not rich)
  counter:SetText('PAGE '..page..' / '..pages..'   •   '..#model.rows..' ENTRIES')
  footer:SetText('LIFEFORGE '..self.version..'   •   '..self:L('storedLocally')..'   •   '..(self.runtime.readOnly and self:L('readOnly') or self:L('releaseNotice')))
  controls.prev:SetShown(not rich)
  controls.next:SetShown(not rich)
  controls.searchLabel:SetShown(model.filterable==true and not rich)
  searchBox:SetShown(model.filterable==true and not rich)
  controls.action:SetShown(model.action~=nil and not rich)
  controls.action.text:SetText(model.action=='goal' and '+ NEW GOAL' or model.action=='letter' and '+ SEAL LETTER' or
    model.action=='bookmark' and '+ BOOKMARK' or model.action=='guildmemory' and '+ GUILD MEMORY' or '+ SAVE MEMORY')
  for _,b in pairs(tabButtons) do b.text:SetText(b.tab==currentTab and '◆ '..b.caption or b.caption) end
  for _,b in pairs(scopeButtons) do b.text:SetText(b.scope==scope and '◆ '..b.caption or b.caption) end
  subtitle:SetText('Browsing: '..((self.db.characters[selectedKey or self.key] or self.char).name or '')..'   •   Realm: '..((self.db.characters[selectedKey or self.key] or self.char).realm or ''))
end
local function chooseTab(tab)
  currentTab=tab;page=1;filterQuery=''
  if LF.experienceFrame and LF.experienceFrame.state then
    LF.experienceFrame.state.selectedDay=nil
  end
  if tab=='characters' and scope=='character' then scope='realm' end
  if searchBox then searchBox:SetText('') end
  LF.db.settings.ui.selectedTab=tab
  LF:Refresh()
end
function LF:BuildUI()
  if main or type(_G.CreateFrame)~='function' then return end
  main=CreateFrame('Frame','LifeForgeMainFrame',UIParent,'BackdropTemplate')
  main:SetSize(940,645);main:SetPoint('CENTER');main:SetClampedToScreen(true)
  if type(_G.UISpecialFrames)=='table' then table.insert(_G.UISpecialFrames,'LifeForgeMainFrame') end
  main:SetScale(math.max(.85,math.min(1.15,tonumber(self.db.settings.scale) or 1)))
  main:SetMovable(true);main:EnableMouse(true);main:RegisterForDrag('LeftButton')
  main:SetScript('OnDragStart',function(self) if not LF:IsCombat() then self:StartMoving() end end)
  main:SetScript('OnDragStop',function(self)self:StopMovingOrSizing() end)
  main:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=24,
    insets={left=10,right=10,top=10,bottom=10}})
  surface(main,188,570,18,-60,.085,.082,.077,.96)
  line(main,893,23,-60)
  label(main,26,-14,410,38,'L I F E F O R G E',true,accent)
  label(main,435,-16,375,30,'YOUR CHARACTER · YOUR JOURNEY · YOUR LEGEND',false,pale)
  button(main,877,-15,35,30,'X',function()main:Hide()end)
  for i,item in ipairs(tabs) do
    local tab,text=item[1],item[2]
    local b=button(main,25,-72-(i-1)*31,173,28,text,function()chooseTab(tab)end)
    b.tab=tab;b.caption=text;tabButtons[#tabButtons+1]=b
  end
  label(main,28,-578,165,20,'BY NOVYX FORGE',false,accent)
  sectionTitle=label(main,225,-75,670,31,'',true,accent)
  sectionSubtitle=label(main,225,-112,670,36,'',false,pale)
  subtitle=label(main,225,-148,670,21,'',false,muted)
  for i=1,4 do
    local x=225+(i-1)*170
    local tile=surface(main,161,62,x,-184,.13,.12,.11,.98)
    metricLabels[i]={key=label(tile,10,-6,141,19,'',false,muted),value=label(tile,10,-26,141,29,'',true,accent)}
  end
  for i,cat in ipairs({{'character','Character'},{'realm','Realm'},{'account','Account'}}) do
    local b=button(main,225+(i-1)*107,-258,99,27,cat[2],function()
      scope=cat[1];LF.db.settings.ui.selectedScope=scope;page=1;LF:Refresh()
    end)
    b.scope=cat[1];b.caption=cat[2];scopeButtons[#scopeButtons+1]=b
  end
  controls.searchLabel=label(main,553,-261,74,24,'SEARCH',false,muted)
  searchBox=safeEdit(main,638,-260,254,26,false)
  searchBox:SetScript('OnTextChanged',function(self)
    local text=self:GetText() or ''
    if text~=filterQuery then filterQuery=text;page=1;LF:Refresh() end
  end)
  line(main,680,225,-294)
  for i=1,perPage do
    local b=button(main,225,-299-(i-1)*30,677,28,'',function(self,mouseButton)
      if self.item then self.item.mouseButton=mouseButton;onRow(self.item) end
    end)
    b:RegisterForClicks('LeftButtonUp','RightButtonUp')
    b.title=label(b,4,-2,245,25,'',false,pale)
    b.detail=label(b,256,-2,403,25,'',false,muted)
    b.text:Hide()
    listRows[i]=b
  end
  counter=label(main,448,-585,320,24,'',false,muted)
  controls.prev=button(main,225,-584,85,26,'< PREV',function()page=math.max(1,page-1);LF:Refresh()end)
  controls.next=button(main,321,-584,84,26,'NEXT >',function()page=page+1;LF:Refresh()end)
  controls.action=button(main,767,-584,136,26,'+ SAVE MEMORY',action)
  self:BuildExperienceUI(main,onRow)
  footer=label(main,225,-617,688,17,'',false,muted)
  currentTab=self.db.settings.ui.selectedTab or 'overview'
  scope=self.db.settings.ui.selectedScope or 'character'
  main:Hide()
  if self.db.settings.minimap then self:BuildMinimap() end
end
function LF:Show(tab)
  if not main then self:BuildUI() end
  if not main then self:Log('Game UI unavailable');return end
  if tab and tab~='' then
    if tab=='stats' then tab='statistics' end
    local exists=false
    for _,t in ipairs(tabs) do if t[1]==tab then exists=true end end
    if exists then currentTab=tab;page=1;filterQuery='';searchBox:SetText('') end
  end
  if not tab and main:IsShown() then main:Hide()
  else main:Show();self:Refresh() end
end
function LF:BuildMinimap()
  if self.minimapButton or not _G.Minimap then return end
  local m=CreateFrame('Button','LifeForgeMinimapButton',_G.Minimap)
  m:SetSize(29,29);m:SetPoint('TOPLEFT',_G.Minimap,'TOPLEFT',0,0)
  m:SetNormalTexture('Interface\\Icons\\INV_Misc_Book_09')
  m:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
  m:SetScript('OnClick',function()LF:Show()end)
  m:SetScript('OnEnter',function(self)
    if not _G.GameTooltip then return end
    GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine('LifeForge')
    GameTooltip:AddLine('Your Legacy in Azeroth • /lf',1,1,1);GameTooltip:Show()
  end)
  m:SetScript('OnLeave',function()if _G.GameTooltip then GameTooltip:Hide() end end)
  self.minimapButton=m
end