local LF=_G.LifeForge
local tracker=CreateFrame("Frame")
local elapsed=0
function LF:StartTracking()
 if self.readOnly or not self.char then return end
 self.char.stats.sessions=(self.char.stats.sessions or 0)+1
 self.char.sessionStarted=self:Now()
 tracker:RegisterEvent("PLAYER_LEVEL_UP")
 tracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
 tracker:RegisterEvent("ZONE_CHANGED")
 tracker:RegisterEvent("PLAYER_MONEY")
 tracker:RegisterEvent("PLAYER_LOGOUT")
 tracker:RegisterEvent("PLAYER_ENTERING_WORLD")
 self:RecordZone()
end
function LF:RecordZone()
 local c=self.char; if not c then return end
 local zone=GetZoneText() or ""
 if zone=="" then return end
 c.zone=zone
 if not c.zones[zone] then
  c.zones[zone]={firstSeen=self:Now(),seconds=0}
  if self.db.settings.tracking then self:AddEvent("zones","A New Horizon","First recorded visit to "..zone..".",true) end
 end
 self:CheckGoals()
end
tracker:SetScript("OnEvent",function(_,event,...)
 local c=LF.char; if not c or LF.readOnly then return end
 if event=="PLAYER_LEVEL_UP" then
  local level=tonumber(...) or UnitLevel("player") or c.level
  if level>c.level then
    c.stats.levelUps=(c.stats.levelUps or 0)+(level-c.level)
    c.level=level
    if LF.db.settings.tracking then LF:AddEvent("levels","Level "..level.." Reached","Another step in your adventure.",true) end
  end
  LF:CheckGoals()
 elseif event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED" or event=="PLAYER_ENTERING_WORLD" then LF:RecordZone()
 elseif event=="PLAYER_MONEY" then
  local money=GetMoney() or 0
  if LF.db.settings.tracking then c.stats.goldDelta=(c.stats.goldDelta or 0)+(money-(c.gold or money)) end
  c.gold=money
 elseif event=="PLAYER_LOGOUT" then
  c.lastSeen=LF:Now()
 end
 if LF.Refresh then LF:Refresh() end
end)
tracker:SetScript("OnUpdate",function(_,dt)
 if not LF.char or LF.readOnly or not LF.db.settings.tracking then return end
 elapsed=elapsed+dt
 if elapsed<5 then return end
 local seconds=math.floor(elapsed); elapsed=elapsed-seconds
 local c=LF.char; local afk=UnitIsAFK("player")
 if afk then c.stats.afk=(c.stats.afk or 0)+seconds else c.stats.active=(c.stats.active or 0)+seconds end
 local zone=c.zone
 if zone and c.zones[zone] then c.zones[zone].seconds=(c.zones[zone].seconds or 0)+seconds end
 c.lastSeen=LF:Now()
 LF:CheckGoals()
 if LF.Refresh then LF:Refresh() end
end)
