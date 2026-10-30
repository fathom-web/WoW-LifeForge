local LF=_G.LifeForge
local function appendBounded(t, event, cap)
  t[#t+1]=event
  if #t<=cap then return end
  -- Never silently remove a manually favorited event.
  for i=1,#t do if not t[i].favorite then table.remove(t,i);return end end
  -- Full of favorites: refuse additional events instead of destroying favorite history.
  t[#t]=nil
end
function LF:Emit(kind,title,description,special,character)
  if not self:IsTracking() then return nil end
  local c=character or self.char
  if not c then return nil end
  local id=self:NextId(c)
  local e={id=id,at=self:Now(),kind=self:Text(kind,24),title=self:Text(title,100),
    description=self:Text(description,500),zone=self:Text(c.zone or "",100),favorite=false}
  appendBounded(c.events,e,self.config.MAX_EVENTS)
  self.db.updated=self:Now()
  self:Notify(e,special)
  if self.Refresh then self:Refresh() end
  return e
end
function LF:NextId(c)
  local n=c.nextId or 1;c.nextId=n+1;return n
end
function LF:Notify(e,special)
  local choices=self.db.settings.notifications
  if not ((special and choices.special) or choices[e.kind]) then return end
  if self:IsCombat() then
    local pending=self.runtime.pendingNotices
    if #pending<15 then pending[#pending+1]=e.title end
    return
  end
  if type(_G.RaidNotice_AddMessage)=="function" and _G.RaidWarningFrame then
    self:SafeCall(_G.RaidNotice_AddMessage,_G.RaidWarningFrame,"LifeForge: "..e.title,
      _G.ChatTypeInfo and _G.ChatTypeInfo.SYSTEM)
  else
    self:Log(e.title)
  end
end
function LF:FlushNotices()
  if self:IsCombat() then return end
  local pending=self.runtime.pendingNotices
  if #pending==0 then return end
  self:Log(tostring(#pending).." milestone notification(s) collected during combat")
  for i=1,#pending do self:Log(pending[i]) end
  self.runtime.pendingNotices={}
end
