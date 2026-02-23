local ffi = require("ffi")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
  typedef uint64_t NPCSeed;

	typedef struct {
		const char* name;
		const char* colorid;
	} RelationRangeInfo;

	typedef struct {
		size_t queueidx;
		const char* state;
		const char* statename;
		const char* orderdef;
		size_t actualparams;
		bool enabled;
		bool isinfinite;
		bool issyncpointreached;
		bool istemporder;
	} Order;

	typedef struct {
		const char* id;
		const char* name;
		const char* icon;
		const char* description;
		const char* category;
		const char* categoryname;
		bool infinite;
		uint32_t requiredSkill;
	} OrderDefinition;

	typedef struct {
		const char* id;
		const char* name;
		const char* desc;
		uint32_t amount;
		uint32_t numtiers;
		bool canhire;
	} PeopleInfo;

  UniverseID GetPlayerID(void);
  RelationRangeInfo GetUIRelationName(const char* fromfactionid, const char* tofactionid);

	uint32_t GetNumAllFactionShips(const char* factionid);
	uint32_t GetAllFactionShips(UniverseID* result, uint32_t resultlen, const char* factionid);

  bool GetDefaultOrder(Order* result, UniverseID controllableid);

	uint32_t CreateOrder(UniverseID controllableid, const char* orderid, bool default);
	bool EnablePlannedDefaultOrder(UniverseID controllableid, bool checkonly);
	bool GetOrderDefinition(OrderDefinition* result, const char* orderdef);

  void SetFleetName(UniverseID controllableid, const char* fleetname);


	int32_t GetEntityCombinedSkill(UniverseID entityid, const char* role, const char* postid);

	bool IsPerson(NPCSeed person, UniverseID controllableid);
	bool IsPersonTransferScheduled(UniverseID controllableid, NPCSeed person);
  int32_t GetPersonCombinedSkill(UniverseID controllableid, NPCSeed person, const char* role, const char* postid);
	const char* GetPersonName(NPCSeed person, UniverseID controllableid);
	const char* GetPersonRole(NPCSeed person, UniverseID controllableid);
	const char* GetPersonName(NPCSeed person, UniverseID controllableid);
	const char* GetPersonRoleName(NPCSeed person, UniverseID controllableid);
	UniverseID GetInstantiatedPerson(NPCSeed person, UniverseID controllableid);
	bool HasPersonArrived(UniverseID controllableid, NPCSeed person);

	uint32_t GetPeopleCapacity(UniverseID controllableid, const char* macroname, bool includepilot);
  uint32_t GetNumAllRoles(void);
	uint32_t GetPeople2(PeopleInfo* result, uint32_t resultlen, UniverseID controllableid, bool includearriving);

  const char* AssignHiredActor(GenericActor actor, UniverseID targetcontrollableid, const char* postid, const char* roleid, bool checkonly);

	bool HasResearched(const char* wareid);

  double GetCurrentGameTime(void);
]]

local debugLevel = "trace" -- "none", "debug", "trace"

local texts = {}


local playerPoi = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},

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
  RegisterEvent("PlayerPoi.OnRename", playerPoi.onRename)
end

function playerPoi.resetData()
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
  playerPoi.menuMapConfig = menuMap.uix_getConfig()
  trace(string.format("menuMap is %s", tostring(menuMap)))
  playerPoi.Init(menuMap)
end


Register_OnLoad_Init(Init)
