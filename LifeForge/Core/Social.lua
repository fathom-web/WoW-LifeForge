-- Build 3: social observations and named recurring groups. No network communication.
-- These are *observed roster overlaps*, never proof of friendship or joint combat.
local LF=_G.LifeForge
local activeMembers,activeGroup,activeOwner = {},nil,nil
local rosterPending=false
local BOND_THRESHOLDS={3600,36000,180000,360000}
local function rosterFromAPI()
  if LF:IsCombat() then return nil end -- do not inspect potentially secret combat values
  local result={}
  if type(_G.GetNumGroupMembers)~="function" then return result end
  local size=LF:SafeCall(_G.GetNumGroupMembers)
  if not LF:Finite(size) or size<2 or size>40 then return result end
  local raid=LF:SafeCall(_G.IsInRaid)==true
  for i=1,size do
    local unit=(raid and "raid" or "party")..i
    if not raid and i==size then unit="player" end
    local name,realm=LF:SafeCall(_G.UnitName,unit)
    if type(name)=="string" and name~="" and unit~="player" and LF:SafeCall(_G.UnitIsUnit,unit,"player")~=true then
      realm=(type(realm)=="string" and realm~="") and realm or (LF.char and LF.char.realm or "")
      local key=LF:CharacterKey(realm,name)
      if key and key~=LF.key and not LF.db.settings.mutedCompanions[key] then result[key]=true end
    end
  end
  return result
end
local function membersSorted(roster)
  local keys=LF:Keys(roster)
  return keys,table.concat(keys,"|")
end
local function finishGroup()
  if activeGroup then
    activeGroup.record.ended=LF:Now()
  end
  activeGroup=nil
end
function LF:GetObservedCompanionKeys()
  if not self.char or activeOwner~=self.key or rosterPending or
    not self:IsTracking() or not self.db.settings.socialTracking then return {} end
  return self:Keys(activeMembers)
end
function LF:UpdateGroup()
  if not self.char then return end
  if self.runtime.readOnly or not self:IsTracking() or not self.db.settings.socialTracking then
    finishGroup();activeMembers={};activeOwner=self.key;rosterPending=false;return
  end
  if self:IsCombat() then rosterPending=true;return end
  local roster=rosterFromAPI()
  if not roster then rosterPending=true;return end
  if activeOwner~=self.key then
    finishGroup();activeMembers={};activeOwner=self.key
  end
  local members,signature=membersSorted(roster)
  local oldMembers=activeMembers
  if activeGroup and activeGroup.signature~=signature then finishGroup() end
  if not activeGroup and #members>0 then
    local c=self.char
    if self:Count(c.parties)<self.config.MAX_PARTIES or c.parties[signature] then
      local p=c.parties[signature]
      if not p then
        p={members=members,name="",seconds=0,sessions=0,firstSeen=self:Now(),lastSeen=self:Now(),favorite=false}
        c.parties[signature]=p
      end
      p.sessions=p.sessions+1
      local item={started=self:Now(),seconds=0,members=members,zone=self:Text(c.zone or "",100)}
      if #c.groupHistory>=self.config.MAX_GROUP_HISTORY then table.remove(c.groupHistory,1) end
      c.groupHistory[#c.groupHistory+1]=item
      activeGroup={signature=signature,party=p,record=item}
    end
  end
  for key in pairs(roster) do
    local friend=self.char.companions[key]
    if not friend then
      if self:Count(self.char.companions)<self.config.MAX_COMPANIONS then
        friend={firstSeen=self:Now(),lastSeen=self:Now(),seconds=0,groupSessions=0,bondTier=0}
        self.char.companions[key]=friend
      end
    end
    if friend and not oldMembers[key] then
      local absence=self:Now()-(friend.lastSeen or self:Now())
      if (friend.groupSessions or 0)>0 and absence>=30*86400 then
        local ev=self:Emit("companions","The Last Adventure — Reunited",
          "Grouped again with "..key.." after "..math.floor(absence/86400).." days apart (observed).",true)
        if ev then ev.companionKey=key end
      end
      friend.groupSessions=(friend.groupSessions or 0)+1
    end
  end
  activeMembers=roster;rosterPending=false
end
function LF:TickCompanions(seconds)
  if not self.char or not self:IsTracking() or not self.db.settings.socialTracking or
     activeOwner~=self.key or rosterPending then return end
  local at=self:Now()
  for key in pairs(activeMembers) do
    local friend=self.char.companions[key]
    if friend and not self.db.settings.mutedCompanions[key] then
      local previous=friend.seconds or 0
      friend.seconds=previous+seconds
      friend.lastSeen=at
      for tier,threshold in ipairs(BOND_THRESHOLDS) do
        if previous<threshold and friend.seconds>=threshold and (friend.bondTier or 0)<tier then
          friend.bondTier=tier
          local ev=self:Emit("companions","Legendary Bonds: "..math.floor(threshold/3600).."h",
            "Observed party or raid time with "..key.." reached "..math.floor(threshold/3600).." hours.",true)
          if ev then ev.companionKey=key end
        end
      end
    end
  end
  if activeGroup then
    activeGroup.party.seconds=activeGroup.party.seconds+seconds
    activeGroup.party.lastSeen=at
    activeGroup.record.seconds=activeGroup.record.seconds+seconds
  end
end
function LF:NameParty(signature,name)
  if self.runtime.readOnly or self.runtime.restorePending or not self.char then return false,"Database locked" end
  if type(signature)~="string" or not self.char.parties[signature] then return false,"Unknown party" end
  name=self:Trim(name)
  if #name>80 then return false,"Group nickname too long" end
  self.char.parties[signature].name=name
  return true
end
function LF:EraseCompanion(key)
  if self.runtime.readOnly or not self.char then return false,"Read-only" end
  return self:EraseCompanionEverywhere(key,true)
end
function LF:MuteCompanion(key,value)
  if self.runtime.readOnly or self.runtime.restorePending then return false,"Read-only" end
  self.db.settings.mutedCompanions[key]=value==true or nil
  if value then self:UpdateGroup() end
  return true
end
function LF:EraseCompanionEverywhere(key,confirmed)
  if self.runtime.readOnly or self.runtime.restorePending then return false,"Database locked" end
  if confirmed~=true then return false,"Confirmation required" end
  if type(key)~="string" or key=="" then return false,"Invalid companion key" end
  for _,c in pairs(self.db.characters) do
    c.companions[key]=nil
    for signature,party in pairs(c.parties or {}) do
      for _,member in ipairs(party.members or {}) do
        if member==key then c.parties[signature]=nil;break end
      end
    end
    for i=#(c.groupHistory or {}),1,-1 do
      for _,member in ipairs(c.groupHistory[i].members or {}) do
        if member==key then table.remove(c.groupHistory,i);break end
      end
    end
    for i=#(c.events or {}),1,-1 do
      local e=c.events[i]
      if e.companionKey==key or
         ((e.kind=="companions") and (e.description or ""):find(key,1,true)) then
        table.remove(c.events,i)
      end
    end
    for _,n in ipairs(c.notes or {}) do
      if type(n.companions)=="table" then
        for i=#n.companions,1,-1 do if n.companions[i]==key then table.remove(n.companions,i) end end
      end
    end
  end
  self.db.settings.mutedCompanions[key]=true -- Forget is also an ongoing privacy exclusion.
  if activeMembers[key] then
    activeMembers[key]=nil
    finishGroup()
    rosterPending=true -- re-snapshot roster at next safe event; no more counting meanwhile
  end
  return true
end
