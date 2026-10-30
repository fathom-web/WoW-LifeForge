-- Build 5 management APIs. Pure account-safe mutations with explicit destructive consent.
local LF=_G.LifeForge
local kinds={time=true,level=true,zones=true,notes=true,companions=true,gold=true}
function LF:CanWrite()
  if not self.db or not self.char or self.runtime.readOnly or self.runtime.restorePending then
    return false,"Database locked"
  end
  return true
end
function LF:EditGoal(id,title,kind,target)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  local g=self.char.goals[id]
  if not g then return false,"Goal not found" end
  title=self:Trim(title)
  if title=='' or #title>100 or not kinds[kind] or not self:Finite(target) or
      target<1 or target>1e12 then return false,"Invalid goal: title, kind or target" end
  local changed=(g.target~=math.floor(target) or g.kind~=kind)
  g.title=title;g.kind=kind;g.target=math.floor(target)
  if changed then g.completed=false end
  g.preset=false -- an edited preset stays edited between logins
  if self:IsTracking() then self:CheckGoals() end
  return true
end
function LF:DeleteGoal(id,confirmed)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  if confirmed~=true then return false,'Explicit confirmation required' end
  local g=self.char.goals[id]
  if not g then return false,'Goal not found' end
  if g.preset then g.hidden=true else self.char.goals[id]=nil end
  return true
end
function LF:SetGoalHidden(id,hide)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  local g=self.char.goals[id]
  if not g then return false,'Goal not found' end
  g.hidden=hide==true
  return true
end
function LF:EditNoteFull(id,title,body,category)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  category=self:Trim(category)
  if category=='' or #category>50 then return false,'Invalid memory category' end
  ok,reason=self:EditNote(id,title,body)
  if ok then local n=self:FindNote(id);n.category=category end
  return ok,reason
end
function LF:DeleteFutureLetter(id,confirmed)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  if confirmed~=true then return false,'Explicit confirmation required' end
  for i,l in ipairs(self.char.letters) do
    if l.id==id then table.remove(self.char.letters,i);return true end
  end
  return false,'Letter not found'
end
function LF:QuickBookmark()
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  if not self:IsTracking() then return false,'Tracking disabled' end
  local zone=self:Trim(self.char.zone or '')
  local title=zone~='' and ('A Moment in '..zone) or 'A Moment in Azeroth'
  local date=self:Date('%Y-%m-%d %H:%M',self:Now())
  local saved,id=self:AddNote(title,'Bookmarked '..date..' (local game time).','Adventure')
  if not saved then return false,id end
  self:FavoriteNote(id,true)
  return true,id
end
function LF:DataHealth(full)
  local d=self.db
  if type(d)~='table' or type(d.characters)~='table' then
    return {valid=false,reason='Database unavailable'}
  end
  local report={schema=d.schema,characters=0,notes=0,events=0,goals=0,letters=0,
    sessions=0,groupRecords=0,days=0,snapshots=0,archived=0,valid=false}
  for _,c in pairs(d.characters) do
    report.characters=report.characters+1
    if c.retired then report.archived=report.archived+1 end
    report.notes=report.notes+#(c.notes or {})
    report.events=report.events+#(c.events or {})
    report.goals=report.goals+self:Count(c.goals)
    report.letters=report.letters+#(c.letters or {})
    report.sessions=report.sessions+#(c.sessionHistory or {})
    report.groupRecords=report.groupRecords+#(c.groupHistory or {})
    report.days=report.days+self:Count(c.daily)
    report.snapshots=report.snapshots+self:Count(c.snapshots)
  end
  if full~=false then
    local valid,why=self:ValidateDB(d)
    report.valid=valid;report.reason=why
  else
    report.valid=nil;report.reason='Use /lf diagnostics to run full validation'
  end
  return report
end
function LF:PruneRawHistory(days,confirmed,key)
  local ok,reason=self:CanWrite();if not ok then return false,reason end
  if confirmed~=true then return false,'Explicit confirmation required' end
  if not self:Finite(days) or days<30 or days>36500 then return false,'Invalid retention interval' end
  local c=self.db.characters[key or self.key]
  if not c then return false,'Unknown character' end
  local cutoff=self:Now()-math.floor(days)*86400
  local removed=0
  for _,field in ipairs({'sessionHistory','groupHistory'}) do
    local arr=c[field]
    for i=#arr,1,-1 do
      local t=field=='sessionHistory' and (arr[i].ended or arr[i].started) or arr[i].started
      if type(t)=='number' and t<cutoff then table.remove(arr,i);removed=removed+1 end
    end
  end
  -- NEVER discard aggregate statistics, day totals, snapshots, notes,
  -- favorite milestones, Chronicle events, letters or bonds implicitly.
  return true,removed
end
function LF:SessionIntelligence(c)
  c=c or self.char
  if not c then return nil end
  local count,active,afk,longest=0,0,0,0
  for _,s in ipairs(c.sessionHistory or {}) do
    count=count+1;active=active+(s.active or 0);afk=afk+(s.afk or 0)
    longest=math.max(longest,s.active or 0)
  end
  local current=c.openSession
  return {completed=count,completedActive=active,completedAFK=afk,
    meanActive=count>0 and math.floor(active/count) or 0,longestFinished=longest,
    currentActive=current and (current.active or 0) or 0,
    currentAFK=current and (current.afk or 0) or 0}
end
function LF:CompatibilityReport()
  local build=type(_G.GetBuildInfo)=='function' and {self:SafeCall(_G.GetBuildInfo)} or {}
  local interface=tonumber(build[4])
  local api={UnitName=type(_G.UnitName)=='function',GetMoney=type(_G.GetMoney)=='function',
    GetZoneText=type(_G.GetZoneText)=='function',GetNumGroupMembers=type(_G.GetNumGroupMembers)=='function',
    UnitIsAFK=type(_G.UnitIsAFK)=='function',CreateFrame=type(_G.CreateFrame)=='function'}
  local missing={}
  for k,available in pairs(api) do if not available then missing[#missing+1]=k end end
  table.sort(missing)
  return {interface=interface or 'unknown',expected=16001,
    version=tostring(build[1] or 'unknown'),missing=missing,
    provisional=interface~=16001,verifiedInGame=false}
end
