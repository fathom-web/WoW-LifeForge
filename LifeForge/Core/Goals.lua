local LF=_G.LifeForge
LF.goalPresets={
  {id="time10",title="A Life in Azeroth",kind="time",target=36000},
  {id="time50",title="The Veteran",kind="time",target=180000},
  {id="zones10",title="The Explorer",kind="zones",target=10},
  {id="level40",title="Road to Forty",kind="level",target=40},
  {id="notes5",title="Keeper of Memories",kind="notes",target=5},
  {id="companions5",title="United We Stand",kind="companions",target=5},
}
function LF:SeedGoals(c)
  for _,p in ipairs(self.goalPresets) do
    if not c.goals[p.id] then
      c.goals[p.id]={id=p.id,title=p.title,kind=p.kind,target=p.target,completed=false,preset=true}
    end
  end
end
function LF:GoalProgress(c,g)
  if g.kind=="time" then return c.stats.active or 0 end
  if g.kind=="level" then return c.level or 1 end
  if g.kind=="zones" then return self:Count(c.zones) end
  if g.kind=="notes" then return #c.notes end
  if g.kind=="companions" then return self:Count(c.companions) end
  if g.kind=="gold" then return c.gold or 0 end
  return 0
end
function LF:AddGoal(title,kind,target)
  if not self:IsTracking() or not self.char then return false,"Tracking disabled" end
  if not ({time=true,level=true,zones=true,notes=true,companions=true,gold=true})[kind] then
    return false,"Unsupported goal kind"
  end
  if type(title)~="string" or self:Trim(title)=="" or #title>100 then return false,"Invalid goal title" end
  if not self:Finite(target) or target<1 or target>1e12 then return false,"Invalid target" end
  local c=self.char
  if self:Count(c.goals)>=200 then return false,"Goal limit reached" end
  local id="custom-"..tostring(self:NextId(c))
  c.goals[id]={id=id,title=title,kind=kind,target=math.floor(target),completed=false,preset=false}
  return true,id
end
function LF:CheckGoals()
  if not self:IsTracking() or not self.char then return end
  local c=self.char
  for _,g in pairs(c.goals) do
    if not g.hidden and g.completed==false and self:GoalProgress(c,g)>=g.target then
      g.completed=self:Now()
      self:Emit("goals","Goal Complete: "..g.title,"Your recorded progress reached its target.",true)
    end
  end
end
