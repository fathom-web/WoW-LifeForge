local addonName, ns = ...
ns = ns or {}
_G.LifeForge = ns
ns.name = addonName or "LifeForge"
ns.version = "1.0.0"
ns.schema = 2
ns.config = { MAX_EVENTS=6000, MAX_NOTES=1500, MAX_SESSIONS=600, MAX_DAYS=5000,
  MAX_COMPANIONS=1500, MAX_SNAPSHOTS=360, MAX_PARTIES=300, MAX_GROUP_HISTORY=800, MAX_GUILD_HISTORY=300, TICK=5, MAX_TICK=30, SESSION_REJOIN=120 }
ns.modules = {}
function ns:L(key)
  local tbl=self.Locale or {}
  return tbl[key] or tostring(key)
end
ns.runtime = { booted=false, pendingNotices={}, warnings={} }
function ns:Now()
  if type(_G.time)=="function" then return _G.time() end
  return os.time()
end
function ns:Clock()
  if type(_G.GetTime)=="function" then return _G.GetTime() end
  return os.clock()
end
function ns:Date(fmt, stamp)
  if type(_G.date)=="function" then return _G.date(fmt, stamp or self:Now()) end
  return os.date(fmt, stamp or self:Now())
end
function ns:Log(message)
  local s = "|cffe6bd79LifeForge|r: "..tostring(message)
  if type(_G.print)=="function" then _G.print(s) end
end
function ns:IsCombat()
  if type(_G.InCombatLockdown)~="function" then return false end
  local ok, locked=pcall(_G.InCombatLockdown)
  return ok and locked == true
end
function ns:SafeCall(fn, ...)
  if type(fn)~="function" then return nil end
  local ok, a,b,c,d = pcall(fn, ...)
  if ok then return a,b,c,d end
  return nil
end