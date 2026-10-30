local LF=_G.LifeForge
function LF:Boot(identity)
  if self.runtime.booted then return true end
  local ok,msg=self:InitializeDB()
  if not ok then self:Log(msg);return false,msg end
  local ready,reason=self:AttachCharacter(identity)
  if not ready then self:Log(reason);return false,reason end
  self:SeedGoals(self.char)
  self:StartTracking()
  self:UpdateGroup()
  self:UpdateGuild()
  self:MonthlySnapshot()
  self:BuildUI()
  self.runtime.booted=true
  if not self.db.meta.introductionShown then
    self:Log("Your locally stored Chronicle begins now. LifeForge does not recover pre-installation history. Settings: /lf settings")
    self.db.meta.introductionShown=true
  end
  self:Log("Build 7 initialized. Type /lifeforge")
  return true
end
function LF:Command(message)
  message=self:Trim(message or "")
  local cmd,rest=message:match("^(%S+)%s*(.-)$")
  cmd=cmd or ""
  if cmd=="backup" then self:ShowBackup();return end
  if self.runtime.restorePending then self:Log("Restore staged: use /reload before further changes");return end
  if cmd=="tracking" or cmd=="social" then
    local flag=rest:lower()
    if flag~="on" and flag~="off" then self:Log("Usage: /lf "..cmd.." on|off");return end
    if self.runtime.readOnly or self.runtime.restorePending then self:Log("Database locked");return end
    if cmd=="tracking" then
      self.db.settings.tracking=(flag=="on")
      if flag=="off" then self:CloseSession() else self:StartSession() end
    else
      self.db.settings.socialTracking=(flag=="on")
      self:UpdateGroup()
    end
    self:Log(cmd.." "..flag);return
  end
  if cmd=="notifications" then
    if self.runtime.readOnly or self.runtime.restorePending then self:Log("Database locked");return end
    local category,flag=rest:match("^(%S+)%s+(%S+)$")
    if not category or not self.db.settings.notifications[category] and self.db.settings.notifications[category]~=false then
      self:Log("Unknown category. Try special, levels, zones, goals, memories, companions, sessions, guild, records");return
    end
    if flag~="on" and flag~="off" then self:Log("Usage: /lf notifications goals on|off");return end
    self.db.settings.notifications[category]=(flag=="on")
    self:Log("Notification "..category.." "..flag);return
  end
  if cmd=="bookmark" then
    local ok,reason=self:QuickBookmark()
    self:Log(ok and "Moment saved as a favorite memory" or tostring(reason))
    return
  end
  if cmd=="note" then
    local title,body=rest:match("^(.-)%s*|%s*(.*)$")
    local ok,reason=self:AddNote(title or rest,body or "")
    self:Log(ok and "Memory added" or tostring(reason));return
  end
  if cmd=="letter" then
    local title,body,condition=rest:match("^(.-)%s*|%s*(.-)%s*|%s*(.-)%s*$")
    local valid,kind,target=self:ParseLetterTrigger(condition)
    if not valid then self:Log(kind);return end
    local ok,reason=self:AddFutureLetter(title,body,kind,target)
    self:Log(ok and "Future letter sealed" or tostring(reason));return
  end
  if cmd=="goal" then
    local title,kind,target=rest:match("^(.-)%s*|%s*(%S+)%s*|%s*(%d+)$")
    local ok,reason=self:AddGoal(title,kind,tonumber(target))
    self:Log(ok and "New goal created" or tostring(reason));return
  end
  if cmd=="diagnostics" then
    local h=self:DataHealth();local compat=self:CompatibilityReport()
    self:Log("DB schema "..tostring(h.schema).." / valid: "..tostring(h.valid).."; "..tostring(h.characters).." characters, "..tostring(h.events).." events, "..tostring(h.notes).." notes"..(h.reason and ("; issue: "..tostring(h.reason)) or ""))
    self:Log("Client interface "..tostring(compat.interface).."; API availability is provisional until in-game checks. Missing: "..table.concat(compat.missing,", "))
    return
  end
  if cmd=="help" then
    self:Log("/lf [overview|characters|chronicle|timeline|statistics|companions|goals|vault|museum|footprint|calendar|capsules|wrapped|guild|records|settings|backup]")
    self:Log("/lf bookmark; /lf note Title | Body; /lf goal Name | level | 60; /lf letter Title | Body | level:60 (or hours:100 / date:2027-01-01)")
    self:Log("/lf tracking on|off; /lf social on|off; /lf notifications [category] on|off; /lf diagnostics")
    return
  end
  if cmd=="" then self:Show() else self:Show(cmd) end
end
if type(_G.SlashCmdList)=="table" then
  _G.SLASH_LIFEFORGE1="/lifeforge"
  _G.SLASH_LIFEFORGE2="/lf"
  _G.SlashCmdList.LIFEFORGE=function(msg) LF:Command(msg) end
end
if type(_G.CreateFrame)=="function" then
  local bootFrame=CreateFrame("Frame")
  bootFrame:RegisterEvent("PLAYER_LOGIN")
  bootFrame:SetScript("OnEvent",function() LF:Boot() end)
end