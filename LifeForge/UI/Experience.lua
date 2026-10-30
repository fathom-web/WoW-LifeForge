-- Build 4: native WoW frame visualizations.  No external webview or fake world-map coordinates.
local LF=_G.LifeForge
local gold={.90,.72,.41};local pale={.94,.88,.74};local dim={.64,.62,.58}
local function text(parent,x,y,w,h,value,large)
  local f=parent:CreateFontString(nil,'OVERLAY',large and 'GameFontNormal' or 'GameFontHighlightSmall')
  f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetSize(w,h)
  f:SetText(value or '');f:SetTextColor(pale[1],pale[2],pale[3])
  f:SetJustifyH('LEFT');f:SetJustifyV('MIDDLE');return f
end
local function backdrop(parent,x,y,w,h,r,g,b)
  local f=CreateFrame('Frame',nil,parent);f:SetSize(w,h);f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local tex=f:CreateTexture(nil,'BACKGROUND');tex:SetAllPoints(f)
  tex:SetColorTexture(r or .16,g or .14,b or .12,.94);return f,tex
end
local function control(parent,x,y,w,h,value,fn)
  local b=CreateFrame('Button',nil,parent);b:SetSize(w,h);b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
  local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(b);bg:SetColorTexture(.21,.17,.12,.98)
  b.caption=text(b,8,-2,w-12,h-3,value,false)
  b:SetScript('OnClick',fn)
  b:SetScript('OnEnter',function()bg:SetColorTexture(.32,.24,.14,1)end)
  b:SetScript('OnLeave',function()bg:SetColorTexture(.21,.17,.12,.98)end)
  return b
end
local function fmt(seconds)
  return LF.ViewFormatTime and LF.ViewFormatTime(seconds) or (tostring(math.floor((seconds or 0)/60))..'m')
end
local function clip(s,len)
  s=tostring(s or ''):gsub('[\r\n]+',' ')
  if #s>len then return s:sub(1,len-3)..'...' end
  return s
