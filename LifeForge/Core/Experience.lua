-- Build 4: pure, bounded presentation models. No world-map position is fabricated.
-- All statistics are observed locally; period metrics NEVER infer historical group time.
local LF=_G.LifeForge
local function clampInt(v,lo,hi)
  if type(v)~='number' or v~=v then return lo end
  return math.max(lo,math.min(hi,math.floor(v)))
end
local function isLeap(y) return y%4==0 and (y%100~=0 or y%400==0) end
local function monthDays(y,m)
  local days={31,isLeap(y) and 29 or 28,31,30,31,30,31,31,30,31,30,31}
  return days[m]
end
-- Sakamoto algorithm: 0=Sunday, independent of local timezone, DST, and WoW APIs.
local offsets={0,3,2,5,0,3,5,1,4,6,2,4}
local function weekday(y,m,d)
  local yr=y
  if m<3 then yr=yr-1 end
  return (yr+math.floor(yr/4)-math.floor(yr/100)+math.floor(yr/400)+offsets[m]+d)%7
end
local function dateKey(y,m,d) return string.format('%04d-%02d-%02d',y,m,d) end
local function periodOf(stamp)
  if type(stamp)~='number' then return nil end
  return LF:Date('%Y-%m',stamp)
end
local function dayOf(stamp)
  if type(stamp)~='number' then return nil end
  return LF:Date('%Y-%m-%d',stamp)
