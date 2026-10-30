-- Build 7. Data-driven tier achievements; counts reflect only events observed since installation.
local LF=_G.LifeForge
LF.milestoneTiers = {
  {kind='time', unit=3600, thresholds={1,10,50,100,250,500}, label='Hours Adventured'},
  {kind='zones', thresholds={5,10,25,50,100}, label='Horizons Discovered'},
  {kind='notes', thresholds={5,10,25,50,100}, label='Memories Preserved'},
  {kind='companions', thresholds={5,10,25,50}, label='Companions Encountered'},
  {kind='levelUps', thresholds={5,10,25,50,100}, label='Levels Gained'},
}
function LF:MilestoneProgress(c,kind)
  if kind=='time' then return math.max(0,c.stats.active or 0)/3600 end
  if kind=='zones' then return self:Count(c.zones) end
  if kind=='notes' then return #(c.notes or {}) end
  if kind=='companions' then return self:Count(c.companions) end
  if kind=='levelUps' then return c.stats.levelUps or 0 end
  return 0
end
function LF:MilestoneCatalog(c)
  local result={}
  for _,tier in ipairs(self.milestoneTiers) do
    local value=self:MilestoneProgress(c,tier.kind)
    for index,threshold in ipairs(tier.thresholds) do
      local id=tier.kind..'-'..threshold
      result[#result+1]={id=id,kind=tier.kind,target=threshold,label=tier.label,
        current=value,achieved=c.milestones and c.milestones[id] or nil,
        tier=index==#tier.thresholds and 'legendary' or index>=3 and 'epic' or 'standard'}
    end
  end
  return result
end
function LF:CheckMilestones()
  if not self.char or not self:IsTracking() or self.runtime.readOnly or self.runtime.restorePending then return end
  local c=self.char
  c.milestones=c.milestones or {}
  for _,milestone in ipairs(self:MilestoneCatalog(c)) do
    if milestone.current>=milestone.target and not c.milestones[milestone.id] then
      c.milestones[milestone.id]=self:Now()
      self:Emit('records','Legacy Milestone: '..milestone.label,
        'Reached '..milestone.target..' '..milestone.label:lower()..' since LifeForge began tracking.',
        milestone.tier=='legendary')
    end
  end
end