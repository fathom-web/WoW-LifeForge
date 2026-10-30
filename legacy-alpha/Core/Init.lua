local addonName, LF = ...
LF = LF or {}
_G.LifeForge = LF
LF.version = "0.1.0-alpha"
LF.schema = 1
LF.modules = {}
LF.listeners = {}
LF.goldThreshold = 10000
LF.goalPresets = {
  {id="time10", title="A Life in Azeroth", kind="time", target=10*3600},
  {id="time50", title="The Veteran", kind="time", target=50*3600},
  {id="zones10", title="The Explorer", kind="zones", target=10},
  {id="level40", title="The Road to Forty", kind="level", target=40},
  {id="notes5", title="Keeper of Memories", kind="notes", target=5},
}
local function now() return time() end
LF.Now = now
function LF:Stamp() return date("%Y-%m-%d %H:%M", now()) end
function LF:DefaultDB()
  return {schema=1, created=now(), settings={scale=1, notifications={special=true, levels=false, zones=false, goals=false}, tracking=true, minimap=true}, characters={}, order={}}
end
function LF:Boot()
  if type(LifeForgeDB) ~= "table" then LifeForgeDB = self:DefaultDB() end
  self.db = LifeForgeDB
  if type(self.db.characters) ~= "table" then self.db.characters = {} end
  if type(self.db.settings) ~= "table" then self.db.settings = self:DefaultDB().settings end
  if type(self.db.settings.notifications) ~= "table" then self.db.settings.notifications = self:DefaultDB().settings.notifications end
  if self.db.settings.tracking == nil then self.db.settings.tracking = true end
  if type(self.db.order) ~= "table" then self.db.order = {} end
  if (tonumber(self.db.schema) or 0) > self.schema then
    print("|cffff7777LifeForge: database was created by a newer addon version. Tracking disabled.|r")
    self.readOnly = true
    return
  end
  self.db.schema = self.schema
  local name, realm = UnitName("player"), GetRealmName()
  if not name or not realm then return end
  local key = realm .. ":" .. name
  local c = self.db.characters[key]
  if not c then
    c = {name=name, realm=realm, created=now(), events={}, notes={}, goals={}, zones={}, stats={active=0, afk=0, sessions=0, goldDelta=0, levelUps=0}, nextId=1}
    self.db.characters[key] = c
    table.insert(self.db.order,key)
  end
  c.stats = c.stats or {active=0, afk=0, sessions=0, goldDelta=0, levelUps=0}
  c.events = c.events or {}; c.notes = c.notes or {}; c.goals = c.goals or {}; c.zones = c.zones or {}; c.nextId = c.nextId or 1
  self.key, self.char = key, c
  c.class = select(2, UnitClass("player")) or "UNKNOWN"
  c.race = select(2, UnitRace("player")) or "UNKNOWN"
  c.faction = UnitFactionGroup("player") or "Unknown"
  c.level = UnitLevel("player") or 1
  c.gold = GetMoney() or 0
  c.lastSeen = now()
  if not c.welcomed then self:AddEvent("start", "Your Adventure Began", "Your LifeForge chronicle begins today.", true); c.welcomed=true end
  for _, preset in ipairs(self.goalPresets) do
    if not c.goals[preset.id] then c.goals[preset.id]={id=preset.id, title=preset.title, kind=preset.kind, target=preset.target, completed=false} end
  end
  if self.StartTracking then self:StartTracking() end
  if self.BuildUI then self:BuildUI() end
  print("|cffd6ad65LifeForge|r ready. Type /lifeforge")
end
function LF:AddEvent(kind,title,description,special)
  local c=self.char
  if not c or self.readOnly or not self.db.settings.tracking then return end
  local id=c.nextId or 1; c.nextId=id+1
  table.insert(c.events, {id=id, at=now(), kind=kind, title=title, description=description or "", zone=GetZoneText() or "", favorite=false})
  if #c.events > 1500 then
    for i=1,#c.events do if not c.events[i].favorite then table.remove(c.events,i); break end end
  end
  local notify=self.db.settings.notifications or {}
  if (special and notify.special) or notify[kind] then
    if not (InCombatLockdown and InCombatLockdown()) then
      RaidNotice_AddMessage(RaidWarningFrame, "LifeForge: "..title, ChatTypeInfo["SYSTEM"])
    end
  end
  if self.Refresh then self:Refresh() end
end
function LF:GetKeys(scope)
  local found={}
  for key, c in pairs(self.db.characters) do
    if scope=="account" or (scope=="realm" and c.realm==self.char.realm) or (scope=="character" and key==self.key) then table.insert(found,key) end
  end
  table.sort(found)
  return found
end
function LF:Totals(scope)
  local t={characters=0, active=0, afk=0, sessions=0, levels=0, notes=0, zones=0, events=0}
  for _,key in ipairs(self:GetKeys(scope or "character")) do
    local c=self.db.characters[key]
    t.characters=t.characters+1; t.active=t.active+(c.stats.active or 0); t.afk=t.afk+(c.stats.afk or 0)
    t.sessions=t.sessions+(c.stats.sessions or 0); t.levels=t.levels+(c.level or 0)
    t.notes=t.notes+#(c.notes or {}); t.events=t.events+#(c.events or {})
    for _ in pairs(c.zones or {}) do t.zones=t.zones+1 end
  end
  return t
end
function LF:GoalProgress(c,g)
  if g.kind=="time" then return c.stats.active or 0 end
  if g.kind=="level" then return c.level or 1 end
  if g.kind=="zones" then local n=0;for _ in pairs(c.zones) do n=n+1 end;return n end
  if g.kind=="notes" then return #c.notes end
  return 0
end
function LF:CheckGoals()
  local c=self.char; if not c then return end
  for _,g in pairs(c.goals) do
    if not g.completed and self:GoalProgress(c,g)>=g.target then
      g.completed=self:Now(); self:AddEvent("goals","Goal Completed: "..g.title,"A new milestone has been forged.",true)
    end
  end
end
function LF:AddNote(title,body)
  if not self.char or self.readOnly then return end
  title = tostring(title or ""):sub(1,80); body=tostring(body or ""):sub(1,500)
  if title=="" then return end
  local note={id=self.char.nextId, at=now(), title=title, body=body, favorite=false}
  self.char.nextId=self.char.nextId+1
  table.insert(self.char.notes,note)
  self:AddEvent("memory","A Memory Forged",title,true)
  self:CheckGoals(); self:Refresh()
end
function LF:Chronicle()
  local c=self.char; if not c then return "" end
  local zone= c.zone or "Azeroth"
  local count=#c.events
  return "Chapter I - The Journey Continues\n\n"..c.name.." has begun recording a legacy in Azeroth. Across "..tostring(count).." recorded moments, the road has led through "..zone..". Every discovery and milestone adds another page to the story."
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent",function() LF:Boot() end)
SLASH_LIFEFORGE1="/lifeforge"; SLASH_LIFEFORGE2="/lf"
SlashCmdList["LIFEFORGE"] = function(msg)
  msg=(msg or ""):lower():match("^%s*(.-)%s*$")
  if not LF.db then print("LifeForge is initializing."); return end
  if msg=="help" then print("LifeForge: /lf, /lf stats, /lf chronicle, /lf vault, /lf goals, /lf settings, /lf backup")
  elseif msg=="backup" then if LF.ShowBackup then LF:ShowBackup() end
  else LF:Show(msg) end
end
