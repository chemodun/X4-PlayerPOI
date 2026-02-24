local ffi = require("ffi")
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

local debugLevel = "none" -- "none", "debug", "trace"

local texts = {
  playerPOI = ReadText(1972092414, 1),
}


local playerPoi = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},
  variableId = "playerPoi",
  tabIcon = "mapst_ol_player_poi",
  poiMacro = "player_poi_01_macro",
  poiMode = "playerPOI",
  posX = nil,
  posY = nil,
  optimizeRename = true
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
  menuMap.registerCallback("createPropertyOwned_on_add_other_objects_infoTableData", playerPoi.prepareTabData)
  menuMap.registerCallback("createPropertyOwned_on_createPropertySection_unassignedships", playerPoi.displayTabData)
  menuMap.registerCallback("onRenderTargetSelect_on_propertyowned_newmode", playerPoi.selectTabForPlayerPoiItems)
  menuInteract.registerCallback("draw_on_start", playerPoi.getMousePosition)
  menuInteract.registerCallback("prepareActions_prepare_custom_action", playerPoi.removeSomeActions)
  RegisterEvent("PlayerPoi.OnRename", playerPoi.onRename)
  RegisterEvent("PlayerPoi.ConfigChanged", playerPoi.onConfigChanged)
  AddUITriggeredEvent("PlayerPoi", "Reloaded")
  playerPoi.setupTab()
end

function playerPoi.onConfigChanged(_, _)
  local variableId = string.format("$%s", playerPoi.variableId)
  local config = GetNPCBlackboard(playerPoi.playerId, variableId)
  if config == nil then
    return
  end
  playerPoi.optimizeRename = config.optimizeRename ~= nil and config.optimizeRename ~= false and config.optimizeRename ~= 0
  debugLevel = config.debugLevel or "none"
  debug("Configuration changed: optimizedRename=" .. tostring(playerPoi.optimizeRename) .. ", debugLevel=" .. tostring(debugLevel))
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
    trace("Checking category with category: " .. tostring(category.category))
    if string.sub(category.category, 1, 10) ~= "custom_tab" then
      if category.category == playerPoi.poiMode then
        trace("Found playerPOI category in menu map config")
      else
        local poiTab = {
          category = playerPoi.poiMode,
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
    local macro = GetComponentData(ConvertStringTo64Bit(tostring(deployable)), "macro")
    if macro == playerPoi.poiMacro then
      trace("Found deployable with matching macro: " .. tostring(deployable))
      playerPoiList[#playerPoiList + 1] = deployable
      table.remove(infoTableData.deployables, i)
    end
  end
  trace("Prepared player POI data with " .. tostring(#playerPoiList) .. " entries")
end

function playerPoi.displayTabData(numDisplayed, instance, ftable, infoTableData)
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return { numdisplayed = numDisplayed }
  end
  infoTableData.playerPOI = infoTableData.playerPOI or {}
  if menu.propertyMode == playerPoi.poiMode then
    numDisplayed = menu.createPropertySection(instance, "owneddeployables", ftable, texts.playerPOI, infoTableData.playerPOI, "-- " .. ReadText(1001, 34) .. " --", nil, numDisplayed, nil, menu.propertySorterType)
  end
  return { numdisplayed = numDisplayed }
end

function playerPoi.getMousePosition(config)
  local menu = playerPoi.menuInteract
  if menu == nil then
    debug("Menu interact is not initialized")
    return
  end
  playerPoi.posX = menu.posX
  playerPoi.posY = menu.posY
end

function playerPoi.removeSomeActions(actions, definedActions)
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
      if action.actiontype == "detach" or string.find(action.actiontype, "collectdeployable") then
        trace("Removing action with actiontype: " .. tostring(action.actiontype))
        table.remove(actions, i)
        definedActions[action.actiontype] = nil
      end
    end
  end
end

function playerPoi.selectTabForPlayerPoiItems(pickedComponent64, newMode)
  trace("pickedComponent64: " .. tostring(pickedComponent64))
  local macro = GetComponentData(pickedComponent64, "macro")
  if macro == playerPoi.poiMacro then
    newMode = playerPoi.poiMode
  end
  return { newmode = newMode }
end


function playerPoi.onRename(_, param)
  trace("onRename called with param: " .. tostring(param) .. " and optimizedRename: " .. tostring(playerPoi.optimizeRename))
  local object = ConvertStringTo64Bit(tostring(param))
  local menu = playerPoi.menuMap
  if menu == nil then
    debug("Menu map is not initialized")
    return
  end
  local config = playerPoi.menuMapConfig
  local posX = playerPoi.posX
  local posY = playerPoi.posY
  if playerPoi.optimizeRename ~= true or posX == nil or posY == nil then
    local mousePos = C.GetCenteredMousePos()
    posX = mousePos.x + Helper.viewWidth / 2
    posY = mousePos.y + Helper.viewHeight / 2
  end

  menu.contextMenuMode = "rename"
  menu.contextMenuData = { component = object, xoffset = posX, yoffset = posY }

  local width = Helper.scaleX(config.renameWidth)
  if menu.contextMenuData.xoffset + width > Helper.viewWidth then
    menu.contextMenuData.xoffset = Helper.viewWidth - width - Helper.frameBorder
  end
  playerPoi.posX = nil
  playerPoi.posY = nil

  menu.createContextFrame(width, nil, menu.contextMenuData.xoffset, menu.contextMenuData.yoffset)
end

local function Init()
  playerPoi.playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  playerPoi.onConfigChanged()
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
