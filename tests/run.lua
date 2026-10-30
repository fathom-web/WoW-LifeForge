-- Headless automated Lua tests; no WoW client needed. Run: lua5.4 tests/run.lua
local src="LifeForge/"
local files={"Locales/enUS.lua","Core/Bootstrap.lua","Core/Util.lua","Core/Database.lua",
  "Core/Events.lua","Core/Character.lua","Core/Chronicle.lua","Core/Goals.lua",
  "Core/Memories.lua","Core/Snapshots.lua","Core/Tracking.lua","Core/Social.lua","Core/Guild.lua","Core/Records.lua",
  "Core/Backup.lua","Core/Management.lua","Core/Experience.lua","UI/ViewModel.lua","UI/Main.lua","UI/Experience.lua","UI/BackupWindow.lua","Core/Commands.lua"}
local now=1793294000
local zone="Durotar"
local money=15000
local realm="ForeverRealm"
local name="Garvok"
local level=12
local activeTests=0
local function assertEq(actual,expected,message)
  if actual~=expected then
    error((message or "Assertion failed")..": expected "..tostring(expected).." got "..tostring(actual),2)
  end
end
local function loadAddon(existing)
  _G.LifeForgeDB=existing
  _G.CreateFrame=nil
  _G.time=function() return now end
  _G.date=os.date
  _G.UnitName=function()return name end
  _G.GetRealmName=function()return realm end
  _G.GetNormalizedRealmName=function()return realm end
  _G.UnitClass=function() return "Warrior","WARRIOR" end
  _G.UnitRace=function() return "Orc","Orc" end
  _G.UnitFactionGroup=function()return "Horde" end
  _G.UnitLevel=function()return level end
  _G.GetMoney=function()return money end
  _G.GetZoneText=function()return zone end
  _G.UnitIsAFK=function()return false end
  _G.GetNumGroupMembers=nil
  _G.IsInRaid=nil
  _G.UnitIsUnit=nil
  _G.InCombatLockdown=function()return false end
  _G.SlashCmdList={}
  local ns={}
  for _,path in ipairs(files) do
    local chunk,err=loadfile(src..path)
    if not chunk then error(err) end
    chunk("LifeForge",ns)
  end
  return ns
end
local function test(title,fn)
  local ok,err=pcall(fn)
  if not ok then io.stderr:write("FAIL "..title.." :: "..tostring(err).."\n");os.exit(1) end
  activeTests=activeTests+1
  io.write("PASS "..title.."\n")
end
local LF

