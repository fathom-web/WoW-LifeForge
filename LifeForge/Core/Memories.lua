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
function LF:AddFutureLetter(title,body,kind,target)
  if not self:IsTracking() or not self.char then return false,"Tracking disabled" end
  if not ({level=true,time=true,date=true})[kind] then return false,"Invalid unlock condition" end
  if type(title)~="string" or #title<1 or #title>100 or type(body)~="string" or #body<1 or #body>2000 then
    return false,"Invalid letter"
  end
  if not self:Finite(target) or target<1 or target>1e12 then return false,"Invalid target" end
  local c=self.char
  if #c.letters>=300 then return false,"Letter limit reached" end
  local l={id=self:NextId(c),title=title,body=body,kind=kind,target=target,at=self:Now(),opened=false}
  c.letters[#c.letters+1]=l
  return true,l.id
end
function LF:UnlockLetters()
  if not self:IsTracking() or not self.char then return end
  local c=self.char
  for _,l in ipairs(c.letters) do
    local value=l.kind=="level" and c.level or l.kind=="time" and c.stats.active or self:Now()
    if l.opened==false and value>=l.target then
      l.opened=self:Now();self:Emit("memories","A Letter From Your Past",l.title,true)
    end
  end
end
