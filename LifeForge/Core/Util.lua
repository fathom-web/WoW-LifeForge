local LF = _G.LifeForge
function LF:Finite(n)
  return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
function LF:SafeInt(n, fallback, low, high)
  if not self:Finite(n) then return fallback or 0 end
  n=math.floor(n)
  if low and n<low then return low end
  if high and n>high then return high end
  return n
end
function LF:Text(s, maxLen)
  if type(s)~="string" then return "" end
  return s:sub(1,maxLen or 300)
end
function LF:DeepCopy(obj, depth, seen)
  if type(obj)~="table" then return obj end
  depth=depth or 0;seen=seen or {}
  if depth>40 or seen[obj] then error("Cycle or excessive depth") end
  seen[obj]=true
  local result={}
  for k,v in pairs(obj) do result[self:DeepCopy(k, depth+1, seen)]=self:DeepCopy(v, depth+1, seen) end
  seen[obj]=nil
  return result
end
function LF:Count(t)
  local n=0; if type(t)=="table" then for _ in pairs(t) do n=n+1 end end
  return n
end
function LF:Keys(t)
  local out={}
  if type(t)=="table" then for k in pairs(t) do out[#out+1]=k end end
  table.sort(out,function(a,b) return tostring(a)<tostring(b) end)
  return out
end
function LF:Trim(s)
  return type(s)=="string" and s:match("^%s*(.-)%s*$") or ""
end
function LF:CharacterKey(realm, name)
  if type(realm)~="string" or realm=="" or type(name)~="string" or name=="" then return nil end
  return realm..":"..name
end
function LF:IsTracking()
  return not self.runtime.readOnly and not self.runtime.restorePending and self.db and self.db.settings and self.db.settings.tracking==true
end
