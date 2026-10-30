local LF=_G.LifeForge
function LF:AddNote(title,body,category)
  if not self:IsTracking() or not self.char then return false,"Tracking disabled" end
  title=self:Trim(title);body=type(body)=="string" and body or ""
  if title=="" or #title>100 or #body>3000 then return false,"Note title/body size invalid" end
  if #self.char.notes>=self.config.MAX_NOTES then return false,"Note limit reached" end
  local c=self.char
  local note={id=self:NextId(c),at=self:Now(),updated=self:Now(),title=title,
    body=body,category=self:Text(category or "Personal Memory",50),favorite=false,
    zone=self:Text(c.zone or "",100),guild=self:Text(c.guild or "",150),companions=self:GetObservedCompanionKeys()}
  c.notes[#c.notes+1]=note
  self:Emit("memories","A Memory Forged",title,true)
  self:CheckGoals()
  return true,note.id
end
function LF:FindNote(id)
  if not self.char then return nil end
  for i,n in ipairs(self.char.notes) do if n.id==id then return n,i end end
end
function LF:EditNote(id,title,body)
  if self.runtime.readOnly then return false,"Read-only mode" end
  local n=self:FindNote(id)
  if not n then return false,"Missing note" end
  title=self:Trim(title)
  if title=="" or #title>100 or type(body)~="string" or #body>3000 then
    return false,"Invalid text"
  end
  n.title=title;n.body=body;n.updated=self:Now();return true
end
function LF:FavoriteNote(id,value)
  if self.runtime.readOnly then return false,"Read-only mode" end
  local n=self:FindNote(id)
  if not n then return false,"Missing note" end
  n.favorite=value==true;return true
end
function LF:DeleteNote(id,confirmed)
  if self.runtime.readOnly then return false,"Read-only mode" end
  if confirmed~=true then return false,"Explicit confirmation required" end
  local n,i=self:FindNote(id)
  if not i then return false,"Missing note" end
  table.remove(self.char.notes,i);return true
end
-- A sealed letter may unlock at a level, after N hours, or on a local calendar date.
-- The string editor uses: level:60 | hours:100 | date:2027-01-01.
-- Date targets use YYYYMMDD, avoiding timezone-dependent midnight calculations.
function LF:ParseLetterTrigger(spec)
  if type(spec)~="string" then return false,"Unlock condition must be text" end
  local kind,value=spec:match("^%s*(%a+)%s*:%s*(.-)%s*$")
  if not kind then return false,"Use level:60, hours:100 or date:2027-01-01" end
  kind=kind:lower()
  if kind=="level" or kind=="hours" then
    if not value:match("^%d+$") then return false,"Enter a positive whole number" end
    local target=tonumber(value)
    if not target or target<1 or target>1000000 then return false,"Unlock target out of range" end
    return true,kind=="hours" and "time" or "level",kind=="hours" and target*3600 or target
  end
  if kind=="date" then
    local y,m,d=value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    y=tonumber(y);m=tonumber(m);d=tonumber(d)
    if not y or y<2000 or y>9999 or m<1 or m>12 then return false,"Invalid calendar date" end
    local days={31,28,31,30,31,30,31,31,30,31,30,31}
    if m==2 and y%4==0 and (y%100~=0 or y%400==0) then days[2]=29 end
    if d<1 or d>days[m] then return false,"Invalid calendar date" end
    return true,"date",y*10000+m*100+d
  end
  return false,"Use level, hours or date"
end
function LF:LetterTriggerLabel(letter)
  if letter.kind=="level" then return "level "..tostring(letter.target) end
  if letter.kind=="time" then return tostring(math.floor(letter.target/3600)).." tracked hours" end
  if letter.kind=="date" and letter.target<100000000 then
    local s=tostring(letter.target)
    return s:sub(1,4).."-"..s:sub(5,6).."-"..s:sub(7,8)
  end
  return "date "..self:Date("%Y-%m-%d",letter.target)
end
function LF:AddFutureLetter(title,body,kind,target)
  if not self:IsTracking() or not self.char then return false,"Tracking disabled" end
  if not ({level=true,time=true,date=true})[kind] then return false,"Invalid unlock condition" end
  if type(title)~="string" or #title<1 or #title>100 or type(body)~="string" or #body<1 or #body>2000 then
    return false,"Invalid letter"
  end
  if not self:Finite(target) or target<1 or target>1e12 then return false,"Invalid target" end
  local c=self.char
  -- A letter is meant for a future version of the player, not immediate delivery.
  local progress=kind=="level" and c.level or kind=="time" and c.stats.active or
    (target<100000000 and tonumber(self:Date("%Y%m%d",self:Now())) or self:Now())
  if target<=progress then return false,"Choose a future milestone" end
  if #c.letters>=300 then return false,"Letter limit reached" end
  local l={id=self:NextId(c),title=title,body=body,kind=kind,target=target,at=self:Now(),opened=false}
  c.letters[#c.letters+1]=l
  return true,l.id
end
function LF:UnlockLetters()
  if not self:IsTracking() or not self.char then return end
  local c=self.char
  for _,l in ipairs(c.letters) do
    local value=l.kind=="level" and c.level or l.kind=="time" and c.stats.active or
      (l.target<100000000 and tonumber(self:Date("%Y%m%d",self:Now())) or self:Now())
    if l.opened==false and value>=l.target then
      l.opened=self:Now();self:Emit("memories","A Letter From Your Past",l.title,true)
    end
  end
end
