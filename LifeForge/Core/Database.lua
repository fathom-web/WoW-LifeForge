local LF=_G.LifeForge
local function defaults()
  return {
    schema=2, created=LF:Now(), updated=LF:Now(),
    settings={tracking=true, socialTracking=true, mutedCompanions={}, minimap=true, scale=1,
      retentionDays=3650, notifications={special=true, levels=false, zones=false, goals=false,
        memories=false, companions=false, sessions=false, guild=false, records=false},
      ui={selectedScope="character", selectedTab="overview"}},
    characters={}, characterOrder={}, meta={migrations={}, lastExportAt=0},
    future={designVersion=1},
  }
end
LF.DefaultDB=defaults
local function ensure(t,k,default)
  if type(t[k])~=type(default) then t[k]=default end
end
function LF:MigrateLegacy(db)
  -- One-way in-memory migration of schema 1; keep a copy in SavedVariables for manual recovery.
  if db.schema==2 then return true end
  if db.schema~=1 and db.schema~=nil then return false,"Unknown legacy schema" end
  local old= self:DeepCopy(db)
  local base=defaults()
  db._legacyBackupV1=old -- intentionally retained until the user backs up externally
  ensure(db,"characters",{})
  db.characterOrder=type(db.order)=="table" and db.order or {}
  db.settings=type(db.settings)=="table" and db.settings or {}
  for k,v in pairs(base.settings) do if type(db.settings[k])~=type(v) then db.settings[k]=v end end
  db.settings.notifications=db.settings.notifications or base.settings.notifications
  for k,v in pairs(base.settings.notifications) do
    if type(db.settings.notifications[k])~="boolean" then db.settings.notifications[k]=v end
  end
  for _,c in pairs(db.characters) do
    if type(c)=="table" then
      c.stats=type(c.stats)=="table" and c.stats or {}
      c.stats.active=self:SafeInt(c.stats.active,0,0)
      c.stats.afk=self:SafeInt(c.stats.afk,0,0)
      c.stats.sessions=self:SafeInt(c.stats.sessions,0,0)
      c.stats.levelUps=self:SafeInt(c.stats.levelUps,0,0)
      c.stats.goldDelta=self:SafeInt(c.stats.goldDelta,0,-1e15,1e15)
      c.events=type(c.events)=="table" and c.events or {}
      c.notes=type(c.notes)=="table" and c.notes or {}
      c.goals=type(c.goals)=="table" and c.goals or {}
      c.zones=type(c.zones)=="table" and c.zones or {}
      c.companions={};c.groupHistory={};c.guildHistory={};c.parties={};c.records={};c.daily={};c.snapshots={};c.letters={}
      c.sessionHistory={};c.nextId=self:SafeInt(c.nextId,1,1);c.retired=false
      c.stats.goldEarned=0;c.stats.goldSpent=0
      -- Alpha had an open session but no reliable finalization; do not count invented duration.
      c.openSession=nil
      c.level=self:SafeInt(c.level,1,1,1000)
      c.gold=self:SafeInt(c.gold,0,0,1e15)
      c.name=type(c.name)=="string" and c.name or "Unknown"
      c.realm=type(c.realm)=="string" and c.realm or "Unknown"
    end
  end
  db.meta={migrations={{from=1,to=2,at=self:Now()}},lastExportAt=0}
  db.future={designVersion=1}
  db.schema=2;db.updated=self:Now()
  return true
end
function LF:InitializeDB(raw)
  raw=raw or _G.LifeForgeDB
  if type(raw)~="table" then raw=defaults() end
  local schema=raw.schema
  if type(schema)=="number" and schema>self.schema then
    self.db=raw;self.runtime.readOnly=true
    return false,"Database was written by a newer LifeForge version; read-only protection enabled"
  end
  if schema~=2 then
    local ok,success,err=pcall(function() return self:MigrateLegacy(raw) end)
    if not ok or not success then
      self.db=raw;self.runtime.readOnly=true
      return false,"Legacy database migration failed: "..tostring(err or success)
    end
  end
  local base=defaults()
  for _,key in ipairs({"settings","characters","characterOrder","meta","future"}) do
    ensure(raw,key,base[key])
  end
  for k,v in pairs(base.settings) do ensure(raw.settings,k,v) end
  for k,v in pairs(base.settings.notifications) do ensure(raw.settings.notifications,k,v) end
  ensure(raw.settings,"mutedCompanions",{})
  ensure(raw.settings,"ui",base.settings.ui)
  -- Normalize every stored alt, not just the currently logged-in character.
  -- Older LF2 backups may not contain fields added in Build 3.
  for _,c in pairs(raw.characters) do
    if type(c)=="table" then self:NormalizeCharacter(c) end
  end
  if type(raw.updated)~="number" then raw.updated=self:Now() end
  self.db=raw
  _G.LifeForgeDB=raw
  return true
end
function LF:NewCharacter(name,realm)
  local ts=self:Now()
  return {name=name,realm=realm,created=ts,lastSeen=ts,level=1,gold=0,
    stats={active=0,afk=0,sessions=0,levelUps=0,goldDelta=0,goldEarned=0,goldSpent=0},
    events={},notes={},goals={},zones={},companions={},groupHistory={},guildHistory={},parties={},records={},
    daily={},snapshots={},letters={},sessionHistory={},nextId=1,retired=false,openSession=nil}
end
function LF:NormalizeCharacter(c)
  for _,k in ipairs({"events","notes","goals","zones","companions","groupHistory","guildHistory","parties","records","daily","snapshots","letters","sessionHistory"}) do
    if type(c[k])~="table" then c[k]={} end
  end
  if type(c.stats)~="table" then c.stats={} end
  c.records.peakGold=self:SafeInt(c.records.peakGold,c.gold or 0,0,1e15)
  c.records.longestSession=self:SafeInt(c.records.longestSession,0,0)
  c.records.bestLevel=self:SafeInt(c.records.bestLevel,c.level or 1,1,1000)
  for _,k in ipairs({"active","afk","sessions","levelUps","goldDelta","goldEarned","goldSpent"}) do
    if not self:Finite(c.stats[k]) then c.stats[k]=0 end
  end
  c.nextId=self:SafeInt(c.nextId,1,1)
  if type(c.retired)~="boolean" then c.retired=false end
  for _,g in pairs(c.goals) do
    if type(g)=="table" and type(g.hidden)~="boolean" then g.hidden=false end
  end
end
function LF:ReadOnlyHealth()
  return {schema=self.db and self.db.schema or 0,characters=self.db and self:Count(self.db.characters) or 0,
    tracking=self:IsTracking(),readOnly=self.runtime.readOnly==true}
end
