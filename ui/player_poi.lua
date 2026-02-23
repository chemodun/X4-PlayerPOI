local ffi = require("ffi")
local p = require("7.60.ui.core.lua.jit.p")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
	typedef struct {
		int x;
		int y;
	} Coord2D;

  UniverseID GetPlayerID(void);

	Coord2D GetCenteredMousePos(void);

  double GetCurrentGameTime(void);
]]

local debugLevel = "trace" -- "none", "debug", "trace"

local texts = {
  playerPOI = ReadText(1972092414,1),
}


local playerPoi = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},
  tabIcon = "mapob_poi",
  poiMacro = "player_poi_01_macro",
  poiMode = "playerPOI",

}

local config = {}
local function debug(message)
  if debugLevel ~= "none" then
    local text = "PlayerPoi: " .. message
    if type(DebugError) == "function" then
      DebugError(text)
    end
  end
end

local function trace(message)
  ---@diagnostic disable-next-line: unnecessary-if
  if debugLevel == "trace" then
    debug(message)
  end
end

local function bind(obj, methodName)
  return function(...)
    return obj[methodName](obj, ...)
  end
end

function playerPoi.Init(menuMap)
  trace("playerPoi.Init called at " .. tostring(C.GetCurrentGameTime()))
  playerPoi.menuMap = menuMap
  playerPoi.menuMapConfig = menuMap.uix_getConfig()
  playerPoi.setupTab()
  menuMap.registerCallback("createPropertyOwned_on_add_other_objects_infoTableData", playerPoi.prepareTabData)
  menuMap.registerCallback("createPropertyOwned_on_createPropertySection_unassignedships", playerPoi.displayTabData)
  RegisterEvent("PlayerPoi.OnRename", playerPoi.onRename)
end

function playerPoi.resetData()
end

function playerPoi.setupTab()
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return
  end
  local config = playerPoi.menuMapConfig
  local propertyCategories = config and config.propertyCategories or nil
  if propertyCategories == nil then
    debug("Property categories are not defined in menu map config")
    return
  end
  for i = #propertyCategories, 1, -1 do
    local category = propertyCategories[i]
    if string.sub(category.id, 1, 10) ~= "custom_tab" then
      if category.id == playerPoi.poiMode then
        trace("Found playerPOI category in menu map config")
      else 
        local poiTab = {
          id = playerPoi.poiMode,
          name = texts.playerPOI,
          icon = playerPoi.tabIcon,
        }
        if i == #propertyCategories then
          propertyCategories[#propertyCategories + 1] = poiTab
        else
          table.insert(propertyCategories, i + 1, poiTab)
        end
      end
      return
    end
  end
end

function playerPoi.prepareTabData(infoTableData)
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return
  end
  if infoTableData == nil then
    debug("Info table data is nil")
    return
  end
  if infoTableData.playerPOI ~= nil then
    trace("Player POI data already prepared, skipping")
    return
  end
  if infoTableData.deployables == nil or #infoTableData.deployables == 0 then
    trace("No deployables found in info table data, skipping player POI data preparation")
    return
  end
  infoTableData.playerPOI = {}
  local playerPoiList = infoTableData.playerPOI
  for i = #infoTableData.deployables, 1, -1 do
    local deployable = infoTableData.deployables[i]
    local macro = GetComponentData(deployable.id, "macro")
    if macro == playerPoi.poiMacro then
      trace("Found deployable with matching macro: " .. tostring(deployable.id))
      playerPoiList[#playerPoiList + 1] = deployable
      table.remove(infoTableData.deployables, i)
    end
  end
end

function playerPoi.displayTabData(numDisplayed, instance, ftable, infoTableData)
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return numDisplayed
  end
  infoTableData.playerPOI = infoTableData.playerPOI or {}
  if menu.propertyMode == playerPoi.poiMode then
    numDisplayed = menu.createPropertySection(instance, "owneddeployables", ftable, texts.playerPOI, infoTableData.playerPOI, "-- " .. ReadText(1001, 34) .. " --", nil, numDisplayed, nil, menu.propertySorterType)
  end
  return numDisplayed
end

function playerPoi.onRename(_, param)
  trace("onRename called with param: " .. tostring(param))
  local object = ConvertStringTo64Bit(tostring(param))
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return
  end
  local config = playerPoi.menuMapConfig
  local mousepos = C.GetCenteredMousePos()
  menu.contextMenuMode = "rename"
  menu.contextMenuData = { component = object, xoffset = mousepos.x + Helper.viewWidth / 2, yoffset = mousepos.y + Helper.viewHeight / 2 }

  local width = Helper.scaleX(config.renameWidth)
  if menu.contextMenuData.xoffset + width > Helper.viewWidth then
    menu.contextMenuData.xoffset = Helper.viewWidth - width - Helper.frameBorder
  end

  menu.createContextFrame(width, nil, menu.contextMenuData.xoffset, menu.contextMenuData.yoffset)
end

local function Init()
  playerPoi.playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  debug("Initializing PlayerPOI UI extension with PlayerID: " .. tostring(playerPoi.playerId))
  local menuMap = Helper.getMenu("MapMenu")
  local menuMapIsOk = menuMap ~= nil and type(menuMap.registerCallback) == "function"
  if not menuMapIsOk then
    debug("Failed to get MapMenu or registerCallback is not a function")
    return
  end
  trace(string.format("menuMap is %s", tostring(menuMap)))
  playerPoi.Init(menuMap)
end


Register_OnLoad_Init(Init)
