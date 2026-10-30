-- Guild membership is recorded only when the client exposes a trusted player guild name.
local LF=_G.LifeForge
function LF:UpdateGuild()
  if not self.char or not self:IsTracking() then return end
  if self:IsCombat() then return end
  local known=(type(_G.GetGuildInfo)=="function")
  if not known then return end
  local guild=self:SafeCall(_G.GetGuildInfo,"player")
  if type(guild)~="string" then
    -- A temporary nil while logging in is not proof of guild departure.
    if type(_G.IsInGuild)~="function" or self:SafeCall(_G.IsInGuild)~=false then return end
    guild=""
  end
  guild=self:Text(self:Trim(guild),150)
  local c=self.char
  if not c.guildObserved then
    c.guildObserved=true;c.guild=guild;c.guildFirstObservedAt=self:Now()
    if guild~="" then self:AppendGuildChange("joined",guild) end
    return
  end
  if (c.guild or "")==guild then return end
  local previous=c.guild or ""
  if previous~="" then self:AppendGuildChange("left",previous) end
  c.guild=guild
  if guild~="" then self:AppendGuildChange("joined",guild) end
end
function LF:AppendGuildChange(kind,guild)
  if not self.char or not self:IsTracking() then return end
  local c=self.char
  if #c.guildHistory>=self.config.MAX_GUILD_HISTORY then table.remove(c.guildHistory,1) end
  c.guildHistory[#c.guildHistory+1]={at=self:Now(),kind=kind,guild=guild,zone=self:Text(c.zone or "",100)}
  self:Emit("guild",kind=="joined" and "A New Guild Chapter" or "A Guild Chapter Closes",
    (kind=="joined" and "Guild membership first observed: " or "Observed departure from guild: ")..guild..".",true)
end
