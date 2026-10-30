local LF=_G.LifeForge
local frame -- no per-frame polling; a single accumulated update every ~5 seconds
local accumulation=0
local function wall()
  return LF:Now()
end
function LF:StartSession()
  local c=self.char
  if not c or self.runtime.readOnly or not self:IsTracking() then return end
  local ts=wall()
  local previous=c.openSession
  -- A /reload within two minutes resumes the same session, never adds another count.
  if type(previous)=="table" and not previous.closed and type(previous.lastTick)=="number"
     and ts>=previous.lastTick and ts-previous.lastTick<=self.config.SESSION_REJOIN then
    previous.lastTick=ts
  else
    -- Rapid reload/re-login: merge into previous logical session instead of double counting.
    local history=c.sessionHistory
    local last=history[#history]
    if last and type(last.ended)=="number" and ts>=last.ended
      and ts-last.ended<=self.config.SESSION_REJOIN then
      c.openSession={id=last.id,started=last.started,lastTick=ts,
        active=last.active,afk=last.afk,closed=false}
      table.remove(history,#history)
    else
      c.stats.sessions=c.stats.sessions+1
      c.openSession={id=self:NextId(c),started=ts,lastTick=ts,active=0,afk=0,closed=false}
      local day=self:Date("%Y-%m-%d")
      c.daily[day]=c.daily[day] or {active=0,afk=0,sessions=0,levels=0}
      c.daily[day].sessions=c.daily[day].sessions+1
    end
  end
  self.runtime.lastClock=self:Clock()
  accumulation=0
end
function LF:CloseSession()
  local c=self.char
  if not c or not c.openSession or c.openSession.closed then return end
  local s=c.openSession
  s.closed=true;s.ended=wall()
  if #c.sessionHistory>=self.config.MAX_SESSIONS then
    table.remove(c.sessionHistory,1) -- bounded raw detail; aggregate stats remain intact
  end
  c.sessionHistory[#c.sessionHistory+1]={id=s.id,started=s.started,ended=s.ended,
    active=s.active or 0,afk=s.afk or 0}
  c.openSession=nil
  c.lastSeen=wall()
  self:RecordSessionRecord(s)
end
function LF:RecordLevel(level)
  local c=self.char
  if not c or self.runtime.readOnly then return end
  level=self:SafeInt(level,c.level,1,1000)
  if level>c.level then
    local previous=c.level;c.level=level
    self:RecordPeakLevel(level)
    if self:IsTracking() then
      c.stats.levelUps=c.stats.levelUps+(level-previous)
      local day=self:Date("%Y-%m-%d")
      c.daily[day]=c.daily[day] or {active=0,afk=0,sessions=0,levels=0}
      c.daily[day].levels=c.daily[day].levels+(level-previous)
      self:Emit("levels","Level "..level.." Reached","Recorded level progression.",true)
      self:CheckGoals();self:UnlockLetters()
    end
  elseif level<c.level then
    -- Do not register a negative level-up after a character service or test realm change.
    c.level=level
  end
end
function LF:RecordMoney(money)
  local c=self.char
  if not c or self.runtime.readOnly or not self:Finite(money) then return end
  money=self:SafeInt(money, c.gold or 0, 0,1e15)
  local diff=money-(c.gold or money)
  if self:IsTracking() then
    c.stats.goldDelta=c.stats.goldDelta+diff
    if diff>0 then c.stats.goldEarned=c.stats.goldEarned+diff
    elseif diff<0 then c.stats.goldSpent=c.stats.goldSpent-diff end
  end
  c.gold=money
  self:RecordPeakGold(money)
end
function LF:RecordZone(zone)
  local c=self.char
  if not c or self.runtime.readOnly then return end
  zone=self:Text(self:Trim(zone or self:SafeCall(_G.GetZoneText)),100)
  if zone=="" then return end
  c.zone=zone
  if self:IsTracking() and not c.zones[zone] then
    c.zones[zone]={firstSeen=wall(),seconds=0}
    self:Emit("zones","A New Horizon","First tracked visit to "..zone..".",true)
    self:CheckGoals()
  end
end
function LF:Tick(seconds,afk)
  if not self.char or not self:IsTracking() or not self.char.openSession then return end
  local c=self.char
  seconds=self:SafeInt(seconds,0,0,self.config.MAX_TICK)
  if seconds==0 then return end
  local active=afk and 0 or seconds
  local idle=afk and seconds or 0
  c.stats.active=c.stats.active+active;c.stats.afk=c.stats.afk+idle
  c.openSession.active=(c.openSession.active or 0)+active
  c.openSession.afk=(c.openSession.afk or 0)+idle
  c.openSession.lastTick=wall()
  c.lastSeen=wall()
  self:RecordDaily(active,idle)
  if c.zone and c.zones[c.zone] then c.zones[c.zone].seconds=c.zones[c.zone].seconds+seconds end
  self:TickCompanions(seconds)
  self:CheckGoals();self:UnlockLetters();self:MonthlySnapshot()
  -- UI refreshes are capped during long sessions; explicit actions still refresh immediately.
  local clock=self:Clock()
  if self.Refresh and (not self.runtime.lastLiveRefresh or clock<self.runtime.lastLiveRefresh or
    clock-self.runtime.lastLiveRefresh>=15) then
    self.runtime.lastLiveRefresh=clock
    self:Refresh()
  end
end
function LF:TrackerEvent(event,...)
  if not self.char or self.runtime.readOnly then return end
  if event=="PLAYER_LEVEL_UP" then
    self:RecordLevel(tonumber((...)) or self:SafeCall(_G.UnitLevel,"player"))
  elseif event=="PLAYER_MONEY" then self:RecordMoney(self:SafeCall(_G.GetMoney))
  elseif event=="ZONE_CHANGED" or event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_ENTERING_WORLD" then
    self:RecordZone()
    if event=="PLAYER_ENTERING_WORLD" then self:UpdateGuild();self:UpdateGroup() end
  elseif event=="GROUP_ROSTER_UPDATE" then self:UpdateGroup()
  elseif event=="PLAYER_GUILD_UPDATE" or event=="GUILD_ROSTER_UPDATE" then self:UpdateGuild()
  elseif event=="PLAYER_FLAGS_CHANGED" then return
  elseif event=="PLAYER_REGEN_ENABLED" then self:FlushNotices();self:UpdateGroup()
  elseif event=="PLAYER_LOGOUT" then self:CloseSession() end
end
function LF:StartTracking()
  if self.runtime.readOnly or not self.char then return end
  self:RecordZone()
  self:UpdateGuild()
  if self:IsTracking() then self:StartSession() end
  if frame then return end
  if type(_G.CreateFrame)~="function" then return end
  frame=_G.CreateFrame("Frame")
  for _,event in ipairs({"PLAYER_LEVEL_UP","PLAYER_MONEY","ZONE_CHANGED","ZONE_CHANGED_NEW_AREA",
    "PLAYER_ENTERING_WORLD","PLAYER_FLAGS_CHANGED","GROUP_ROSTER_UPDATE","PLAYER_GUILD_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_REGEN_ENABLED","PLAYER_LOGOUT"}) do
    -- Unknown Forever beta events must not prevent addon load.
    pcall(frame.RegisterEvent,frame,event)
  end
  frame:SetScript("OnEvent",function(_,event,...) LF:TrackerEvent(event,...) end)
  frame:SetScript("OnUpdate",function(_,elapsed)
    if not LF:IsTracking() then
      if LF.char and LF.char.openSession then LF:CloseSession() end
      accumulation=0; LF.runtime.lastClock=LF:Clock();return
    end
    if not LF.char.openSession then LF:StartSession() end
    accumulation=accumulation+(tonumber(elapsed) or 0)
    if accumulation<LF.config.TICK then return end
    local dt=math.min(LF.config.MAX_TICK,math.floor(accumulation))
    accumulation=0
    LF:Tick(dt, LF:SafeCall(_G.UnitIsAFK,"player")==true)
  end)
end