end
local function chars(self,scope,key)
  local result={}
  if not self.db or not self.db.characters then return result end
  local keys=self:GetKeys(scope or 'character',key or self.key)
  for _,k in ipairs(keys or {}) do
    local c=self.db.characters[k]
    if type(c)=='table' then result[#result+1]=c end
  end
  return result
end
local function dayData()
  return {active=0,afk=0,sessions=0,levels=0,events=0,memories=0}
end
function LF:CalendarModel(year,month,scope,key)
  year=clampInt(year,2000,2100);month=clampInt(month,1,12)
  local group=chars(self,scope,key)
  local byDay,peak={},0
  for d=1,monthDays(year,month) do byDay[d]=dayData() end
  local prefix=string.format('%04d-%02d-',year,month)
  for _,c in ipairs(group) do
    for day,entry in pairs(c.daily or {}) do
      if type(day)=='string' and day:sub(1,8)==prefix then
        local d=tonumber(day:sub(9,10))
        local out=d and byDay[d]
        if out and type(entry)=='table' then
          for _,k in ipairs({'active','afk','sessions','levels'}) do
            local value=entry[k]
            if self:Finite(value) then out[k]=out[k]+math.max(0,value) end
          end
        end
      end
    end
    for _,e in ipairs(c.events or {}) do
      local date=dayOf(e.at)
      if date and date:sub(1,8)==prefix then
        local d=tonumber(date:sub(9,10))
        if byDay[d] then byDay[d].events=byDay[d].events+1 end
      end
    end
    for _,n in ipairs(c.notes or {}) do
      local date=dayOf(n.at)
      if date and date:sub(1,8)==prefix then
        local d=tonumber(date:sub(9,10))
        if byDay[d] then byDay[d].memories=byDay[d].memories+1 end
      end
    end
  end
  local summary=dayData();local activeDays=0
  for d=1,#byDay do
    local e=byDay[d]
    for k in pairs(summary) do summary[k]=summary[k]+e[k] end
    if e.active>0 or e.afk>0 then activeDays=activeDays+1 end
    peak=math.max(peak,e.active)
  end
  summary.activeDays=activeDays
  local first=weekday(year,month,1) -- Sunday-first heatmap.
  local cells={}
  for i=1,42 do
    local d=i-first
    local entry=byDay[d]
    cells[i]={day=entry and d or nil,key=entry and dateKey(year,month,d) or nil,
      active=entry and entry.active or 0,events=entry and entry.events or 0,
      memories=entry and entry.memories or 0,
      intensity=entry and peak>0 and math.ceil(4*entry.active/peak) or 0,
      summary=entry}
  end
  return {year=year,month=month,label=string.format('%04d-%02d',year,month),cells=cells,
    totals=summary,peak=peak,characters=#group}
end
function LF:FootprintModel(scope,key)
  local grouped={}
  for _,c in ipairs(chars(self,scope,key)) do
    for zone,z in pairs(c.zones or {}) do
      if type(zone)=='string' and type(z)=='table' then
        local item=grouped[zone] or {name=zone,seconds=0,visits=0,firstSeen=nil,memories=0,mapID=nil}
        item.seconds=item.seconds+math.max(0,tonumber(z.seconds) or 0)
        -- Map coordinates are *observed samples* tied to a verified map ID.
        if type(z.mapID)=='number' and z.mapID>0 then
          if not item.mapID then
            item.mapID=z.mapID;item.mapName=z.mapName;item.parentMapID=z.parentMapID
          end
          if item.mapID==z.mapID and type(z.sampleX)=='number' and type(z.sampleY)=='number'
             and z.sampleX>=0 and z.sampleX<=1 and z.sampleY>=0 and z.sampleY<=1
             and (not item.sampledAt or (z.sampledAt or 0)>item.sampledAt) then
            item.sampleX=z.sampleX;item.sampleY=z.sampleY;item.sampledAt=z.sampledAt
          end
        end
        item.visits=item.visits+1 -- number of characters who recorded the zone, NOT travel visits
        if type(z.firstSeen)=='number' then
          item.firstSeen=math.min(item.firstSeen or z.firstSeen,z.firstSeen)
        end
        grouped[zone]=item
      end
    end
    for _,n in ipairs(c.notes or {}) do
      local z=grouped[n.zone]
      if z then z.memories=z.memories+1 end
    end
  end
  local items,maxSeconds={},0
  for _,z in pairs(grouped) do
    items[#items+1]=z;maxSeconds=math.max(maxSeconds,z.seconds)
  end
  table.sort(items,function(a,b)
    if a.seconds==b.seconds then return a.name<b.name end
    return a.seconds>b.seconds
  end)
  for _,z in ipairs(items) do z.ratio=maxSeconds>0 and z.seconds/maxSeconds or 0 end
  return {zones=items,count=#items,maxSeconds=maxSeconds,mode='ZONE ATLAS',notice='Only map IDs/coordinates actually observed from C_Map are included. Never inferred from zone labels.'}
end
function LF:MuseumModel(scope,key)
  local items={}
  for _,c in ipairs(chars(self,scope,key)) do
    for _,n in ipairs(c.notes or {}) do
      if n.favorite then items[#items+1]={id=n.id,kind='note',character=c.name,characterKey=LF:CharacterKey(c.realm,c.name),title=n.title,
        zone=n.zone,at=n.at,description=n.body,category=n.category} end
    end
    for _,e in ipairs(c.events or {}) do
      if e.favorite then items[#items+1]={id=e.id,kind='event',character=c.name,characterKey=LF:CharacterKey(c.realm,c.name),title=e.title,
        zone=e.zone,at=e.at,description=e.description,category=e.kind} end
    end
  end
  table.sort(items,function(a,b)
    if a.at==b.at then return tostring(a.title)<tostring(b.title) end
    return (a.at or 0)>(b.at or 0)
  end)
  return {exhibits=items,total=#items,notice='Exhibits are favorited memories and milestones, never fabricated loot.'}
end
function LF:WrappedPeriods(scope,key)
  local set={}
  for _,c in ipairs(chars(self,scope,key)) do
    for d in pairs(c.daily or {}) do
      if type(d)=='string' and d:match('^%d%d%d%d%-%d%d%-%d%d$') then set[d:sub(1,7)]=true end
    end
    for _,e in ipairs(c.events or {}) do local p=periodOf(e.at);if p then set[p]=true end end
    for _,n in ipairs(c.notes or {}) do local p=periodOf(n.at);if p then set[p]=true end end
  end
  local periods={'all'}
  local entries=self:Keys(set)
  table.sort(entries,function(a,b)return a>b end)
  for _,p in ipairs(entries) do periods[#periods+1]=p end
  return periods
end
function LF:WrappedModel(period,scope,key)
  period=period or 'all'
  if period~='all' and (type(period)~='string' or not period:match('^%d%d%d%d%-%d%d$') or
    tonumber(period:sub(6,7))<1 or tonumber(period:sub(6,7))>12) then
    return nil,'Invalid reporting period'
  end
  local total={active=0,afk=0,sessions=0,levels=0,events=0,notes=0,zones=0,
    companions=0,days=0,characters=0,period=period,topZone=nil,topCompanion=nil}
  local days,zoneTotals,friendTotals={},{},{}
  for _,c in ipairs(chars(self,scope,key)) do
    total.characters=total.characters+1
    if period=='all' then
      total.active=total.active+math.max(0,c.stats.active or 0)
      total.afk=total.afk+math.max(0,c.stats.afk or 0)
      total.sessions=total.sessions+math.max(0,c.stats.sessions or 0)
      total.levels=total.levels+math.max(0,c.stats.levelUps or 0)
    else
      for day,datum in pairs(c.daily or {}) do
        if type(day)=='string' and day:sub(1,7)==period and type(datum)=='table' then
          for _,k in ipairs({'active','afk','sessions','levels'}) do
            total[k]=total[k]+math.max(0,tonumber(datum[k]) or 0)
          end
        end
      end
    end
    for day,d in pairs(c.daily or {}) do
      if (period=='all' or (type(day)=='string' and day:sub(1,7)==period))
        and ((d.active or 0)>0 or (d.afk or 0)>0) then days[day]=true end
    end
    for _,e in ipairs(c.events or {}) do if period=='all' or periodOf(e.at)==period then total.events=total.events+1 end end
    for _,n in ipairs(c.notes or {}) do if period=='all' or periodOf(n.at)==period then total.notes=total.notes+1 end end
    for zone,z in pairs(c.zones or {}) do
      if period=='all' or periodOf(z.firstSeen)==period then total.zones=total.zones+1 end
      if period=='all' then zoneTotals[zone]=(zoneTotals[zone] or 0)+math.max(0,z.seconds or 0) end
    end
    if period=='all' then
      for player,f in pairs(c.companions or {}) do
        total.companions=total.companions+1 -- observed character-companion pairs, not unique humans
        friendTotals[player]=(friendTotals[player] or 0)+math.max(0,f.seconds or 0)
      end
    end
  end
  total.days=self:Count(days)
  local function best(t)
    local name,amount=nil,-1
    for k,v in pairs(t) do if v>amount or (v==amount and tostring(k)<tostring(name)) then name=k;amount=v end end
    if name then return {name=name,seconds=amount} end
  end
  total.topZone=best(zoneTotals);total.topCompanion=best(friendTotals)
  total.scope=scope or 'character'
  total.periodLabel=period=='all' and 'ALL TRACKED TIME' or period
  total.disclaimer=period=='all' and 'Observed since installation, on this computer.' or
    'Monthly group time and zone-duration history are not available; only verifiable month events are included.'
  return total
end