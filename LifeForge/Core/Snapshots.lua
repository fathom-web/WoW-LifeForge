local LF=_G.LifeForge
function LF:RecordDaily(active,afk)
  local c=self.char
  if not c or not self:IsTracking() then return end
  local day=self:Date("%Y-%m-%d")
  local d=c.daily[day]
  if not d then
    if self:Count(c.daily)>=self.config.MAX_DAYS then return end
    d={active=0,afk=0,sessions=0,levels=0};c.daily[day]=d
  end
  d.active=d.active+active;d.afk=d.afk+afk
end
function LF:MonthlySnapshot()
  if not self.char or not self:IsTracking() then return end
  local c=self.char
  local month=self:Date("%Y-%m")
  if c.snapshots[month] then return end
  if self:Count(c.snapshots)>=self.config.MAX_SNAPSHOTS then return end
  c.snapshots[month]={at=self:Now(),level=c.level,gold=c.gold,active=c.stats.active,
    zones=self:Count(c.zones),companions=self:Count(c.companions),notes=#c.notes}
end
