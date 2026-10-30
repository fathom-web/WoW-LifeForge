-- Repeatable synthetic storage/serialization stress smoke. NOT a WoW-client benchmark.
local originalPrint=print
print=function() end
-- Reuse real module loaders and actual regression tests to initialize the same addon.
dofile('tests/run.lua')
print=originalPrint
local lf=_G.LifeForge
-- Last test is isolated and leaves a valid local character attached.
local c=lf.char
if not c then error('No test character available') end
local now=lf:Now()
for i=1,3000 do
  local id=lf:NextId(c)
  c.events[#c.events+1]={id=id,at=now-i*3600,kind='zones',
    title='Observed milestone '..i,description='Synthetic test record for pagination',
    zone='The Barrens',favorite=(i%50==0)}
end
for i=1,500 do
  local id=lf:NextId(c)
  c.notes[#c.notes+1]={id=id,at=now-i*3600,updated=now-i*3600,title='Test note '..i,
    body='Synthetic memory '..i,category='Test',zone='Durotar',favorite=(i%10==0)}
end
for i=1,500 do
  c.sessionHistory[i]={id=i,started=now-i*86400,ended=now-i*86400+100,active=90,afk=10}
end
for i=1,600 do
  c.groupHistory[i]={started=now-i*86400,seconds=50,members={'TestRealm:Tester'}}
end
for i=1,100 do
  c.companions['TestRealm:Tester'..i]={firstSeen=now-i*60,lastSeen=now,seconds=3600,groupSessions=1,bondTier=0}
  c.zones['SyntheticZone'..i]={firstSeen=now-i*60,seconds=3600}
end
for i=1,360 do
  c.daily[os.date('%Y-%m-%d',now-i*86400)]={active=500,afk=60,sessions=1,levels=0}
end
local start=os.clock()
local valid,reason=lf:ValidateDB(lf.db)
assert(valid,reason)
local timeline=lf:BuildView('timeline','character',lf.key)
assert(#timeline.rows>=3000)
local ok,parts=lf:BuildExport()
assert(ok,parts)
assert(#parts>1)
local batch=lf:NewImport()
for i=#parts,1,-1 do
  local accepted,err=lf:AcceptPart(batch,parts[i])
  assert(accepted,err)
end
local prepared,preview=lf:PrepareImport(batch,'replace')
assert(prepared,preview)
assert(preview.incomingCharacters==1)
local elapsed=os.clock()-start
io.write(string.format('STRESS PASS — 3000 events, 500 notes, 500 sessions, 600 group records, 100 companions, 360 days; %d backup parts; %.3fs CPU (headless)\n',#parts,elapsed))
