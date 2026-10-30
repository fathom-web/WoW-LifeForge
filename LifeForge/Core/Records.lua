-- Personal records are derived from locally observed values; no historical estimates.
local LF=_G.LifeForge
function LF:RecordPeakGold(gold)
  if not self.char or not self:IsTracking() then return end
  local r=self.char.records
  if gold>(r.peakGold or 0) then r.peakGold=gold;r.peakGoldAt=self:Now() end
end
function LF:RecordPeakLevel(level)
  if not self.char or not self:IsTracking() then return end
  local r=self.char.records
  if level>(r.bestLevel or 0) then r.bestLevel=level;r.bestLevelAt=self:Now() end
end
function LF:RecordSessionRecord(session)
  if not self.char or self.runtime.readOnly then return end
  local r=self.char.records
  local active=session.active or 0
  if active>(r.longestSession or 0) then
    r.longestSession=active;r.longestSessionAt=self:Now()
  end
end
function LF:ThenVsNow(c,month)
  c=c or self.char
  if not c or not c.snapshots[month] then return nil,"No snapshot available" end
  local s=c.snapshots[month]
  return {month=month,level=(c.level or 0)-(s.level or 0),gold=(c.gold or 0)-(s.gold or 0),
    active=(c.stats.active or 0)-(s.active or 0),
    zones=self:Count(c.zones)-(s.zones or 0),companions=self:Count(c.companions)-(s.companions or 0)}
end