end
function LF:BuildExperienceUI(parent,selectRow)
  if self.experienceFrame then return self.experienceFrame end
  local root=CreateFrame('Frame',nil,parent)
  root:SetSize(680,285);root:SetPoint('TOPLEFT',parent,'TOPLEFT',225,-297)
  local frames={};local navigation={calendarShift=0,wrappedIndex=1,museumPage=1,atlasPage=1,selectedDay=nil}
  local function frame(name)
    local f=CreateFrame('Frame',nil,root);f:SetAllPoints(root);f:Hide();frames[name]=f;return f
  end
  local cal=frame('calendar')
  local calCaption=text(cal,13,-2,295,25,'',true)
  control(cal,410,-1,102,24,'< MONTH',function()navigation.calendarShift=navigation.calendarShift-1;root:Render()end)
  control(cal,523,-1,102,24,'MONTH >',function()navigation.calendarShift=navigation.calendarShift+1;root:Render()end)
  for i,day in ipairs({'SUN','MON','TUE','WED','THU','FRI','SAT'}) do
    local t=text(cal,12+(i-1)*94,-28,86,18,day,false);t:SetTextColor(gold[1],gold[2],gold[3])
  end
  local calCells={}
  for i=1,42 do
    local col=(i-1)%7;local row=math.floor((i-1)/7)
    local b=control(cal,10+col*94,-49-row*32,88,29,'',function(self)
      if self.key then navigation.selectedDay=self.key;root:Render() end
    end)
    b.caption:SetWidth(78)
    local marker=b:CreateTexture(nil,'ARTWORK');marker:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',3,3)
    marker:SetSize(3,20);marker:SetColorTexture(.6,.45,.22,1)
    b.marker=marker;calCells[i]=b
  end
  local calInfo=text(cal,12,-248,645,24,'',false)
  local fp=frame('footprint')
  local fpHeading=text(fp,10,-1,385,30,LF:L('atlasHeading')..'  |  TRACKED PLACES',true)
  control(fp,418,-1,107,24,LF:L('prevZones'),function()navigation.atlasPage=math.max(1,navigation.atlasPage-1);root:Render()end)
  control(fp,535,-1,111,24,LF:L('nextZones'),function()navigation.atlasPage=navigation.atlasPage+1;root:Render()end)
  local fpRows={}
  for i=1,8 do
    local y=-32-(i-1)*27
    local item=backdrop(fp,9,y,652,25,.13,.12,.11)
    local zone=text(item,10,-2,237,22,'')
    local barBg=backdrop(item,254,-8,245,9,.26,.22,.16)
    local bar=barBg:CreateTexture(nil,'ARTWORK');bar:SetPoint('TOPLEFT',barBg,'TOPLEFT',0,0)
    bar:SetColorTexture(.75,.57,.31,.97);bar:SetHeight(9)
    local value=text(item,509,-2,131,22,'')
    fpRows[i]={holder=item,zone=zone,bar=bar,value=value}
  end
  local fpInfo=text(fp,9,-256,650,20,'',false)
  local museum=frame('museum')
  local museumTitle=text(museum,10,-1,430,27,'THE MEMORY MUSEUM  |  YOUR FAVORITES',true)
  control(museum,435,-1,102,24,'< PAGE',function()navigation.museumPage=math.max(1,navigation.museumPage-1);root:Render()end)
  control(museum,546,-1,102,24,'PAGE >',function()navigation.museumPage=navigation.museumPage+1;root:Render()end)
  local museumCards={}
  for i=1,6 do
    local x=8+(i-1)%3*222;local y=-34-math.floor((i-1)/3)*111
    local b=control(museum,x,y,214,104,'',function(self)
      if self.exhibit then root:ShowExhibit(self.exhibit) end
    end)
    b.caption:SetText('')
    local typeText=text(b,9,-5,188,16,'',false);typeText:SetTextColor(gold[1],gold[2],gold[3])
    local name=text(b,9,-25,192,33,'',true)
    local desc=text(b,9,-60,192,37,'',false)
    museumCards[i]={frame=b,kind=typeText,title=name,detail=desc}
  end
  local museumInfo=text(museum,10,-263,655,21,'',false)
  local museumDetail=backdrop(museum,35,-31,600,223,.075,.071,.067)
  museumDetail:SetFrameLevel((museum:GetFrameLevel() or 0)+6)
  museumDetail.title=text(museumDetail,20,-14,550,34,'',true)
  museumDetail.source=text(museumDetail,20,-55,550,22,'',false)
  museumDetail.body=text(museumDetail,20,-86,550,81,'',false)
  museumDetail.body:SetJustifyV('TOP')
  museumDetail.remove=control(museumDetail,18,-177,190,26,'REMOVE FAVORITE',function()
    local item=museumDetail.item
    if item and item.characterKey==LF.key and not LF.runtime.readOnly and not LF.runtime.restorePending then
      if item.kind=='note' then LF:FavoriteNote(item.id,false)
      else
        for _,ev in ipairs(LF.char.events or {}) do
          if ev.id==item.id then ev.favorite=false;break end
        end
      end
      museumDetail:Hide();root:Render()
    end
  end)
  control(museumDetail,458,-177,123,26,'CLOSE',function()museumDetail:Hide()end)
  museumDetail:Hide()
  function root:ShowExhibit(item)
    museumDetail.item=item
    museumDetail.title:SetText(clip(item.title,65))
    museumDetail.source:SetText(clip((item.character or '')..' · '..(item.zone or '')..' · '..(item.category or ''),90))
    museumDetail.body:SetText(clip(item.description,320))
    museumDetail.remove:SetShown(item.characterKey==LF.key and not LF.runtime.readOnly and not LF.runtime.restorePending)
    museumDetail:Show()
  end
  local wrapped=frame('wrapped')
  local wrapTitle=text(wrapped,12,-2,380,28,'',true)
  control(wrapped,424,-1,101,24,'< PERIOD',function()navigation.wrappedIndex=math.max(1,navigation.wrappedIndex-1);root:Render()end)
  control(wrapped,536,-1,111,24,'PERIOD >',function()navigation.wrappedIndex=navigation.wrappedIndex+1;root:Render()end)
  local tiles={}
  for i=1,4 do
    local x=10+(i-1)*165
    local cell=backdrop(wrapped,x,-37,157,76,.18,.15,.11)
    local k=text(cell,9,-5,140,21,'',false);k:SetTextColor(gold[1],gold[2],gold[3])
    local val=text(cell,9,-29,140,40,'',true)
    tiles[i]={key=k,value=val}
  end
  local highlights={}
  for i=1,3 do
    local e=backdrop(wrapped,10,-123-(i-1)*39,652,35,.13,.12,.11)
    highlights[i]=text(e,10,-3,626,30,'',false)
  end
  local wrappedInfo=text(wrapped,11,-246,651,42,'',false)
  root.state=navigation
  function root:Render(tab,scope,key)
    self.tab=tab or self.tab;self.scope=scope or self.scope;self.key=key or self.key
    local view=self.tab
    if view~='museum' then museumDetail:Hide() end
    for name,panel in pairs(frames) do panel:SetShown(name==view) end
    if view=='calendar' then
      local t=LF:Date('*t',LF:Now())
      local index=t.year*12+(t.month-1)+navigation.calendarShift
      local year=math.floor(index/12);local month=index%12+1
      -- Use explicit bounds rather than operating on user-controlled timestamps.
      if year<2000 or year>2100 then navigation.calendarShift=0;year=t.year;month=t.month end
      local data=LF:CalendarModel(year,month,self.scope,self.key)
      calCaption:SetText('LEGACY CALENDAR  ·  '..data.label)
      local selected=nil
      for i,cell in ipairs(data.cells) do
        local b=calCells[i];b.key=cell.key
        if cell.day then
          local star=(cell.events>0 or cell.memories>0) and '*' or ''
          b.caption:SetText(tostring(cell.day)..star)
          b.marker:SetShown(cell.intensity>0)
          if cell.intensity>0 then b.marker:SetColorTexture(.31+cell.intensity*.13,.21+cell.intensity*.09,.09,.96) end
          if b.key==navigation.selectedDay then selected=cell end
          b:Enable();b:SetAlpha(1)
        else b.caption:SetText('');b.marker:Hide();b:Disable();b:SetAlpha(.25) end
      end
      if selected then
        calInfo:SetText(selected.key..'  ·  '..fmt(selected.summary.active)..' active  ·  '..selected.events..' events  ·  '..selected.memories..' memories')
      else
        calInfo:SetText(tostring(data.totals.activeDays)..' active days  ·  '..fmt(data.totals.active)..' active  ·  '..data.totals.events..' events  ·  * marks a recorded moment')
      end
    elseif view=='footprint' then
      local data=LF:FootprintModel(self.scope,self.key)
      local pages=math.max(1,math.ceil(data.count/8))
      navigation.atlasPage=math.min(navigation.atlasPage,pages)
      fpHeading:SetText('ZONE ATLAS · '..data.count..' ZONES · '..navigation.atlasPage..'/'..pages)
      for i,item in ipairs(fpRows) do
        local z=data.zones[(navigation.atlasPage-1)*8+i]
        item.holder:SetShown(z~=nil)
        if z then
          item.zone:SetText(clip(z.name,34));item.bar:SetWidth(math.max(1,245*z.ratio))
          local observed=z.mapID and (' ID '..tostring(z.mapID)) or ''
          item.value:SetText(fmt(z.seconds)..observed)
        end
      end
      fpInfo:SetText(data.count>0 and LF:L('atlasInfo') or LF:L('atlasEmpty'))
    elseif view=='museum' then
      local data=LF:MuseumModel(self.scope,self.key)
      local pages=math.max(1,math.ceil(data.total/6))
      navigation.museumPage=math.min(navigation.museumPage,pages)
      museumTitle:SetText('THE MEMORY MUSEUM  ·  '..data.total..' EXHIBITS')
      for i,card in ipairs(museumCards) do
        local exhibit=data.exhibits[(navigation.museumPage-1)*6+i]
        card.frame:SetShown(exhibit~=nil);card.frame.exhibit=exhibit
        if exhibit then
          card.kind:SetText(string.upper(clip(exhibit.category or exhibit.kind,26)))
          card.title:SetText(clip(exhibit.title,34))
          card.detail:SetText(clip((exhibit.character or '')..' · '..(exhibit.zone or ''),51))
        end
      end
      museumInfo:SetText('PAGE '..navigation.museumPage..' / '..pages..'  ·  Favorite a timeline event or a memory to display it here.')
    elseif view=='wrapped' then
      local periods=LF:WrappedPeriods(self.scope,self.key)
      navigation.wrappedIndex=math.min(navigation.wrappedIndex,#periods)
      local data=LF:WrappedModel(periods[navigation.wrappedIndex],self.scope,self.key)
      wrapTitle:SetText('LEGACY WRAPPED  ·  '..data.periodLabel)
      local metrics={{'ACTIVE PLAY',fmt(data.active)},{'ADVENTURE DAYS',data.days},
        {'LEVELS GAINED',data.levels},{'STORY MOMENTS',data.events}}
      for i,entry in ipairs(metrics) do tiles[i].key:SetText(entry[1]);tiles[i].value:SetText(tostring(entry[2])) end
      highlights[1]:SetText(data.notes..' personal memories  ·  '..data.zones..' zone discoveries  ·  '..data.sessions..' sessions')
      if data.period=='all' then
        highlights[2]:SetText('Most time in: '..(data.topZone and (data.topZone.name..' ('..fmt(data.topZone.seconds)..')') or 'Not observed yet'))
        highlights[3]:SetText('Top grouped companion: '..(data.topCompanion and (data.topCompanion.name..' ('..fmt(data.topCompanion.seconds)..')') or 'Not observed yet'))
      else
        highlights[2]:SetText('AFK time this month: '..fmt(data.afk))
        highlights[3]:SetText('Monthly discoveries are based on first observed zone entry.')
      end
      wrappedInfo:SetText(data.disclaimer..'  ·  Use your game screenshot key to share; nothing is uploaded.')
    end
  end
  self.experienceFrame=root;root:Hide();return root
end