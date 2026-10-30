-- UI data is composed without accessing protected frames; the same view models can be
-- tested headlessly. Every datum is observed by LifeForge or clearly labelled.
local LF=_G.LifeForge
local function fmt(s)
  s=math.floor(tonumber(s) or 0)
  return string.format('%dh %02dm',math.floor(s/3600),math.floor(s%3600/60))
end
local function gold(copper) return string.format('%.1fg',(tonumber(copper) or 0)/10000) end
local function short(s,n)
  s=tostring(s or ''):gsub('[\r\n]+',' ')
  return s:sub(1,n or 160)
end
local function add(v,title,detail,kind,id)
  v.rows[#v.rows+1]={title=short(title,90),detail=short(detail,220),kind=kind,id=id}
end
local function sortedKeys(map,key,descending)
  local list={}
  for k,value in pairs(map or {}) do list[#list+1]={key=k,value=value} end
  table.sort(list,function(a,b)
    local av=key and (a.value[key] or 0) or a.key
    local bv=key and (b.value[key] or 0) or b.key
    if av==bv then return tostring(a.key)<tostring(b.key) end
    if descending then return av>bv end
    return av<bv
  end)
  return list
end
function LF:BuildView(tab,scope,selectedKey,query)
  local selected=self.db and self.db.characters and self.db.characters[selectedKey or self.key]
  selected=selected or self.char
  local c=selected
  local v={title='',summary='',metrics={},rows={},filterable=false,action=nil}
  if not c then v.title='WELCOME TO LIFEFORGE';v.summary='Character data will appear after login.';return v end
  local timeFmt=function(stamp) return self:Date('%d %b %Y',stamp or self:Now()) end
  local totals=self:Totals(scope, selectedKey or self.key)
  local q=self:Trim(query or ''):lower()
  local function matches(...) if q=='' then return true end
    for i=1,select('#',...) do
      local s=select(i,...)
      if tostring(s or ''):lower():find(q,1,true) then return true end
    end
    return false
  end
  local key=selectedKey or self.key
  if tab=='overview' then
    v.title='YOUR CHARACTER. YOUR LEGEND.'
    v.summary=(c.name or 'Unknown')..'  •  '..(c.race or 'Unknown')..' '..(c.class or '')..'  •  '..(c.realm or '')
    v.metrics={{'LEVEL',c.level or 1},{'TRACKED TIME',fmt(totals.active)},{'MEMORIES',totals.notes},{'CHARACTERS',totals.characters}}
    add(v,'THE LATEST CHAPTER',self:Chronicle(c),'chapter')
    for i=#c.events,math.max(1,#c.events-6),-1 do
      local e=c.events[i];add(v,e.title,timeFmt(e.at)..'  ·  '..(e.zone or ''),'event',e.id)
    end
    v.action='bookmark'
  elseif tab=='characters' then
    v.title='THE FAMILY LEGACY';v.summary='Browse registered characters; right-click to archive/restore without deleting their history.'
    local family=self:FamilyLegacy(scope,selectedKey or self.key)
    v.metrics={{'REGISTERED',family.characters},{'TRACKED TIME',fmt(family.active)},{'REALMS',family.realmCount},{'ARCHIVED',family.archived}}
    if family.first then
      add(v,'THE FIRST CHAPTER',family.first.name..' of '..family.first.realm..'  ·  First tracked '..timeFmt(family.first.created),'fact')
    end
    if family.mostPlayed then
      add(v,'YOUR MOST PLAYED HERO',family.mostPlayed.name..'  ·  '..fmt(family.mostPlayed.active)..' tracked','fact')
    end
    add(v,'THE FAMILY TOTAL',tostring(family.combinedLevels)..' combined character levels  ·  '..tostring(family.memories)..' saved memories','fact')
    for _,k in ipairs(self:GetKeys(scope,selectedKey or self.key)) do
      local d=self.db.characters[k]
      add(v,d.name..(d.retired and '  [Archived]' or ''),d.realm..'  ·  '..(d.class or 'Class unknown')..'  ·  Level '..tostring(d.level)..'  ·  '..fmt(d.stats.active),'character',k)
    end
  elseif tab=='timeline' or tab=='chronicle' then
    v.title=tab=='chronicle' and 'THE CHRONICLE' or 'ADVENTURE TIMELINE'
    v.summary=tab=='chronicle' and self:Chronicle(c) or 'Recorded milestones since LifeForge was first installed.'
    local favorites=0
    for _,e in ipairs(c.events) do if e.favorite then favorites=favorites+1 end end
    v.metrics={{'EVENTS',#c.events},{'FAVORITES',favorites},{'FIRST SEEN',timeFmt(c.created)},{'LEVEL',c.level}}
    v.filterable=true
    if tab=='chronicle' then
      local chapters=self:ChronicleChapters(c)
      v.metrics={{'CHAPTERS',#chapters},{'EVENTS',#c.events},{'FIRST SEEN',timeFmt(c.created)},{'LEVEL',c.level}}
      for i=#chapters,1,-1 do
        local ch=chapters[i]
        if matches(ch.title,ch.summary) then
          add(v,ch.title,ch.summary,'chapter',ch.month)
        end
      end
    else
      for i=#c.events,1,-1 do
        local e=c.events[i]
        if matches(e.title,e.kind,e.zone,e.description) then
          add(v,(e.favorite and '★  ' or '')..e.title,timeFmt(e.at)..'  ·  '..(e.zone or 'Unknown')..'  ·  '..short(e.description,110),'event',e.id)
        end
      end
    end
  elseif tab=='statistics' then
    v.title='LIFE STATISTICS';v.summary='Active and AFK time tracked locally since installation.'
    v.metrics={{'ACTIVE',fmt(c.stats.active)},{'AFK',fmt(c.stats.afk)},{'SESSIONS',c.stats.sessions},{'GOLD',gold(c.gold)}}
    local session=self:SessionIntelligence(c)
    add(v,'SESSION INTELLIGENCE',tostring(session.completed)..' completed sessions  ·  Average active '..fmt(session.meanActive),'fact')
    add(v,'CURRENT SESSION',fmt(session.currentActive)..' active  ·  '..fmt(session.currentAFK)..' AFK (observed)','fact')
    add(v,'LEVEL PROGRESSION',tostring(c.stats.levelUps)..' level-ups recorded since installation','fact')
    add(v,'GOLD MOVEMENT','Earned '..gold(c.stats.goldEarned)..'  ·  Spent '..gold(c.stats.goldSpent),'fact')
    for _,entry in ipairs(sortedKeys(c.zones,'seconds',true)) do
      add(v,entry.key,fmt(entry.value.seconds or 0)..' in this zone','zone',entry.key)
    end
  elseif tab=='companions' then
    v.title='ADVENTURE COMPANIONS';v.summary='Observed party/raid overlap; not proof of friendship or shared activity.'
    v.metrics={{'COMPANIONS',self:Count(c.companions)},{'PARTIES',self:Count(c.parties)},{'PRIVACY','LOCAL'},{'SOCIAL',self.db.settings.socialTracking and 'ON' or 'OFF'}}
    for _,entry in ipairs(sortedKeys(c.companions,'seconds',true)) do
      add(v,entry.key,fmt(entry.value.seconds)..' observed together  ·  '..tostring(entry.value.groupSessions or 0)..' group encounters  ·  bond tier '..tostring(entry.value.bondTier or 0),'companion',entry.key)
    end
    for _,entry in ipairs(sortedKeys(c.parties,'seconds',true)) do
      local p=entry.value
      add(v,'PARTY: '..(p.name~='' and p.name or tostring(#p.members+1)..'-player group'),
        fmt(p.seconds)..' observed  ·  '..tostring(p.sessions)..' sessions  ·  Click to name','party',entry.key)
    end
  elseif tab=='goals' then
    v.title='LEGACY GOALS';v.summary='Write your next chapter. Set personal milestones and follow their progress.'
    local done=0
    for _,g in pairs(c.goals) do if g.completed then done=done+1 end end
    v.metrics={{'GOALS',self:Count(c.goals)},{'COMPLETE',done},{'LEVEL',c.level},{'PROGRESS','LIVE'}}
    for _,entry in ipairs(sortedKeys(c.goals)) do
      local g=entry.value
      if not g.hidden then
        add(v,(g.completed and '✓  ' or '◇  ')..g.title,
          tostring(math.floor(math.min(self:GoalProgress(c,g),g.target)))..' / '..tostring(g.target)..'  ·  '..tostring(g.kind)..'  ·  Click to edit / right-click to remove','goal',entry.key)
      end
    end
    v.action='goal'
  elseif tab=='vault' or tab=='museum' then
    v.title=tab=='museum' and 'THE MEMORY MUSEUM' or 'THE LEGACY VAULT'
    v.summary='Your own notes and memories. Nothing is uploaded.'
    local favorites=0
    for _,n in ipairs(c.notes) do if n.favorite then favorites=favorites+1 end end
    v.metrics={{'NOTES',#c.notes},{'LETTERS',#c.letters},{'FAVORITES',favorites},{'SAVED','LOCAL'}}
    v.filterable=true
    for i=#c.notes,1,-1 do
      local n=c.notes[i]
      if (tab~='museum' or n.favorite) and matches(n.title,n.body,n.category,n.zone) then
        add(v,(n.favorite and '★  ' or '')..n.title,timeFmt(n.at)..'  ·  '..(n.zone or '')..'  ·  '..short(n.body,130),'note',n.id)
      end
    end
    if tab=='vault' then
      for i=#c.letters,1,-1 do
        local l=c.letters[i]
        if matches(l.title,l.opened and l.body or '') then
          add(v,(l.opened and '✉  ' or '🔒  ')..l.title,l.opened and ('Unsealed '..timeFmt(l.opened)) or ('Sealed until '..self:LetterTriggerLabel(l)),'letter',l.id)
        end
      end
    end
    v.action=tab=='vault' and 'note' or 'bookmark'
  elseif tab=='footprint' then
    v.title='YOUR AZEROTH FOOTPRINT';v.summary='Your visited zones, based on activity recorded by this addon.'
    v.metrics={{'ZONES',self:Count(c.zones)},{'TRACKED',fmt(c.stats.active)},{'LEVEL',c.level},{'MAP','LIST VIEW'}}
    for _,entry in ipairs(sortedKeys(c.zones,'seconds',true)) do
      add(v,entry.key,'Time observed '..fmt(entry.value.seconds or 0)..'  ·  First visited '..timeFmt(entry.value.firstSeen),'zone',entry.key)
    end
  elseif tab=='calendar' then
    v.title='LEGACY CALENDAR';v.summary='Daily activity summaries, starting when LifeForge began tracking.'
    v.metrics={{'ACTIVE',fmt(c.stats.active)},{'DAYS',self:Count(c.daily)},{'SESSIONS',c.stats.sessions},{'MODE','DAILY'}}
    for _,entry in ipairs(sortedKeys(c.daily,nil,true)) do
      local d=entry.value
      add(v,entry.key,fmt(d.active)..' active  ·  '..fmt(d.afk)..' AFK  ·  '..tostring(d.sessions or 0)..' sessions','day',entry.key)
    end
  elseif tab=='capsules' then
    v.title='TIME CAPSULES';v.summary='A monthly record of how your character has changed.'
    v.metrics={{'CAPSULES',self:Count(c.snapshots)},{'LEVEL',c.level},{'GOLD',gold(c.gold)},{'MEMORIES',#c.notes}}
    for _,entry in ipairs(sortedKeys(c.snapshots,nil,true)) do
      local s=entry.value
      local difference=self:ThenVsNow(c,entry.key)
      add(v,entry.key,'Then: level '..tostring(s.level)..', '..fmt(s.active)..'  ·  Since: '..(difference.level>=0 and '+' or '')..tostring(difference.level)..' levels, +'..fmt(difference.active),'capsule',entry.key)
    end
    for _,letter in ipairs(c.letters) do
      add(v,letter.opened and ('UNSEALED: '..letter.title) or ('SEALED: '..letter.title),
        letter.opened and 'Letter delivered from your past' or ('Unlock at '..self:LetterTriggerLabel(letter)), 'letter',letter.id)
    end
    v.action='letter'
  elseif tab=='wrapped' then
    v.title='LEGACY WRAPPED';v.summary='Your adventure so far. All values are recorded; no historical guesswork.'
    v.metrics={{'PLAYED',fmt(c.stats.active)},{'ZONES',self:Count(c.zones)},{'MOMENTS',#c.events},{'BONDS',self:Count(c.companions)}}
    add(v,'YOUR STORY SO FAR',self:Chronicle(c),'chapter')
    add(v,'FIRST TRACKED','First recorded on '..timeFmt(c.created),'fact')
    add(v,'TOTAL PLAYTIME',fmt(c.stats.active)..' active time since installation','fact')
    add(v,'MEMORABLE MOMENTS',tostring(#c.notes)..' written memories and '..tostring(#c.events)..' recorded events','fact')
    local top=sortedKeys(c.companions,'seconds',true)[1]
    if top then add(v,'MOST TRAVELED WITH',top.key..'  ·  '..fmt(top.value.seconds)..' observed in a group','fact') end
    add(v,'GUILD HISTORY',tostring(#c.guildHistory)..' observed guild membership changes','fact')
    add(v,'SHARE YOUR LEGACY','Take a screenshot in-game. LifeForge never uploads your data.','fact')
  elseif tab=='guild' then
    v.title='GUILD LEGACY';v.summary='Guild membership observed while LifeForge was installed. Older history is unknown.'
    v.metrics={{'CURRENT',c.guild~='' and (c.guild or 'Unknown') or 'No guild'},{'CHANGES',#c.guildHistory},{'MEMORIES',#c.notes},{'PRIVACY','LOCAL'}}
    for i=#c.guildHistory,1,-1 do
      local item=c.guildHistory[i]
      add(v,item.kind=='joined' and 'Guild joined (observed)' or 'Guild left (observed)',item.guild..'  ·  '..timeFmt(item.at),'guild',i)
    end
    for i=#c.notes,1,-1 do
      local n=c.notes[i]
      if n.category=='Guild Memory' then
        add(v,'GUILD MEMORY: '..n.title,(n.guild or 'Unknown guild')..'  ·  '..timeFmt(n.at),'guildmemory',n.id)
      end
    end
    if #c.guildHistory==0 then add(v,'NO GUILD CHANGES YET','Guild history will appear after the client exposes membership changes.','fact') end
    v.action='guildmemory' 
  elseif tab=='records' then
    v.title='PERSONAL RECORDS';v.summary='Records that can be verified using locally observed game activity.'
    v.metrics={{'LONGEST SESSION',fmt(c.records.longestSession or 0)},{'PEAK GOLD',gold(c.records.peakGold or 0)},{'ZONES',self:Count(c.zones)},{'LEVEL',c.records.bestLevel or c.level}}
    add(v,'TOTAL TRACKED TIME',fmt(c.stats.active),'fact')
    add(v,'CURRENT GOLD',gold(c.gold),'fact')
    add(v,'LEVEL GAINS',tostring(c.stats.levelUps)..' levels since installation','fact')
    local first
    for zone,z in pairs(c.zones or {}) do
      if z.firstSeen and (not first or z.firstSeen<first.at) then first={name=zone,at=z.firstSeen} end
    end
    if first then add(v,'FIRST TRACKED ZONE',first.name..'  ·  '..timeFmt(first.at),'fact') end
    if c.notes[1] then add(v,'FIRST SAVED MEMORY',c.notes[1].title..'  ·  '..timeFmt(c.notes[1].at),'fact') end
    if c.events[1] then add(v,'FIRST TRACKED MOMENT',c.events[1].title..'  ·  '..timeFmt(c.events[1].at),'fact') end
    add(v,'LONGEST FINISHED SESSION',fmt(c.records.longestSession or 0)..' active time','fact')
    add(v,'PERSONAL GOLD RECORD',gold(c.records.peakGold or 0)..' observed since installation','fact')
    for i=#c.sessionHistory,math.max(1,#c.sessionHistory-5),-1 do
      local s=c.sessionHistory[i]
      add(v,'SESSION '..timeFmt(s.started),fmt(s.active or 0)..' active / '..fmt(s.afk or 0)..' AFK','session',s.id)
    end
  elseif tab=='settings' then
    v.title='SETTINGS & DATA HEALTH';v.summary='Your story stays on your computer. Manage tracking and notifications.'
    v.metrics={{'SCHEMA',self.db.schema},{'CHARACTERS',self:Count(self.db.characters)},{'TRACKING',self.db.settings.tracking and 'ON' or 'OFF'},{'DATA','LOCAL'}}
    add(v,'Gameplay tracking',self.db.settings.tracking and 'Enabled — click to turn off' or 'Disabled — click to turn on','tracking')
    add(v,'Companion tracking',self.db.settings.socialTracking and 'Enabled — click to turn off' or 'Disabled — click to turn on','social')
    local notifs=self.db.settings.notifications
    local order={'special','levels','zones','goals','memories','companions','sessions','guild','records'}
    for _,k in ipairs(order) do
      add(v,'Notification: '..k,notifs[k] and 'Enabled — click to turn off' or 'Disabled — click to turn on','notification',k)
    end
    add(v,'Interface scale',tostring(math.floor((self.db.settings.scale or 1)*100))..'% — click to cycle 85 / 100 / 115%','scale')
    add(v,'Minimap button',self.db.settings.minimap and 'Visible — click to hide' or 'Hidden — click to show','minimap')
    local health=self:DataHealth(false)
    add(v,'Data Health','Click for full validation  ·  '..health.events..' events  ·  '..health.notes..' memories  ·  '..health.sessions..' session records','health')
    add(v,'Prune old session details','Remove raw session and group logs older than 365 days; totals, days, memories and Chronicle stay intact','prune')
    local compat=self:CompatibilityReport()
    add(v,'Forever API readiness','Interface '..tostring(compat.interface)..'  ·  '..(#compat.missing==0 and 'Probed APIs found' or ('Missing: '..table.concat(compat.missing,', ')))..'  ·  Real-client testing required','compat')
    add(v,'Backup & Restore','Export, verify, preview, import or restore local data','backup')
    add(v,'Privacy','Stored only in local SavedVariables. No account or server required.','fact')
  else
    v.title='LIFEFORGE';v.summary='Your character. Your journey. Your legend.'
  end
  if #v.rows==0 then add(v,'The first page is waiting','Play, explore, and create your first lasting memory.','fact') end
  return v
end
LF.ViewFormatTime=fmt
