local LF=_G.LifeForge
-- LF2 is a deliberately non-executable format: no loadstring, code evaluation, or remote access.
local MAX_RAW=6000000   -- bounded for addon memory; for larger archives copy the WTF SavedVariables file.
local MAX_PARTS=4096
local PART_SIZE=3200
local MAX_NODES=220000
local function encode(value, depth, state)
  depth=depth or 0
  if depth>24 then error("Excessive nesting") end
  state.nodes=state.nodes+1;if state.nodes>MAX_NODES then error("Too many data nodes") end
  local kind=type(value)
  if kind=="nil" then return "Z" end
  if kind=="boolean" then return value and "B1" or "B0" end
  if kind=="number" then
    if not LF:Finite(value) then error("Non-finite number") end
    local s=tostring(value);return "N"..#s..":"..s
  end
  if kind=="string" then
    if #value>50000 then error("Oversized string") end
    return "S"..#value..":"..value
  end
  if kind=="table" then
    if state.seen[value] then error("Cyclic table") end
    state.seen[value]=true
    local keys=LF:Keys(value)
    if #keys>200000 then error("Oversized table") end
    local items={}
    for _,key in ipairs(keys) do
      if type(key)~="string" and type(key)~="number" then error("Unsupported key") end
      items[#items+1]=encode(key,depth+1,state)
      items[#items+1]=encode(value[key],depth+1,state)
    end
    state.seen[value]=nil
    return "T"..#keys..":"..table.concat(items)
  end
  error("Unsupported type: "..kind)
end
local function decode(source)
  local pos=1;local nodes=0
  local function parse(depth)
    if depth>24 then error("Too deeply nested") end
    nodes=nodes+1; if nodes>MAX_NODES then error("Too many nodes") end
    local marker=source:sub(pos,pos);pos=pos+1
    if marker=="Z" then return nil end
    if marker=="B" then
      local v=source:sub(pos,pos);pos=pos+1
      if v~="0" and v~="1" then error("Invalid boolean") end
      return v=="1"
    end
    if marker~="N" and marker~="S" and marker~="T" then error("Invalid field type") end
    local sep=source:find(":",pos,true)
    if not sep or sep-pos>8 or sep==pos then error("Invalid length field") end
    local lengthText=source:sub(pos,sep-1)
    if not lengthText:match("^%d+$") then error("Invalid field length") end
    local length=tonumber(lengthText)
    if not length or length>MAX_NODES then error("Length exceeds limits") end
    pos=sep+1
    if marker=="T" then
      local result={}
      for _=1,length do
        local key=parse(depth+1)
        if type(key)~="string" and type(key)~="number" then error("Invalid table key") end
        if result[key]~=nil then error("Duplicate table key") end
        local v=parse(depth+1)
        if v==nil then error("Invalid nil table value") end
        result[key]=v
      end
      return result
    end
    if length>50000 or pos+length-1>#source then error("Truncated/oversized scalar") end
    local raw=source:sub(pos,pos+length-1);pos=pos+length
    if marker=="S" then return raw end
    if #raw>48 or not raw:match("^[%d%.%+%-%eE]+$") then error("Malformed number") end
    local n=tonumber(raw)
    if not LF:Finite(n) then error("Non-finite number") end
    return n
  end
  local result=parse(0)
  if pos~=#source+1 then error("Trailing data") end
  return result
end
local ALPHABET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64encode(s)
  local output={}
  for i=1,#s,3 do
    local a,b,c=s:byte(i,i+2)
    local n=a*65536+(b or 0)*256+(c or 0)
    local a1=math.floor(n/262144)%64+1
    local a2=math.floor(n/4096)%64+1
    local a3=math.floor(n/64)%64+1
    local a4=n%64+1
    output[#output+1]=ALPHABET:sub(a1,a1)..ALPHABET:sub(a2,a2)..
      (b and ALPHABET:sub(a3,a3) or "=")..(c and ALPHABET:sub(a4,a4) or "=")
  end
  return table.concat(output)
end
local function b64decode(s)
  if #s%4~=0 or s:find("[^%w%+/%=]") then error("Malformed base64") end
  local lookup={}
  for i=1,#ALPHABET do lookup[ALPHABET:sub(i,i)]=i-1 end
  local result={}
  for i=1,#s,4 do
    local a,b,c,d=s:sub(i,i),s:sub(i+1,i+1),s:sub(i+2,i+2),s:sub(i+3,i+3)
    if not lookup[a] or not lookup[b] or (c~="=" and not lookup[c]) or (d~="=" and not lookup[d]) then error("Invalid base64 quartet") end
    if c=="=" and d~="=" or (c=="=" or d=="=") and i<#s-3 then error("Invalid base64 padding") end
    local n=lookup[a]*262144+lookup[b]*4096+(lookup[c] or 0)*64+(lookup[d] or 0)
    result[#result+1]=string.char(math.floor(n/65536)%256)
    if c~="=" then result[#result+1]=string.char(math.floor(n/256)%256) end
    if d~="=" then result[#result+1]=string.char(n%256) end
  end
  return table.concat(result)
end
local function checksum(s)
  -- Detects accidental corruption, NOT cryptographic authenticity.
  local n=5381
  for i=1,#s do n=(n*33+s:byte(i))%4294967291 end
  return string.format("%08X",n)
end
local function validGeneric(value,depth,counters)
  depth=depth or 0
  if depth>24 then return false,"Nested object too deep" end
  counters.nodes=counters.nodes+1
  if counters.nodes>MAX_NODES then return false,"Too many nodes" end
  local t=type(value)
  if t=="number" then return LF:Finite(value),"Invalid number" end
  if t=="string" then return #value<=50000,"Oversized string" end
  if t=="boolean" then return true end
  if t~="table" then return false,"Unsupported value" end
  for k,v in pairs(value) do
    if type(k)~="string" and type(k)~="number" then return false,"Invalid key" end
    local ok,msg=validGeneric(v,depth+1,counters)
    if not ok then return false,msg end
  end
  return true
end
function LF:ValidateDB(db)
  if type(db)~="table" or db.schema~=self.schema then return false,"Unsupported schema" end
  if type(db.settings)~="table" or type(db.settings.notifications)~="table" or
    type(db.characters)~="table" or type(db.characterOrder)~="table" or type(db.meta)~="table" then
    return false,"Missing database components"
  end
  if type(db.settings.tracking)~="boolean" or type(db.settings.socialTracking)~="boolean" then
    return false,"Invalid tracking preferences"
  end
  if self:Count(db.characters)>300 then return false,"Character limit exceeded" end
  for kind,enabled in pairs(db.settings.notifications) do
    if type(kind)~="string" or #kind>30 or type(enabled)~="boolean" then return false,"Invalid notification preference" end
  end
  if type(db.settings.mutedCompanions)~="table" then return false,"Invalid muted companion list" end
  if not self:Finite(db.settings.scale) or db.settings.scale<0.5 or db.settings.scale>2 then return false,"Invalid UI scale" end
  for key,c in pairs(db.characters) do
    if type(key)~="string" or #key>240 or type(c)~="table" or
      type(c.name)~="string" or type(c.realm)~="string" or
      type(c.stats)~="table" or type(c.events)~="table" or type(c.notes)~="table" or
      type(c.zones)~="table" or type(c.goals)~="table" or
      type(c.companions)~="table" or type(c.snapshots)~="table" or type(c.daily)~="table" or
      type(c.letters)~="table" or type(c.guildHistory)~="table" or
      type(c.groupHistory)~="table" or type(c.sessionHistory)~="table" then
      return false,"Invalid character: "..tostring(key)
    end
    if #c.events>self.config.MAX_EVENTS or #c.notes>self.config.MAX_NOTES or
      #c.sessionHistory>self.config.MAX_SESSIONS or #c.letters>300 or
      self:Count(c.companions)>self.config.MAX_COMPANIONS then return false,"Character data limit exceeded" end
    for _,f in ipairs({"active","afk","sessions","levelUps","goldEarned","goldSpent"}) do
      if not self:Finite(c.stats[f]) or c.stats[f]<0 then return false,"Invalid character stat: "..f end
    end
    if not self:Finite(c.stats.goldDelta) then return false,"Invalid gold delta" end
    if not self:Finite(c.nextId) or c.nextId<1 then return false,"Invalid next ID" end
    if type(c.level)~="number" or not self:Finite(c.level) or c.level<1 or c.level>1000 then return false,"Invalid level" end
    if type(c.gold)~="number" or not self:Finite(c.gold) or c.gold<0 then return false,"Invalid gold" end
    for _,e in ipairs(c.events) do
      if type(e)~="table" or not self:Finite(e.id) or not self:Finite(e.at) or
        type(e.kind)~="string" or type(e.title)~="string" or type(e.description)~="string" or
        type(e.favorite)~="boolean" then return false,"Invalid event" end
    end
    for _,n in ipairs(c.notes) do
      if type(n)=="table" and n.companions~=nil then
        if type(n.companions)~="table" or #n.companions>40 then return false,"Invalid bookmarked companions" end
        for _,person in ipairs(n.companions) do
          if type(person)~="string" or #person>240 then return false,"Invalid bookmarked companion" end
        end
      end
      if type(n)~="table" or not self:Finite(n.id) or type(n.title)~="string" or
        type(n.body)~="string" or type(n.favorite)~="boolean" then return false,"Invalid memory" end
    end
    for id,g in pairs(c.goals) do
      if type(id)~="string" or type(g)~="table" or type(g.title)~="string" or
        not self:Finite(g.target) or not ({time=true,level=true,zones=true,notes=true,companions=true,gold=true})[g.kind] or
        (type(g.completed)~="boolean" and not self:Finite(g.completed)) then
        return false,"Invalid goal" end
    end
    for zone,record in pairs(c.zones) do
      if type(zone)~="string" or type(record)~="table" or not self:Finite(record.seconds) then
        return false,"Invalid zone record" end
    end
    for friend,record in pairs(c.companions) do
      if type(friend)~="string" or type(record)~="table" or not self:Finite(record.seconds) or
        not self:Finite(record.groupSessions) then return false,"Invalid companion record" end
    end
    if c.parties~=nil then
      if type(c.parties)~="table" or self:Count(c.parties)>self.config.MAX_PARTIES then return false,"Invalid parties" end
      for id,party in pairs(c.parties) do
        if type(id)~="string" or #id>1500 or type(party)~="table" or
          type(party.members)~="table" or type(party.name)~="string" or #party.name>80 or
          not self:Finite(party.seconds) or party.seconds<0 or
          not self:Finite(party.sessions) or party.sessions<0 then return false,"Invalid party" end
        for _,member in ipairs(party.members) do if type(member)~="string" or #member>240 then return false,"Invalid party member" end end
      end
    end
    if c.groupHistory~=nil then
      if type(c.groupHistory)~="table" or #c.groupHistory>self.config.MAX_GROUP_HISTORY then return false,"Invalid group history" end
      for _,item in ipairs(c.groupHistory) do
        if type(item)~="table" or type(item.members)~="table" or
          not self:Finite(item.started) or not self:Finite(item.seconds) or item.seconds<0 then return false,"Invalid group session" end
      end
    end
    if c.guildHistory~=nil then
      if type(c.guildHistory)~="table" or #c.guildHistory>self.config.MAX_GUILD_HISTORY then return false,"Invalid guild history" end
      for _,item in ipairs(c.guildHistory) do
        if type(item)~="table" or type(item.guild)~="string" or #item.guild>150 or
          not self:Finite(item.at) or (item.kind~="joined" and item.kind~="left") then return false,"Invalid guild event" end
      end
    end
    if c.records~=nil then
      if type(c.records)~="table" then return false,"Invalid record collection" end
      for _,k in ipairs({"peakGold","bestLevel","longestSession"}) do
        if c.records[k]~=nil and (not self:Finite(c.records[k]) or c.records[k]<0) then return false,"Invalid personal record" end
      end
    end
    for _,l in ipairs(c.letters) do
      if type(l)~="table" or type(l.title)~="string" or type(l.body)~="string" or
        not self:Finite(l.target) or not ({level=true,time=true,date=true})[l.kind] or
        (type(l.opened)~="boolean" and not self:Finite(l.opened)) then return false,"Invalid letter" end
    end
  end
  local ok,msg=validGeneric(db,0,{nodes=0})
  if not ok then return false,msg end
  return true
end
local function splitParts(blob)
  local count=math.ceil(#blob/PART_SIZE)
  if count>MAX_PARTS then error("Too many backup parts; copy SavedVariables on disk instead") end
  local parts={};local digest=checksum(blob)
  for i=1,count do
    local chunk=blob:sub((i-1)*PART_SIZE+1,i*PART_SIZE)
    parts[i]="LF2|"..i.."|"..count.."|"..digest.."|"..chunk
  end
  return parts
end
function LF:BuildExport()
  if not self.db then return false,"No database loaded" end
  local valid,msg=self:ValidateDB(self.db)
  if not valid then return false,"Current database fails validation: "..tostring(msg) end
  local ok,payload=pcall(encode,self.db,0,{nodes=0,seen={}})
  if not ok then return false,"Export refused: "..tostring(payload) end
  if #payload>MAX_RAW then return false,"Database exceeds in-game export limit. Copy the SavedVariables file with WoW closed." end
  local blob=b64encode(payload)
  local success,parts=pcall(splitParts,blob)
  if not success then return false,tostring(parts) end
  self.db.meta.lastExportAt=self:Now()
  return true,parts
end
function LF:NewImport()
  return {pieces={},total=nil,hash=nil,size=0,prepared=nil,mode=nil}
end
function LF:AcceptPart(batch,part)
  if type(batch)~="table" or type(part)~="string" or #part>PART_SIZE+100 then return false,"Invalid part" end
  local index,total,hash,payload=part:match("^LF2|(%d+)|(%d+)|(%x%x%x%x%x%x%x%x)|([%w%+/%=]+)$")
  index=tonumber(index);total=tonumber(total)
  if not index or not total or total<1 or total>MAX_PARTS or index<1 or index>total or
     not payload or #payload>PART_SIZE then return false,"Malformed part header" end
  if batch.total and (batch.total~=total or batch.hash~=hash) then return false,"Backup set mismatch" end
  if batch.pieces[index] then
    if batch.pieces[index]==payload then return true,"Part already received" end
    return false,"Conflicting duplicate part"
  end
  if batch.size+#payload>MAX_RAW*2 then return false,"Import size exceeded" end
  batch.total=total;batch.hash=hash;batch.size=batch.size+#payload
  batch.pieces[index]=payload
  batch.prepared=nil
  return true,"Accepted part "..index.." of "..total
end
function LF:ImportProgress(batch)
  local n=0
  for _ in pairs(batch.pieces or {}) do n=n+1 end
  return n,batch.total or 0
end
function LF:PrepareImport(batch,mode)
  if type(batch)~="table" or not ({merge=true,replace=true})[mode] then return false,"Invalid import mode" end
  local n,total=self:ImportProgress(batch)
  if total==0 or n~=total then return false,"Missing parts: "..n.." / "..total end
  local pieces={}
  for i=1,total do
    if not batch.pieces[i] then return false,"Part "..i.." missing" end
    pieces[#pieces+1]=batch.pieces[i]
  end
  local blob=table.concat(pieces)
  if checksum(blob)~=batch.hash then return false,"Checksum mismatch" end
  local ok,decoded=pcall(function()
    local raw=b64decode(blob)
    if #raw>MAX_RAW then error("Raw payload exceeds limit") end
    return decode(raw)
  end)
  if not ok then return false,"Could not decode backup: "..tostring(decoded) end
  local valid,msg=self:ValidateDB(decoded)
  if not valid then return false,"Unsafe backup rejected: "..tostring(msg) end
  local keys=self:Count(decoded.characters)
  local conflicts,new=0,0
  for key in pairs(decoded.characters) do
    if self.db.characters[key] then conflicts=conflicts+1 else new=new+1 end
  end
  batch.prepared=decoded;batch.mode=mode
  return true,{incomingCharacters=keys,newCharacters=new,existingCharacters=conflicts,
    currentCharacters=self:Count(self.db.characters),mode=mode,
    message=mode=="merge" and "Existing local characters remain untouched; new characters are added. No counters are summed." or
      "Entire account database will be replaced after confirmation and a reload."}
end
function LF:CommitImport(batch,confirmed)
  if confirmed~=true then return false,"Explicit confirmation required" end
  if self.runtime.readOnly then return false,"Database is read-only" end
  if not batch or not batch.prepared or not batch.mode then return false,"Preview import before committing" end
  local valid,msg=self:ValidateDB(batch.prepared)
  if not valid then return false,msg end
  local result
  if batch.mode=="replace" then
    result=self:DeepCopy(batch.prepared)
  else
    result=self:DeepCopy(self.db)
    for key,c in pairs(batch.prepared.characters) do
      if result.characters[key]==nil then
        result.characters[key]=self:DeepCopy(c)
        result.characterOrder[#result.characterOrder+1]=key
      end
    end
  end
  local good,problem=self:ValidateDB(result)
  if not good then return false,"Result invalid: "..tostring(problem) end
  -- Commit staged only: don't mutate the active runtime; reload is required for activation.
  _G.LifeForgeDB=result
  self.runtime.restorePending=true
  batch.prepared=nil
  return true,"Restore staged safely. Type /reload to activate. Do not continue tracking before reloading."
end
LF.BackupInternals={encode=encode,decode=decode,checksum=checksum,b64encode=b64encode,b64decode=b64decode}
