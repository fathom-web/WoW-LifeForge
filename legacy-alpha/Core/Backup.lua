local LF=_G.LifeForge
-- Simple length-delimited ASCII serializer. No loadstring or executable code on import.
-- Fields are encoded as records with explicit typed prefixes and bounded recursion.
local function encode(value,depth)
 depth=depth or 0
 if depth>16 then error("Maximum backup depth exceeded") end
 local ty=type(value)
 if ty=="nil" then return "Z" end
 if ty=="boolean" then return value and "B1" or "B0" end
 if ty=="number" then local s=tostring(value); return "N"..#s..":"..s end
 if ty=="string" then return "S"..#value..":"..value end
 if ty=="table" then
  local entries={}; local n=0
  for k,v in pairs(value) do
   if type(k)=="string" or type(k)=="number" then
    entries[#entries+1]=encode(k,depth+1)..encode(v,depth+1); n=n+1
    if n>10000 then error("Too many table entries") end
   end
  end
  return "T"..n..":"..table.concat(entries)
 end
 error("Unsupported value")
end
local function decode(s)
 local p=1; local nodes=0
 local function parse(depth)
  depth=depth or 0; nodes=nodes+1
  if depth>16 or nodes>60000 then error("Backup exceeds limits") end
  local tag=s:sub(p,p); p=p+1
  if tag=="Z" then return nil end
  if tag=="B" then local v=s:sub(p,p);p=p+1;if v~="0" and v~="1" then error("Invalid boolean") end;return v=="1" end
  local colon=s:find(":",p,true); if not colon or colon-p>8 then error("Invalid length") end
  local len=tonumber(s:sub(p,colon-1)); if not len or len<0 or len>2000000 then error("Invalid size") end
  p=colon+1
  if tag=="N" or tag=="S" then
   if p+len-1>#s then error("Truncated field") end
   local raw=s:sub(p,p+len-1);p=p+len
   if tag=="N" then local n=tonumber(raw);if not n then error("Invalid number") end;return n end
   return raw
  end
  if tag=="T" then
   if len>10000 then error("Too many entries") end
   local t={}
   for i=1,len do local k=parse(depth+1);local v=parse(depth+1);if k~=nil and type(k)~="table" then t[k]=v end end
   return t
  end
  error("Unknown field type")
 end
 local result=parse(0)
 if p<=#s then error("Unexpected trailing data") end
 return result
end
local function checksum(s)
 local n=0
 for i=1,#s do n=(n*33+s:byte(i))%4294967291 end
 return string.format("%08X",n)
end
function LF:Export()
 local payload=encode(self.db)
 return "LF1:"..checksum(payload)..":"..payload
end
function LF:Import(data)
 if not data or #data>1800000 then return false,"Backup too large or empty" end
 local hash,payload=data:match("^LF1:(%x%x%x%x%x%x%x%x):(.*)$")
 if not hash then return false,"Invalid LifeForge backup header" end
 if checksum(payload)~=hash then return false,"Checksum mismatch; import cancelled" end
 local ok, result=pcall(decode,payload)
 if not ok or type(result)~="table" or type(result.characters)~="table" or type(result.settings)~="table" then return false,"Invalid backup structure" end
 if type(result.schema)~="number" or result.schema>self.schema or result.schema<1 then return false,"Unsupported backup version" end
 for k,c in pairs(result.characters) do
  if type(k)~="string" or type(c)~="table" or type(c.stats)~="table" or type(c.events)~="table" or type(c.notes)~="table" or type(c.zones)~="table" then return false,"Invalid character data" end
 end
 -- Restore as a complete replacement, not an implicit merge; reload to reinitialize safely.
 LifeForgeDB=result
 return true,"Backup accepted. Type /reload to activate restored data."
end
