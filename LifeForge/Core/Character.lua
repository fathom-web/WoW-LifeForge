local LF=_G.LifeForge
function LF:AttachCharacter(identity)
  identity=identity or {}
  local name=identity.name or self:SafeCall(_G.UnitName,"player")
  local realm=identity.realm or self:SafeCall(_G.GetNormalizedRealmName) or self:SafeCall(_G.GetRealmName)
  local key=self:CharacterKey(realm,name)
  if not key then return false,"Character data not ready" end
  local c=self.db.characters[key]
  if not c then
    -- Reuse alpha key when the old realm had spaces.
    local alias=self:CharacterKey(self:SafeCall(_G.GetRealmName),name)
    if alias and alias~=key and self.db.characters[alias] then
      c=self.db.characters[alias];self.db.characters[alias]=nil
      for i,v in ipairs(self.db.characterOrder) do if v==alias then self.db.characterOrder[i]=key end end
    end
  end
  if not c then
    c=self:NewCharacter(name,realm)
    self.db.characters[key]=c
    self.db.characterOrder[#self.db.characterOrder+1]=key
  end
  self:NormalizeCharacter(c)
  self.key,self.char=key,c
  c.name=name;c.realm=realm;c.lastSeen=self:Now()
  local _,class=self:SafeCall(_G.UnitClass,"player")
  local _,race=self:SafeCall(_G.UnitRace,"player")
  c.class=identity.class or class or c.class or "UNKNOWN"
  c.race=identity.race or race or c.race or "UNKNOWN"
  c.faction=identity.faction or self:SafeCall(_G.UnitFactionGroup,"player") or c.faction or "Unknown"
  local level=identity.level or self:SafeCall(_G.UnitLevel,"player")
  if self:Finite(level) and level>=1 then c.level=math.floor(level) end
  local money=identity.gold or self:SafeCall(_G.GetMoney)
  if self:Finite(money) then c.gold=math.floor(money) end
  self:RecordPeakGold(c.gold)
  self:RecordPeakLevel(c.level)
  if not c.welcomed then
    c.welcomed=true
    self:Emit("start","Your Adventure Began","LifeForge began recording your journey.",true,c)
  end
  return true
end
function LF:GetKeys(scope, focusKey)
  if not self.db or not self.db.characters then return {} end
  scope=scope or "character"
  local focus=focusKey or self.key
  local focusCharacter=self.db.characters[focus] or self.char
  local found={}
  for key,c in pairs(self.db.characters) do
    if scope=="account" or (scope=="realm" and focusCharacter and c.realm==focusCharacter.realm)
      or (scope=="character" and key==focus) then found[#found+1]=key end
  end
  table.sort(found)
  return found
end
function LF:Totals(scope, focusKey)
  local total={characters=0,active=0,afk=0,sessions=0,levelUps=0,notes=0,events=0,zones=0,
    companions=0,goldCurrent=0}
  for _,key in ipairs(self:GetKeys(scope,focusKey)) do
    local c=self.db.characters[key];local s=c.stats
    total.characters=total.characters+1
    for _,field in ipairs({"active","afk","sessions","levelUps"}) do
      total[field]=total[field]+(s[field] or 0)
    end
    total.notes=total.notes+#c.notes;total.events=total.events+#c.events
    total.zones=total.zones+self:Count(c.zones)
    total.companions=total.companions+self:Count(c.companions)
    total.goldCurrent=total.goldCurrent+(c.gold or 0)
  end
  return total
end
function LF:FamilyLegacy(scope,focusKey)
  local keys=self:GetKeys(scope or "account",focusKey)
  local family={characters=0,active=0,first=nil,mostPlayed=nil,archived=0,
    realms={},combinedLevels=0,memories=0}
  for _,key in ipairs(keys) do
    local c=self.db.characters[key]
    if c then
      family.characters=family.characters+1
      family.active=family.active+(c.stats.active or 0)
      family.combinedLevels=family.combinedLevels+(c.level or 1)
      family.memories=family.memories+#(c.notes or {})
      if c.retired then family.archived=family.archived+1 end
      family.realms[c.realm or "Unknown"]=true
      if not family.first or (c.created or 0)<(family.first.created or 0) then
        family.first={key=key,name=c.name,realm=c.realm,created=c.created}
      end
      if not family.mostPlayed or (c.stats.active or 0)>family.mostPlayed.active then
        family.mostPlayed={key=key,name=c.name,realm=c.realm,active=c.stats.active or 0}
      end
    end
  end
  family.realmCount=self:Count(family.realms)
  return family
end
function LF:SetRetired(key,value)
  if self.runtime.readOnly or self.runtime.restorePending then return false,"Database locked" end
  if not self.db.characters[key] then return false,"Unknown character" end
  self.db.characters[key].retired = value==true
  return true
end