test("Fresh boot creates per-character account database",function()
  LF=loadAddon()
  assertEq(LF:Boot(),true)
  assertEq(LF.db.schema,2)
  assertEq(LF:Count(LF.db.characters),1)
  assertEq(LF.char.name,"Garvok")
  assertEq(LF.db.settings.tracking,true)
  assertEq(#LF.char.events,2) -- start and first zone
  assertEq(LF.char.stats.sessions,1)
  assertEq(LF:Count(LF.char.goals),6)
end)

test("Sessions, AFK, level, zone, money and time counters",function()
  LF:Tick(5,false);LF:Tick(5,true)
  assertEq(LF.char.stats.active,5)
  assertEq(LF.char.stats.afk,5)
  assertEq(LF.char.zones.Durotar.seconds,10)
  LF:RecordLevel(13);LF:RecordLevel(13)
  assertEq(LF.char.stats.levelUps,1)
  LF:RecordMoney(21000);LF:RecordMoney(17000)
  assertEq(LF.char.stats.goldDelta,2000)
  assertEq(LF.char.stats.goldEarned,6000)
  assertEq(LF.char.stats.goldSpent,4000)
  LF:RecordZone("The Barrens");LF:RecordZone("The Barrens")
  assertEq(LF:Count(LF.char.zones),2)
  assertEq(LF:Totals("character").active,5)
end)

test("Custom goals, notes, future letters and chronological facts",function()
  assertEq(LF:AddNote("First adventure","We explored the Barrens"),true)
  local ok,id=LF:AddGoal("Hit 14","level",14)
  assertEq(ok,true)
  local valid,letterId=LF:AddFutureLetter("For future me","Remember today","level",14)
  assertEq(valid,true)
  LF:RecordLevel(14)
  assert(LF.char.goals[id].completed)
  assert(LF.char.letters[1].opened)
  local note=LF.char.notes[1]
  assertEq(LF:EditNote(note.id,"A better title","Edited text"),true)
  assertEq(LF:FavoriteNote(note.id,true),true)
  assertEq(LF:DeleteNote(note.id,false),false)
  assertEq(LF:DeleteNote(note.id,true),true)
  assert(LF:Chronicle():find("Garvok",1,true))
end)

test("Future Self Letters parse levels, hours, and real calendar dates",function()
  local ok,kind,target=LF:ParseLetterTrigger("hours:4")
  assertEq(ok,true);assertEq(kind,"time");assertEq(target,14400)
  ok,kind,target=LF:ParseLetterTrigger("date:2028-02-29")
  assertEq(ok,true);assertEq(kind,"date");assertEq(target,20280229)
  assertEq(LF:ParseLetterTrigger("date:2027-02-29"),false)
  assertEq(LF:ParseLetterTrigger("date:2027-13-01"),false)
  assertEq(LF:ParseLetterTrigger("hours:-2"),false)
  assertEq(LF:ParseLetterTrigger("hours:1.5"),false)
  assertEq(LF:ParseLetterTrigger("today:later"),false)
  local result,id=LF:AddFutureLetter("A future day","Remember to explore!","date",20281231)
  assertEq(result,true)
  assertEq(LF:LetterTriggerLabel(LF.char.letters[#LF.char.letters]),"2028-12-31")
  assertEq(LF:AddFutureLetter("A day gone by","Too late","date",20200101),false)
  assertEq(LF:AddFutureLetter("Already there","Too late","level",1),false)
  LF:UnlockLetters()
  assertEq(LF.char.letters[#LF.char.letters].opened,false)
  now=os.time({year=2029,month=1,day=1,hour=12})
  LF:UnlockLetters()
  assert(LF.char.letters[#LF.char.letters].opened)
  now=1793294000
end)

test("Legacy date timestamp letters remain readable",function()
  local result,id=LF:AddFutureLetter("Older date format","Remember!","date",1893456000)
  assertEq(result,true)
  assert(LF:LetterTriggerLabel(LF.char.letters[#LF.char.letters]):find("date",1,true))
end)

test("Multiple character/realm scope and retirement",function()
  name="Vyrox";level=25;money=100
  assertEq(LF:AttachCharacter(),true)
  LF:SeedGoals(LF.char)
  assertEq(LF:Totals("realm").characters,2)
  realm="AnotherRealm";name="Dadbod"
  assertEq(LF:AttachCharacter(),true)
  assertEq(LF:Totals("realm").characters,1)
  assertEq(LF:Totals("account").characters,3)
  assertEq(LF:SetRetired(LF.key,true),true)
  assertEq(LF.char.retired,true)
end)

test("Family Legacy aggregates all registered characters without inventing history",function()
  local family=LF:FamilyLegacy('account')
  assertEq(family.characters,3)
  assertEq(family.realmCount,2)
  assertEq(family.archived,1)
  assert(family.mostPlayed and family.first)
  local realmFamily=LF:FamilyLegacy('realm')
  assertEq(realmFamily.characters,1)
  local view=LF:BuildView('characters','account')
  assertEq(view.metrics[3][2],2)
  assertEq(view.rows[1].title,'THE FIRST CHAPTER')
end)

test("Sealed letter command accepts calendar triggers and notifications respect lock",function()
  LF:Command('letter Hello future | We made it | date:2027-11-01')
  local last=LF.char.letters[#LF.char.letters]
  assertEq(last.kind,'date')
  assertEq(last.target,20271101)
  local before=#LF.char.letters
  LF:Command('letter Bad date | No | date:2027-02-30')
  assertEq(#LF.char.letters,before)
  local previous=LF.db.settings.notifications.goals
  LF.runtime.restorePending=true
  LF:Command('notifications goals on')
  assertEq(LF.db.settings.notifications.goals,previous)
  LF.runtime.restorePending=false
end)

test("Social tracking counts only observed group overlap and can be erased",function()
  local player=LF
  _G.GetNumGroupMembers=function() return 2 end
  _G.IsInRaid=function()return false end
  _G.UnitName=function(unit)
    if unit=="party1" then return "Thorgar","ForeverRealm" end
    if unit=="player" then return "Dadbod" end
  end
  _G.UnitIsUnit=function(unit,target) return unit=="player" and target=="player" end
  player:UpdateGroup()
  player:StartSession()
  player:Tick(11,false)
  local key="ForeverRealm:Thorgar"
  assertEq(player.char.companions[key].seconds,11)
  assertEq(player:MuteCompanion(key,true),true)
  player:Tick(7,false)
  assertEq(player.char.companions[key].seconds,11)
  assertEq(player:EraseCompanion(key),true)
  assertEq(player.char.companions[key],nil)
  _G.GetNumGroupMembers=nil
end)

test("LF2 export serializes all account characters and roundtrips",function()
  local good,parts=LF:BuildExport()
  assertEq(good,true)
  assert(#parts>=1)
  local batch=LF:NewImport()
  -- imports can be received in reverse order
  for i=#parts,1,-1 do assertEq(LF:AcceptPart(batch,parts[i]),true) end
  local ok,report=LF:PrepareImport(batch,"replace")
  assertEq(ok,true)
  assertEq(report.incomingCharacters,3)
  assertEq(LF:CommitImport(batch,false),false)
  local saved=LF.db
  assertEq(LF:CommitImport(batch,true),true)
  assert(LifeForgeDB~=saved)
  assertEq(LifeForgeDB.schema,2)
  assertEq(LF:Count(LifeForgeDB.characters),3)
end)

test("Corrupted backup rejected before preview",function()
  local ok,parts=LF:BuildExport();assertEq(ok,true)
  local batch=LF:NewImport()
  for i,p in ipairs(parts) do
    local altered=p
    if i==1 then
      altered=p:sub(1,-2)..(p:sub(-1)=="A" and "B" or "A")
    end
    assertEq(LF:AcceptPart(batch,altered),true)
  end
  assertEq(LF:PrepareImport(batch,"replace"),false)
end)

test("Part validation rejects conflicting duplicate and bad input",function()
  local ok,parts=LF:BuildExport();assertEq(ok,true)
  local b=LF:NewImport()
  assertEq(LF:AcceptPart(b,"garbage"),false)
  assertEq(LF:AcceptPart(b,parts[1]),true)
  assertEq(LF:AcceptPart(b,parts[1]),true)
  local evil=parts[1]:sub(1,-2).."A"
  if evil==parts[1] then evil=parts[1]:sub(1,-2).."B" end
  assertEq(LF:AcceptPart(b,evil),false)
end)

test("Merge adds only new characters and does not sum conflicted stats",function()
  local original=LF.db
  local exportBase=LF:DeepCopy(original)
  local newChar=LF:NewCharacter("Nevar","Elsewhere")
  exportBase.characters["Elsewhere:Nevar"]=newChar
  exportBase.characterOrder[#exportBase.characterOrder+1]="Elsewhere:Nevar"
  local internals=LF.BackupInternals
  local raw=internals.encode(exportBase,0,{nodes=0,seen={}})
  local b64=internals.b64encode(raw)
  local digest=internals.checksum(b64)
  local batch=LF:NewImport()
  local total=math.ceil(#b64/3200)
  for i=1,total do
    local part="LF2|"..i.."|"..total.."|"..digest.."|"..b64:sub((i-1)*3200+1,i*3200)
    assertEq(LF:AcceptPart(batch,part),true)
  end
  local ok,report=LF:PrepareImport(batch,"merge")
  assertEq(ok,true)
  assertEq(report.newCharacters,1)
  assertEq(LF:CommitImport(batch,true),true)
  assertEq(LifeForgeDB.characters["Elsewhere:Nevar"].name,"Nevar")
  assertEq(LifeForgeDB.characters["AnotherRealm:Dadbod"].stats.active,
    original.characters["AnotherRealm:Dadbod"].stats.active)
end)

test("Schema 1 alpha is migrated with archived original",function()
  name="Oldie";realm="OldRealm";level=33;money=25
  local old={schema=1,created=now,settings={tracking=true,notifications={special=true}},
    characters={["OldRealm:Oldie"]={name="Oldie",realm="OldRealm",level=30,
    stats={active=24,afk=3,sessions=1,goldDelta=0,levelUps=2},
    events={},notes={},goals={},zones={},nextId=5}},order={"OldRealm:Oldie"}}
  local migrated=loadAddon(old)
  assertEq(migrated:Boot(),true)
  assertEq(migrated.db.schema,2)
  assert(migrated.db._legacyBackupV1)
  assertEq(migrated.char.stats.active,24)
  assertEq(migrated:Count(migrated.db.characters),1)
  assertEq(migrated.db.meta.migrations[1].from,1)
end)

test("Database validation rejects invalid unsafe shapes",function()
  local tested=loadAddon(LifeForgeDB)
  assertEq(tested:Boot(),true)
  local db=tested:DeepCopy(tested.db)
  db.characters["OldRealm:Oldie"].stats.active=0/0
  local ok=tested:ValidateDB(db)
  assertEq(ok,false)
end)


test("Rapid reload resumes prior session without double counting",function()
  local client=loadAddon()
  name="Oldie";realm="OldRealm";level=33;money=25
  assertEq(client:Boot(),true)
  local c=client.char
  local before=c.stats.sessions
  client:Tick(9,false)
  client:CloseSession()
  now=now+8
  client:StartSession()
  assertEq(c.stats.sessions,before)
  assertEq(c.openSession.active>=9,true)
  client:CloseSession()
  now=now+200
  client:StartSession()
  assertEq(c.stats.sessions,before+1)
end)

test("Disabled tracking records no new gameplay time",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  local before=client.char.stats.active
  client.db.settings.tracking=false
  client:Tick(10,false)
  assertEq(client.char.stats.active,before)
  client.db.settings.tracking=true
end)

test("Multiple backup chunks restore out of order",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  for i=1,120 do
    local ok=client:AddNote("Memory "..i,string.rep("Many years of adventures "..i,7))
    assertEq(ok,true)
  end
  local ok,parts=client:BuildExport()
  assertEq(ok,true)
  assert(#parts>1)
  local b=client:NewImport()
  for i=#parts,1,-1 do assertEq(client:AcceptPart(b,parts[i]),true) end
  local ready,preview=client:PrepareImport(b,"replace")
  assertEq(ready,true)
  assertEq(preview.incomingCharacters,1)
  assertEq(#b.prepared.characters[client.key].notes,120)
end)

test("Malformed event structure fails import validation",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  local bad=client:DeepCopy(client.db)
  bad.characters[client.key].events[1]={id=1,at=client:Now(),kind="x",title=false,description="",favorite=false}
  assertEq(client:ValidateDB(bad),false)
end)

test("Import cannot be committed without preview or user confirmation",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  local batch=client:NewImport()
  assertEq(client:CommitImport(batch,true),false)
  local success,parts=client:BuildExport()
  assertEq(success,true)
  for _,part in ipairs(parts) do assertEq(client:AcceptPart(batch,part),true) end
  assertEq(client:CommitImport(batch,true),false)
  assertEq(client:PrepareImport(batch,"merge"),true)
  assertEq(client:CommitImport(batch,false),false)
end)

test("Notifications queued during combat and flushed on leaving",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  _G.InCombatLockdown=function() return true end
  client:Emit("goals","Test Milestone","",true)
  assertEq(#client.runtime.pendingNotices,1)
  _G.InCombatLockdown=function() return false end
  client:FlushNotices()
  assertEq(#client.runtime.pendingNotices,0)
end)

test("UI/minimap/backup dialog smoke-test with mocked WoW frames",function()
  local client=loadAddon()
  local function mockFrame()
    local o={visible=true}
    local methods={}
    function methods:CreateFontString() return mockFrame() end
    function methods:CreateTexture() return mockFrame() end
    function methods:SetShown(v) self.visible=v end
    function methods:SetFocus() self.focused=true end
    function methods:ClearFocus() self.focused=false end
    function methods:SetText(v) self.text=v end
    function methods:GetText()return self.text or "" end
    function methods:Show()self.visible=true end
    function methods:Hide()self.visible=false end
    function methods:IsShown()return self.visible end
    function methods:SetScript(name,fn)self[name]=fn end
    setmetatable(o,{__index=function(_,method)
      return methods[method] or function() end
    end})
    return o
  end
  _G.UIParent=mockFrame()
  _G.Minimap=mockFrame()
  _G.StaticPopupDialogs={}
  _G.ChatFontNormal={}
  _G.CreateFrame=function()return mockFrame() end
  assertEq(client:Boot(),true)
  assert(client.minimapButton)
  client:Show("statistics")
  client:ShowBackup()
  client:Command("notifications goals on")
  assertEq(client.db.settings.notifications.goals,true)
end)



test("Build 2 all 16 UI view models render from local data",function()
  local client=loadAddon()
  assertEq(client:Boot(),true)
  for _,tab in ipairs({"overview","characters","chronicle","timeline","statistics","companions",
    "goals","vault","museum","footprint","calendar","capsules","wrapped","guild","records","settings"}) do
    local view=client:BuildView(tab,"character",client.key,"")
    assert(type(view.title)=="string" and #view.title>0,tab.." lacks title")
    assert(type(view.rows)=="table" and #view.rows>0,tab.." lacks rows")
    assert(type(view.metrics)=="table",tab.." lacks metrics")
    for _,entry in ipairs(view.rows) do
      assert(type(entry.title)=="string" and type(entry.detail)=="string")
    end
  end
end)

test("Timeline and Vault search filter are literal and case-insensitive",function()
  local client=loadAddon();assertEq(client:Boot(),true)
  assertEq(client:AddNote("Bear Story","Met the bear in the woods"),true)
  local t=client:BuildView("timeline","character",client.key,"HORIZON")
  assertEq(#t.rows,1)
  local v=client:BuildView("vault","character",client.key,"BEAR")
  assertEq(#v.rows,1)
  assert(v.rows[1].title:find("Bear Story",1,true))
  local noMatch=client:BuildView("vault","character",client.key,"<NONEXISTENT>")
  assertEq(#noMatch.rows,1)
  assertEq(noMatch.rows[1].kind,"fact")
end)

test("Account and realm character lists cannot invent unavailable alts",function()
  local client=loadAddon();assertEq(client:Boot(),true)
  local first=client.key
  local firstName=client.char.name
  local v=client:BuildView("characters","account",first)
  assertEq(v.metrics[1][2],1)
  assertEq(#v.rows,4) -- family summary plus one real character
  name="Vyrox";level=23
  assertEq(client:AttachCharacter(),true)
  local list=client:BuildView("characters","account",client.key)
  assertEq(list.metrics[1][2],2)
  assertEq(#list.rows,5)
  local detail=client:BuildView("overview","character",first)
  assert(detail.summary:find(firstName,1,true))
end)

test("UI renders honest snapshot and companion data",function()
  local client=loadAddon();assertEq(client:Boot(),true)
  client.char.companions["Realm:Friend"]={seconds=1234,groupSessions=3}
  client.char.snapshots["2026-10"]={level=12,gold=15000,active=1000}
  local f=client:BuildView("companions","character",client.key)
  assert(f.rows[1].detail:find("observed together",1,true))
  local t=client:BuildView("capsules","character",client.key)
  assertEq(t.rows[1].title,"2026-10")
  local wrap=client:BuildView("wrapped","character",client.key)
  assertEq(wrap.title,"LEGACY WRAPPED")
end)

test("Settings expose all granular notification toggles plus UI settings",function()
  local client=loadAddon();assertEq(client:Boot(),true)
  local v=client:BuildView("settings","character",client.key)
  local toggleCount,hasBackup,hasScale,hasMinimap=0,false,false,false
  for _,row in ipairs(v.rows) do
    if row.kind=="notification" then toggleCount=toggleCount+1 end
    if row.kind=="backup" then hasBackup=true end
    if row.kind=="scale" then hasScale=true end
    if row.kind=="minimap" then hasMinimap=true end
  end
  assertEq(toggleCount,9)
  assert(hasBackup and hasScale and hasMinimap)
end)


test("Selected alt uses its own character and realm scope",function()
  realm="RealmOne";name="FirstAlt";level=12
  local client=loadAddon();assertEq(client:Boot(),true)
  local first=client.key
  realm="RealmTwo";name="SecondAlt";level=22
  assertEq(client:AttachCharacter(),true)
  local second=client.key
  local v=client:BuildView("overview","character",first)
  assert(v.summary:find("FirstAlt",1,true))
  assertEq(v.metrics[4][2],1)
  local r=client:BuildView("characters","realm",first)
  assertEq(r.metrics[1][2],1)
  assertEq(#r.rows,4)
  assert(r.rows[4].title:find("FirstAlt",1,true))
  local a=client:BuildView("characters","account",second)
  assertEq(a.metrics[1][2],2)
  assertEq(#a.rows,5)
end)

test("Favorite metrics reflect saved events and memories",function()
  realm="ForeverRealm";name="Garvok";level=12
  local client=loadAddon();assertEq(client:Boot(),true)
  assertEq(client:AddNote("My favorite", "A fun day"),true)
  local n=client.char.notes[#client.char.notes]
  assertEq(client:FavoriteNote(n.id,true),true)
  local vault=client:BuildView("vault","character",client.key)
  assertEq(vault.metrics[3][2],1)
  client.char.events[1].favorite=true
  local timeline=client:BuildView("timeline","character",client.key)
  assertEq(timeline.metrics[2][2],1)
end)


-- Build 3 regression tests: observed social facts, privacy, guild, records, letters and backups.
local function freshBuild3()
  name="Garvok";realm="ForeverRealm";level=12;money=15000;zone="Durotar"
  _G.GetGuildInfo=nil;_G.IsInGuild=nil
  local client=loadAddon()
  assertEq(client:Boot(),true)
  return client
end
local function fakeParty(members)
  _G.GetNumGroupMembers=function() return #members+1 end
  _G.IsInRaid=function()return false end
  _G.UnitIsUnit=function(unit,target)return unit=="player" and target=="player" end
  _G.UnitName=function(unit)
    if unit=="player" then return name,realm end
    local index=tonumber((unit or ""):match("^party(%d+)$"))
    if index and members[index] then return members[index],"ForeverRealm" end
  end
end

test("Build 3 party overlap persists session history and names",function()
  local client=freshBuild3()
  fakeParty({"Thorgar","Velrissa"});client:UpdateGroup()
  assertEq(client:Count(client.char.parties),1)
  client:Tick(12,false)
  client:Tick(8,true)
  local partyId=client:Keys(client.char.parties)[1]
  local party=client.char.parties[partyId]
  assertEq(party.seconds,20)
  assertEq(party.sessions,1)
  assertEq(client.char.companions["ForeverRealm:Thorgar"].seconds,20)
  assertEq(#client.char.groupHistory,1)
  assertEq(client.char.groupHistory[1].seconds,20)
  assertEq(client:NameParty(partyId,"The Sleepless Three"),true)
  assertEq(party.name,"The Sleepless Three")
  client:UpdateGroup();assertEq(party.sessions,1) -- no double count on identical roster
  local view=client:BuildView("companions","character",client.key)
  local found=false
  for _,entry in ipairs(view.rows) do if entry.title:find("Sleepless",1,true) then found=true end end
  assert(found,"Named party missing from UI")
  fakeParty({"Thorgar"});client:UpdateGroup()
  assertEq(client:Count(client.char.parties),2)
  assertEq(client.char.groupHistory[1].ended~=nil,true)
  assertEq(#client.char.groupHistory,2)
end)

test("Build 3 Legendary Bonds are based on observed hours and never duplicated",function()
  local client=freshBuild3()
  fakeParty({"Thorgar"});client:UpdateGroup()
  client:TickCompanions(3599)
  local friend=client.char.companions["ForeverRealm:Thorgar"]
  assertEq(friend.bondTier or 0,0)
  client:TickCompanions(2)
  assertEq(friend.bondTier,1)
  local n=#client.char.events
  client:TickCompanions(2)
  assertEq(#client.char.events,n)
  client:TickCompanions(32400)
  assertEq(friend.bondTier,2)
  local t=client:BuildView("companions","character",client.key)
  assert(t.rows[1].detail:find("bond tier 2",1,true))
end)

test("Build 3 social events cannot claim unobserved reunions",function()
  local client=freshBuild3()
  fakeParty({"Thorgar"});client:UpdateGroup()
  local key="ForeverRealm:Thorgar"
  fakeParty({});client:UpdateGroup()
  local before=#client.char.events
  fakeParty({"Thorgar"});client:UpdateGroup()
  assertEq(#client.char.events,before)
  fakeParty({});client:UpdateGroup()
  client.char.companions[key].lastSeen=now-(31*86400)
  fakeParty({"Thorgar"});client:UpdateGroup()
  assertEq(client.char.events[#client.char.events].title,"The Last Adventure — Reunited")
end)

test("Build 3 combat roster uncertainty pauses measurements and safely resumes",function()
  local client=freshBuild3()
  fakeParty({"Thorgar"});client:UpdateGroup()
  _G.InCombatLockdown=function()return true end
  client:UpdateGroup() -- roster might change; do not infer or count while pending
  client:TickCompanions(200)
  local friend=client.char.companions["ForeverRealm:Thorgar"]
  assertEq(friend.seconds,0)
  _G.InCombatLockdown=function()return false end
  client:UpdateGroup();client:TickCompanions(9)
  assertEq(friend.seconds,9)
end)

test("Build 3 bookmark stores known companions and forgetting erases future tracking",function()
  local client=freshBuild3()
  fakeParty({"Thorgar","Velrissa"});client:UpdateGroup()
  client:TickCompanions(8)
  local key="ForeverRealm:Thorgar"
  assertEq(client:AddNote("A crazy night","Great party"),true)
  assertEq(#client.char.notes[1].companions,2)
  local partyId=client:Keys(client.char.parties)[1]
  assertEq(client:EraseCompanionEverywhere(key,false),false)
  assertEq(client:EraseCompanionEverywhere(key,true),true)
  assertEq(client.char.companions[key],nil)
  assertEq(client.char.parties[partyId],nil)
  assertEq(#client.char.groupHistory,0)
  assertEq(#client.char.notes[1].companions,1)
  assertEq(client.db.settings.mutedCompanions[key],true)
  client:UpdateGroup();client:TickCompanions(4)
  assertEq(client.char.companions[key],nil)
end)

test("Build 3 guild history is recorded only when membership is observable",function()
  local client=freshBuild3()
  client:UpdateGuild();assertEq(#client.char.guildHistory,0)
  _G.GetGuildInfo=function()return "Raiders Of The Lost Sleep" end
  client:UpdateGuild()
  assertEq(client.char.guild,"Raiders Of The Lost Sleep")
  assertEq(#client.char.guildHistory,1)
  client:UpdateGuild();assertEq(#client.char.guildHistory,1)
  _G.GetGuildInfo=function()return nil end
  client:UpdateGuild();assertEq(#client.char.guildHistory,1) -- ambiguous nil is not a leave
  _G.IsInGuild=function()return false end
  client:UpdateGuild()
  assertEq(#client.char.guildHistory,2)
  assertEq(client.char.guildHistory[2].kind,"left")
  local view=client:BuildView("guild","character",client.key)
  assertEq(view.metrics[2][2],2)
end)

test("Build 3 records track peaks and longest completed active session",function()
  local client=freshBuild3()
  assertEq(client.char.records.peakGold,15000)
  client:RecordMoney(40000);client:RecordMoney(1000)
  assertEq(client.char.records.peakGold,40000)
  client:Tick(25,false);client:Tick(5,true)
  client:CloseSession()
  assertEq(client.char.records.longestSession,25)
  client:RecordLevel(22)
  assertEq(client.char.records.bestLevel,22)
  local v=client:BuildView("records","character",client.key)
  assertEq(v.metrics[2][2],"4.0g")
  assertEq(v.metrics[4][2],22)
end)

test("Build 3 then-vs-now comparisons use historical saved facts",function()
  local client=freshBuild3()
  client:MonthlySnapshot()
  local month=client:Date("%Y-%m")
  client:RecordLevel(13);client:Tick(12,false);client:RecordMoney(30000)
  local diff=client:ThenVsNow(client.char,month)
  assertEq(diff.level,1)
  assertEq(diff.gold,15000)
  assertEq(diff.active,12)
  assertEq(client:ThenVsNow(client.char,"2000-01"),nil)
  local v=client:BuildView("capsules","character",client.key)
  assert(v.rows[1].detail:find("Since",1,true))
end)

test("Build 3 sealed Future Self letter text is absent from search",function()
  local client=freshBuild3()
  assertEq(client:AddFutureLetter("My message","SECRET_DIAMOND","level",20),true)
  local before=client:BuildView("vault","character",client.key,"SECRET_DIAMOND")
  assertEq(before.rows[1].kind,"fact")
  local capsules=client:BuildView("capsules","character",client.key)
  assertEq(capsules.action,"letter")
  client:RecordLevel(20)
  local after=client:BuildView("vault","character",client.key,"SECRET_DIAMOND")
  assertEq(after.rows[1].kind,"letter")
end)

test("Build 3 backup includes parties, guild changes and personal records",function()
  local client=freshBuild3()
  fakeParty({"Thorgar"});client:UpdateGroup();client:TickCompanions(22)
  _G.GetGuildInfo=function()return "Raiders Of The Lost Sleep" end
  client:UpdateGuild();client:RecordMoney(22222)
  local ok,parts=client:BuildExport();assertEq(ok,true)
  local batch=client:NewImport()
  for _,part in ipairs(parts) do assertEq(client:AcceptPart(batch,part),true) end
  local ready=client:PrepareImport(batch,"replace")
  assertEq(ready,true)
  local restored=batch.prepared.characters[client.key]
  assertEq(client:Count(restored.parties),1)
  assertEq(#restored.guildHistory,1)
  assertEq(restored.records.peakGold,22222)
  assertEq(client:CommitImport(batch,false),false)
end)

test("Build 3 older schema-2 saves safely gain optional social extensions",function()
  local client=freshBuild3()
  client.char.parties=nil;client.char.records=nil
  local key=client.key
  local alt=client:NewCharacter("Alt","OtherRealm")
  alt.parties=nil;alt.records=nil;alt.guildHistory={}
  client.db.characters["OtherRealm:Alt"]=alt
  local saved=client.db
  local restarted=loadAddon(saved)
  assertEq(restarted:Boot(),true)
  assert(type(restarted.char.records)=="table")
  assert(type(restarted.db.characters["OtherRealm:Alt"].parties)=="table")
  assert(restarted.db.characters[key].records.peakGold>=0)
end)

test("Build 3 corrupt added party/record fields reject export",function()
  local client=freshBuild3()
  local original=client.char.records.peakGold
  client.char.records.peakGold=0/0
  assertEq(client:BuildExport(),false)
  client.char.records.peakGold=original
  client.char.parties.fake={name="invalid",members={"Realm:Alt"},seconds=-1,sessions=1}
  assertEq(client:ValidateDB(client.db),false)
end)


test("Build 3 Chronicle monthly chapters use recorded moments only",function()
  local client=freshBuild3()
  local chapters=client:ChronicleChapters()
  assertEq(#chapters,1)
  assertEq(chapters[1].count,#client.char.events)
  client:RecordLevel(13)
  local chaptersAfter=client:ChronicleChapters()
  assertEq(chaptersAfter[1].count,#client.char.events)
  assert(chaptersAfter[1].summary:find("Level 13",1,true))
  local v=client:BuildView("chronicle","character",client.key)
  assertEq(v.rows[1].kind,"chapter")
  assertEq(v.metrics[1][2],1)
  local noResults=client:BuildView("chronicle","character",client.key,"NEVER_HAPPENED")
  assertEq(noResults.rows[1].kind,"fact")
end)


-- Build 4: calendar, zone atlas, museum, wrapped and native UI rendering.
test("Build 4 leap year calendar has 42 correctly aligned days",function()
  local client=freshBuild3()
  local cal=client:CalendarModel(2028,2,'character',client.key)
  assertEq(#cal.cells,42)
  local found={}
  for _,cell in ipairs(cal.cells) do if cell.day then found[#found+1]=cell.day end end
  assertEq(#found,29)
  assertEq(found[1],1);assertEq(found[#found],29)
  assertEq(cal.cells[3].day,1) -- Tue 1 Feb 2028
  assertEq(client:CalendarModel(2027,2,'character',client.key).cells[1].day,nil)
end)

test("Build 4 calendar uses actual recorded days/events and caps intensity",function()
  local client=freshBuild3()
  client.char.daily['2026-10-21']={active=600,afk=20,sessions=1,levels=2}
  client.char.daily['2026-10-22']={active=100,afk=0,sessions=1,levels=0}
  client.char.events[#client.char.events+1]={id=8000,at=os.time({year=2026,month=10,day=21,hour=12}),title='Test event',kind='levels'}
  local calendar=client:CalendarModel(2026,10,'character',client.key)
  assertEq(calendar.totals.active,700)
  assertEq(calendar.totals.activeDays,2)
  assertEq(calendar.totals.levels,2)
  local special
  for _,cell in ipairs(calendar.cells) do if cell.day==21 then special=cell end end
  assertEq(special.active,600)
  assertEq(special.intensity,4)
  assertEq(special.events,1)
end)

test("Build 4 footprint combines observed zone time across local alts",function()
  local client=freshBuild3()
  client.char.zones.Durotar.seconds=100
  local alt=client:NewCharacter('Second','ForeverRealm')
  alt.zones.Durotar={seconds=200,firstSeen=now-10}
  alt.zones.Orgrimmar={seconds=50,firstSeen=now}
  client.db.characters['ForeverRealm:Second']=alt
  local localView=client:FootprintModel('character',client.key)
  local realmView=client:FootprintModel('realm',client.key)
  assertEq(localView.count,1)
  assertEq(realmView.count,2)
  assertEq(realmView.zones[1].seconds,300)
  assertEq(realmView.zones[1].visits,2)
  assertEq(realmView.zones[1].ratio,1)
end)

test("Build 4 museum contains only real favorites and respects scope",function()
  local client=freshBuild3()
  assertEq(client:AddNote('The evening','An unforgettable time'),true)
  local n=client.char.notes[#client.char.notes]
  client:FavoriteNote(n.id,true)
  client.char.events[1].favorite=true
  local museum=client:MuseumModel('character',client.key)
  assertEq(museum.total,2)
  assertEq(museum.exhibits[1].kind,'note')
  client:FavoriteNote(n.id,false)
  assertEq(client:MuseumModel('character',client.key).total,1)
  assertEq(client:DeleteNote(n.id,true),true)
  assertEq(client:MuseumModel('character',client.key).total,1)
end)

test("Build 4 monthly Wrapped cannot infer prior companions or zone hours",function()
  local client=freshBuild3()
  client.char.daily={['2026-10-15']={active=300,afk=60,sessions=2,levels=1},
      ['2026-09-12']={active=700,afk=100,sessions=3,levels=2}}
  client.char.stats.active=1000;client.char.stats.afk=160;client.char.stats.sessions=5
  client.char.stats.levelUps=3
  client.char.companions['ForeverRealm:Thorgar']={seconds=10000,lastSeen=now}
  local month=client:WrappedModel('2026-10','character',client.key)
  assertEq(month.active,300);assertEq(month.days,1)
  assertEq(month.sessions,2);assertEq(month.levels,1)
  assertEq(month.topCompanion,nil)
  assertEq(month.topZone,nil)
  local lifetime=client:WrappedModel('all','character',client.key)
  assertEq(lifetime.active,1000)
  assertEq(lifetime.topCompanion.name,'ForeverRealm:Thorgar')
  assertEq(client:WrappedModel('2026-13','character',client.key),nil)
  local periods=client:WrappedPeriods('character',client.key)
  assertEq(periods[1],'all')
  assertEq(periods[2],'2026-10')
  assertEq(periods[3],'2026-09')
end)

test("Build 4 uses unchanged schema-2 and LF2 backup for favorites and daily stats",function()
  local client=freshBuild3()
  assertEq(client:AddNote('Saved exhibit','Real memory'),true)
  client:FavoriteNote(client.char.notes[1].id,true)
  client.char.daily['2026-10-23']={active=72,afk=3,sessions=1,levels=0}
  local ok,parts=client:BuildExport()
  assertEq(ok,true)
  local batch=client:NewImport()
  for _,part in ipairs(parts) do assertEq(client:AcceptPart(batch,part),true) end
  assertEq(client:PrepareImport(batch,'replace'),true)
  local restored=batch.prepared.characters[client.key]
  assertEq(restored.daily['2026-10-23'].active,72)
  assertEq(restored.notes[1].favorite,true)
  assertEq(batch.prepared.schema,2)
end)

-- An intentionally small fake frame environment to catch runtime errors without WoW.
local function fakeFrame()
  local obj={shown=true,level=1,scripts={}}
  local function noop()end
  local methods={'SetSize','SetPoint','SetAllPoints','SetBackdrop','SetBackdropColor',
      'SetClampedToScreen','SetScale','SetMovable','EnableMouse','RegisterForDrag',
      'RegisterForClicks','SetFrameStrata','SetTextColor','SetJustifyH','SetJustifyV',
      'SetColorTexture','SetHeight','SetWidth','SetNormalTexture','SetHighlightTexture',
      'SetAutoFocus','SetMultiLine','SetFontObject','SetMaxLetters','SetFocus','ClearFocus',
      'SetAlpha','StartMoving','StopMovingOrSizing','SetOwner','AddLine','Enable','Disable'}
  for _,m in ipairs(methods) do obj[m]=noop end
  obj.SetScript=function(self,k,fn)self.scripts[k]=fn end
  obj.SetFrameLevel=function(self,v)self.level=v end
  obj.GetFrameLevel=function(self)return self.level end
  obj.Hide=function(self)self.shown=false end
  obj.Show=function(self)self.shown=true end
  obj.SetShown=function(self,v)self.shown=v==true end
  obj.IsShown=function(self)return self.shown end
  obj.SetText=function(self,v)self.text=v end
  obj.GetText=function(self)return self.text or '' end
  obj.CreateTexture=function(self)return fakeFrame()end
  obj.CreateFontString=function(self)return fakeFrame()end
  return obj
end

test("Build 4 renders all four native UI panels in a mocked frame tree",function()
  local client=freshBuild3()
  _G.CreateFrame=function()return fakeFrame()end
  _G.UIParent=fakeFrame();_G.Minimap=fakeFrame();_G.UISpecialFrames={}
  client:BuildUI()
  assert(client.experienceFrame)
  for _,tab in ipairs({'calendar','museum','footprint','wrapped'}) do
    client:Show(tab)
    assertEq(client.experienceFrame.tab,tab)
    assertEq(client.experienceFrame:IsShown(),true)
  end
  local f=client.experienceFrame
  f.state.calendarShift=1;f:Render('calendar','character',client.key)
  f.state.wrappedIndex=200;f:Render('wrapped','character',client.key)
  f:Render('museum','character',client.key)
  f:Render('footprint','character',client.key)
  client:Show('statistics')
  assertEq(f:IsShown(),false)
  _G.CreateFrame=nil;_G.Minimap=nil
end)


-- Build 5: acceptance tests of actual management operations, not tab placeholders.
test("Build 5 edits all goal kinds with validated target and completion reset",function()
  local client=freshBuild3()
  local ok,id=client:AddGoal('My journey','level',14)
  assertEq(ok,true)
  client:RecordLevel(14)
  assert(client.char.goals[id].completed)
  assertEq(client:EditGoal(id,'Travel far','zones',100),true)
  assertEq(client.char.goals[id].completed,false)
  assertEq(client.char.goals[id].kind,'zones')
  assertEq(client.char.goals[id].preset,false)
  assertEq(client:EditGoal(id,'invalid','not-a-kind',20),false)
  assertEq(client:EditGoal(id,'Bad limit','gold',0),false)
  assertEq(client:EditGoal(id,'The Treasure','gold',100000),true)
  assertEq(client:EditGoal(id,'Veteran','time',99999),true)
  assertEq(client:EditGoal(id,'Friends','companions',5),true)
  assertEq(client:EditGoal(id,'Stories','notes',5),true)
end)

test("Build 5 goal deletion is consent-gated and presets stay hidden after reseed",function()
  local client=freshBuild3()
  local ok,id=client:AddGoal('Experimental','level',60);assertEq(ok,true)
  assertEq(client:DeleteGoal(id,false),false)
  assertEq(client:DeleteGoal(id,true),true)
  assertEq(client.char.goals[id],nil)
  assertEq(client:DeleteGoal('time10',true),true)
  assertEq(client.char.goals.time10.hidden,true)
  client:SeedGoals(client.char)
  assertEq(client.char.goals.time10.hidden,true)
  local goals=client:BuildView('goals','character',client.key)
  for _,row in ipairs(goals.rows) do assert(row.id~='time10') end
end)

test("Build 5 memory category editing and deletion prevent accidental removal",function()
  local client=freshBuild3()
  local ok,id=client:AddNote('The battle','It was great','Adventure');assertEq(ok,true)
  assertEq(client:EditNoteFull(id,'Edited','The long tale','Guild Memory'),true)
  local note=client:FindNote(id);assertEq(note.category,'Guild Memory')
  assertEq(client:EditNoteFull(id,'Broken','Text',''),false)
  assertEq(client:DeleteNote(id,false),false)
  assertEq(client:DeleteNote(id,true),true)
end)

test("Build 5 archived characters never lose their records",function()
  local client=freshBuild3()
  local key=client.key;client:AddNote('Remember','History preserved')
  assertEq(client:SetRetired(key,true),true)
  assertEq(client.db.characters[key].retired,true)
  assertEq(client:SetRetired(key,false),true)
  assertEq(#client.db.characters[key].notes,1)
  client.runtime.readOnly=true
  assertEq(client:SetRetired(key,true),false)
  client.runtime.readOnly=false
end)

test("Build 5 Future Self Letters require deletion confirmation",function()
  local client=freshBuild3()
  local ok,id=client:AddFutureLetter('My future','Remember this','level',55)
  assertEq(ok,true)
  assertEq(client:DeleteFutureLetter(id,false),false)
  assertEq(client:DeleteFutureLetter(id,true),true)
  assertEq(#client.char.letters,0)
end)

test("Build 5 Data Health detects corruption without deleting saves",function()
  local client=freshBuild3()
  local health=client:DataHealth()
  assertEq(health.valid,true)
  assertEq(health.characters,1)
  local original=client.char.stats.active
  client.char.stats.active=-11
  assertEq(client:DataHealth().valid,false)
  client.char.stats.active=original
  assertEq(client:DataHealth().valid,true)
end)

test("Build 5 cleanup preserves totals, diary, milestones and notes",function()
  local client=freshBuild3()
  local c=client.char
  c.stats.active=9000;c.daily['2024-01-01']={active=3600,afk=0,sessions=1,levels=0}
  client:AddNote('Keep','Never prune this')
  c.sessionHistory={{id=1,started=now-500*86400,ended=now-500*86400,active=9000,afk=0},
    {id=2,started=now-5*86400,ended=now-4*86400,active=5,afk=0}}
  c.groupHistory={{started=now-450*86400,seconds=8,members={'A'}},
    {started=now-2*86400,seconds=3,members={'B'}}}
  local oldEvents=#c.events
  assertEq(client:PruneRawHistory(365,false),false)
  local ok,removed=client:PruneRawHistory(365,true)
  assertEq(ok,true);assertEq(removed,2)
  assertEq(#c.sessionHistory,1);assertEq(#c.groupHistory,1)
  assertEq(c.stats.active,9000)
  assertEq(c.daily['2024-01-01'].active,3600)
  assertEq(#c.events,oldEvents);assertEq(#c.notes,1)
end)

test("Build 5 Session Intelligence uses only completed sessions for average",function()
  local client=freshBuild3()
  local c=client.char
  c.sessionHistory={{started=1,ended=2,active=100,afk=30},{started=3,ended=4,active=200,afk=10}}
  c.openSession={id=55,started=5,active=40,afk=9}
  local report=client:SessionIntelligence(c)
  assertEq(report.completed,2)
  assertEq(report.meanActive,150)
  assertEq(report.currentActive,40)
  assertEq(report.longestFinished,200)
end)

test("Build 5 compatibility report never pretends live client validation",function()
  local client=freshBuild3()
  _G.GetBuildInfo=function()return '1.60.1','', '',16001 end
  local result=client:CompatibilityReport()
  assertEq(result.interface,16001)
  assertEq(result.verifiedInGame,false)
  _G.GetBuildInfo=nil
  assertEq(client:CompatibilityReport().provisional,true)
end)

test("Build 5 backup restores goals, letter, archive and category",function()
  local client=freshBuild3()
  assertEq(client:AddNote('My note','Tale','Guild'),true)
  local id=client.char.notes[#client.char.notes].id
  assertEq(client:EditNoteFull(id,'My note','Tale','Epic'),true)
  assertEq(client:DeleteGoal('time10',true),true)
  assertEq(client:SetRetired(client.key,true),true)
  assertEq(client:AddFutureLetter('Hello','Future story','level',55),true)
  local ok,parts=client:BuildExport();assertEq(ok,true)
  local batch=client:NewImport()
  for _,part in ipairs(parts) do assertEq(client:AcceptPart(batch,part),true) end
  assertEq(client:PrepareImport(batch,'replace'),true)
  assertEq(client:CommitImport(batch,true),true)
  local restored=_G.LifeForgeDB.characters[client.key]
  assertEq(restored.notes[1].category,'Epic')
  assertEq(restored.retired,true)
  assertEq(restored.goals.time10.hidden,true)
  assertEq(#restored.letters,1)
end)


test("Build 5 one-command bookmark stores real local context and is favorited",function()
  local client=freshBuild3()
  local before=#client.char.notes
  local ok,id=client:QuickBookmark()
  assertEq(ok,true);assertEq(#client.char.notes,before+1)
  local note=client:FindNote(id)
  assertEq(note.favorite,true)
  assertEq(note.zone,'Durotar')
  assertEq(note.category,'Adventure')
  assert(note.body:find('Bookmarked',1,true))
end)

test("Build 5 guild memories and personal firsts appear in their sections",function()
  local client=freshBuild3()
  client.char.guild='Raiders Of The Lost Sleep'
  assertEq(client:AddNote('First raid','Great evening','Guild Memory'),true)
  local guild=client:BuildView('guild','character',client.key)
  local found=false
  for _,r in ipairs(guild.rows) do
    if r.title:find('First raid',1,true) then
      assert(r.detail:find('Raiders Of The Lost Sleep',1,true));found=true
    end
  end
  assertEq(found,true)
  assertEq(guild.action,'guildmemory')
  local records=client:BuildView('records','character',client.key)
  local firsts=0
  for _,r in ipairs(records.rows) do if r.title:find('FIRST ',1,true) then firsts=firsts+1 end end
  assert(firsts>=2)
end)

test("Build 5 richer Chronicle only narrates observed milestones",function()
  local client=freshBuild3()
  client:RecordLevel(13)
  local chapters=client:ChronicleChapters()
  assert(chapters[1].summary:find('level milestone',1,true))
  assert(chapters[1].summary:find('Level 13',1,true))
  assert(not chapters[1].summary:find('boss defeated',1,true))
end)

test("Build 5 lightweight settings health counts and full validation are separate",function()
  local client=freshBuild3()
  local light=client:DataHealth(false)
  assertEq(light.valid,nil)
  assertEq(light.characters,1)
  assertEq(client:DataHealth(true).valid,true)
end)

test("Build 5 mocked UI can open all sixteen tabs without runtime exceptions",function()
  local client=freshBuild3()
  _G.CreateFrame=function()return fakeFrame()end
  _G.UIParent=fakeFrame();_G.Minimap=fakeFrame();_G.UISpecialFrames={}
  client:BuildUI()
  for _,tab in ipairs({'overview','characters','chronicle','timeline','statistics','companions',
    'goals','vault','museum','footprint','calendar','capsules','wrapped','guild','records','settings'}) do
    client:Show(tab)
    local v=client:BuildView(tab,'character',client.key)
    assert(type(v.title)=='string')
    assert(type(v.rows)=='table')
  end
  _G.CreateFrame=nil;_G.Minimap=nil
end)

io.write("\n"..activeTests.." / "..activeTests.." Lua tests passed.\n")
