local LF=_G.LifeForge
-- Prose is generated from recorded facts, never invented dungeon clears or boss kills.
function LF:Chronicle(c)
  c=c or self.char
  if not c then return "No character selected." end
  local latest=c.events[#c.events]
  if not latest then return "Your adventure begins with the first moment LifeForge records." end
  local name=self:Text(c.name,64)
  if latest.kind=="zones" then
    return name.." continued the journey into "..self:Text(latest.zone~="" and latest.zone or "a new land",80)..". Another page was added to the chronicle."
  elseif latest.kind=="levels" then
    return "A new milestone for "..name..": "..self:Text(latest.title,100)..". The journey continues."
  elseif latest.kind=="companions" then
    return "The bonds formed on the road grew stronger. "..self:Text(latest.description,220)
  elseif latest.kind=="goals" then
    return name.." fulfilled a personal ambition: "..self:Text(latest.title,100).."."
  end
  return name.." has "..tostring(#c.events).." recorded moments. The latest: "..self:Text(latest.title,100).."."
end

-- Deterministic story chapters assembled from actual timestamps and milestone titles.
-- No AI, server, invented dungeons, or inferred pre-installation history.
function LF:ChronicleChapters(c)
  c=c or self.char
  if not c then return {} end
  local months,order={},{}
  for _,e in ipairs(c.events or {}) do
    if type(e.at)=="number" and type(e.title)=="string" then
      local month=self:Date("%Y-%m",e.at)
      if not months[month] then
        months[month]={month=month,events={},first=e.at}
        order[#order+1]=month
      end
      months[month].events[#months[month].events+1]=e
    end
  end
  table.sort(order)
  local chapters={}
  for index,month in ipairs(order) do
    local chapter=months[month]
    table.sort(chapter.events,function(a,b)
      if a.at==b.at then return a.id<b.id end
      return a.at<b.at
    end)
    local highlights={}
    for i=#chapter.events,math.max(1,#chapter.events-3),-1 do
      highlights[#highlights+1]=self:Text(chapter.events[i].title,90)
    end
    local kinds={}
    for _,e in ipairs(chapter.events) do kinds[e.kind]=(kinds[e.kind] or 0)+1 end
    local moments={}
    if (kinds.levels or 0)>0 then moments[#moments+1]=tostring(kinds.levels)..' level milestone(s)' end
    if (kinds.zones or 0)>0 then moments[#moments+1]=tostring(kinds.zones)..' first tracked zone(s)' end
    if (kinds.companions or 0)>0 then moments[#moments+1]=tostring(kinds.companions)..' companion milestone(s)' end
    if (kinds.goals or 0)>0 then moments[#moments+1]=tostring(kinds.goals)..' completed goal(s)' end
    if (kinds.memories or 0)>0 then moments[#moments+1]=tostring(kinds.memories)..' remembered moment(s)' end
    chapter.title="Chapter "..tostring(index).." — "..self:Date("%B %Y",chapter.first)
    chapter.summary=self:Text(c.name or 'Your character',64)..' recorded '..tostring(#chapter.events)..
      ' moment(s) this month'..(#moments>0 and (': '..table.concat(moments,', ')) or '')..'. Highlights: '..
      table.concat(highlights,'; ')..'.' 
    chapter.count=#chapter.events
    chapters[#chapters+1]=chapter
  end
  return chapters
end
