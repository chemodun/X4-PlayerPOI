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
  mouseX = nil,
  mouseY = nil,

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

function playerPoi.Init(menuMap, menuInteract)
  trace("playerPoi.Init called at " .. tostring(C.GetCurrentGameTime()))
  playerPoi.menuMap = menuMap
  playerPoi.menuMapConfig = menuMap.uix_getConfig()
  playerPoi.menuInteract = menuInteract
  playerPoi.setupTab()
  menuMap.registerCallback("createPropertyOwned_on_add_other_objects_infoTableData", playerPoi.prepareTabData)
  menuMap.registerCallback("createPropertyOwned_on_createPropertySection_unassignedships", playerPoi.displayTabData)
  menuInteract.registerCallback("draw_on_start", playerPoi.getMousePosition)
  menuInteract.registerCallback("prepareActions_prepare_custom_action", playerPoi.removeActivateDeactivateAction)
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

function playerPoi.getMousePosition(config)
  local menu = playerPoi.menuInteract
  if menu == nil then
    debug("Menu interact is not initialized")
    return
  end
  playerPoi.mouseX = menu.mouseX
  playerPoi.mouseY = menu.mouseY
end

function playerPoi.removeActivateDeactivateAction(actions, definedActions)
  local menu = playerPoi.menuInteract
  if menu == nil then
    debug("Menu interact is not initialized")
    return
  end
  local convertedComponent = menu.data and menu.data.convertedComponent or nil
  if convertedComponent == nil then
    trace("No converted component found in interact menu data, skipping action removal")
    return
  end
  local macro = GetComponentData(convertedComponent, "macro")
  if macro == playerPoi.poiMacro then
    trace("Removing activate/deactivate actions for player POI component")
    for i = #actions, 1, -1 do
      local action = actions[i]
      if action.actiontype == "detach" then
        trace("Removing action with actiontype: " .. tostring(action.actiontype))
        table.remove(actions, i)
        definedActions[action.actiontype] = nil
      end
    end
  end
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
  
  local mouseX = playerPoi.mouseX
  local mouseY = playerPoi.mouseY
  if mouseX == nil or mouseY == nil then
    local mousePos = C.GetCenteredMousePos()
    mouseX = mousePos.x
    mouseY = mousePos.y
  end

  menu.contextMenuMode = "rename"
  menu.contextMenuData = { component = object, xoffset = mouseX + Helper.viewWidth / 2, yoffset = mouseY + Helper.viewHeight / 2 }

  local width = Helper.scaleX(config.renameWidth)
  if menu.contextMenuData.xoffset + width > Helper.viewWidth then
    menu.contextMenuData.xoffset = Helper.viewWidth - width - Helper.frameBorder
  end
  playerPoi.mouseX = nil
  playerPoi.mouseY = nil

  menu.createContextFrame(width, nil, menu.contextMenuData.xoffset, menu.contextMenuData.yoffset)
end

local function Init()
  playerPoi.playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  debug("Initializing PlayerPOI UI extension with PlayerID: " .. tostring(playerPoi.playerId))
  local menuMap = Helper.getMenu("MapMenu") 
  if menuMap == nil or type(menuMap.registerCallback) ~= "function" then
    debug("Failed to get MapMenu or registerCallback is not a function")
    return
  end
  local menuInteract = Helper.getMenu("InteractMenu") 
  if menuInteract == nil or type(menuInteract.registerCallback) ~= "function" then
    debug("Failed to get InteractMenu or registerCallback is not a function")
    return
  end
  trace(string.format("menuMap is %s, menuInteract is %s", tostring(menuMap), tostring(menuInteract)))
  playerPoi.Init(menuMap, menuInteract)
end


Register_OnLoad_Init(Init)
