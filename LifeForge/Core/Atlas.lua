-- Build 7. Optional live API evidence only. Never infer positions from zone names.
local LF=_G.LifeForge
local function validId(v)
  return type(v)=='number' and v==v and v>=1 and v<=10000000 and v%1==0
end
local function validCoord(v)
  return type(v)=='number' and v==v and v>=0 and v<=1
end
function LF:MapEvidence()
  local map=_G.C_Map
  if type(map)~='table' or type(map.GetBestMapForUnit)~='function' then return nil end
  if self:IsCombat() then return nil end
  local ok,id=pcall(map.GetBestMapForUnit,'player')
  if not ok then return nil end
  local idSafe,accepted=pcall(validId,id)
  if not idSafe or not accepted then return nil end
  local evidence={id=id}
  if type(map.GetMapInfo)=='function' then
    local fine,info=pcall(map.GetMapInfo,id)
    if fine then
      pcall(function()
        if type(info)=='table' then
          if type(info.name)=='string' then evidence.mapName=self:Text(info.name,100) end
          if validId(info.parentMapID) then evidence.parentMapID=info.parentMapID end
        end
      end)
    end
  end
  if type(map.GetPlayerMapPosition)=='function' then
    local valid,pos=pcall(map.GetPlayerMapPosition,id,'player')
    if valid and pos then
      pcall(function()
        local x,y
        if type(pos.GetXY)=='function' then
          local fine,a,b=pcall(pos.GetXY,pos)
          if fine then x,y=a,b end
        elseif type(pos)=='table' then x,y=pos.x,pos.y end
        if validCoord(x) and validCoord(y) then evidence.x=x;evidence.y=y end
      end)
    end
  end
  return evidence
end
function LF:CaptureMapEvidence(zone)
  if not self.char or not self:IsTracking() or self.runtime.readOnly or not self.char.zones[zone] then return false end
  local proof=self:MapEvidence()
  if not proof then return false end
  local entry=self.char.zones[zone]
  if not entry.mapID or entry.mapID==proof.id then
    entry.mapID=proof.id
    entry.mapName=proof.mapName
    entry.parentMapID=proof.parentMapID
    if proof.x and proof.y then
      entry.sampleX=proof.x;entry.sampleY=proof.y
      entry.sampledAt=self:Now()
    end
    return true
  end
  -- Never overwrite a zone/map association with a mismatching map ID.
  return false
end