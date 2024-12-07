--[[
    Soundtrack addon for World of Warcraft

    Zone events functions.
    Functions that manage zone change events.
]]


Soundtrack.ZoneEvents = {}

local function debug(msg)
	Soundtrack.TraceZones(msg)
end

--NEW IN PROGRESS Map Changes BfA 8.0.1
-- local function fillContinentZoneList(continent)
	-- continentZoneList[continent] = {}
	-- local children = C_Map.GetMapChildrenInfo(continent)
	-- if children then
		-- for _, child in ipairs(children) do
			-- if child.mapType == Enum.UIMapType.Zone then
				-- table.insert(continentZoneList[continent], child.mapID)
			-- end
		-- end
	-- end
-- end

-- Finds the continent name
local function FindContinentByZone()
	local inInstance, instanceType = IsInInstance();
	if inInstance then
		if instanceType == "arena" or instanceType == "pvp" then
			return SOUNDTRACK_PVP, nil;
		end
		if instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
			return SOUNDTRACK_INSTANCES, nil;
		end
	end
	
	-- Get continent
	local c = MapUtil.GetMapParentInfo(C_Map.GetBestMapForUnit("player"), Enum.UIMapType.Continent, true)
	local continent
	if c ~= nil then
		continent = c.name
	end
	
	-- Get zone
	-- Test that map has a zone map (i.e. Legion Dalaran is labeled dungeon, no zone map)
	local z = MapUtil.GetMapParentInfo(C_Map.GetBestMapForUnit("player"),3)
	local zone = GetRealZoneText()
	if z ~= nil then 
		zone = z.name
	end
	
	if continent == nil then continent = SOUNDTRACK_UNKNOWN	end

	return continent, zone
end

-- After migration, zone events have no priorities set. We only
-- discover them as we figure out which parent zones exist
local function AssignPriority(tableName, eventName, priority)
    local event = Soundtrack.GetEventByName(tableName, eventName)
    if event then
        event.priority = priority
    end
end


function Soundtrack_ZoneEvents_AddZones()
	local zoneText = GetRealZoneText();
	if zoneText == nil then return end
	
    local continentName, zoneName = FindContinentByZone()
    local zoneSubText = GetSubZoneText()
    local minimapZoneText = GetMinimapZoneText()
	
	if zoneName ~= nil and zoneName ~= zoneText then
		if zoneSubText ~= nil and zoneSubText ~= "" then
			minimapZoneText = zoneSubText
		end
		if zoneText ~= nil and zoneText ~= "" then
			zoneSubText = zoneText
		end
		zoneText = zoneName
	end
	
    -- Construct full zone path
    
    local zoneText1, zoneText2, zoneText3, zoneText4;
    
    local zonePath;
        
    if not Soundtrack.IsNullOrEmpty(continentName) then
        zoneText1 = continentName;
		debug("AddZone Continent: " .. zoneText1);
        zonePath = continentName;
    end
        
    if not Soundtrack.IsNullOrEmpty(zoneText) then
        zoneText2 = continentName .. "/" .. zoneText;
		debug("AddZone ZoneText: " .. zoneText2);
        zonePath = zoneText2;
        --Soundtrack.Events.RenameEvent(ST_ZONE, zoneText, zoneText2);
    end
    

    if zoneText ~= zoneSubText and not Soundtrack.IsNullOrEmpty(zoneSubText) then
        zoneText3 = zonePath .. "/" .. zoneSubText;
		debug("AddZone SubZoneText: " .. zoneText3);
        zonePath = zoneText3;
        --Soundtrack.Events.RenameEvent(ST_ZONE, zoneSubText, zoneText3);
    end
    
    if zoneText ~= minimapZoneText and zoneSubText ~= minimapZoneText and not Soundtrack.IsNullOrEmpty(minimapZoneText) then
        zoneText4 = zonePath .. "/" .. minimapZoneText;
		debug("AddZone MinimapZoneText: " .. zoneText4);
        zonePath = zoneText4;
        --Soundtrack.Events.RenameEvent(ST_ZONE, minimapZoneText, zoneText4);
    end
	
    
    debug("AddZone Zone: " .. zonePath);
	
    if zoneText4 then
		local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
		if eventTable[zoneText4] == nil then
			Soundtrack.AddEvent(ST_ZONE, zoneText4, ST_MINIMAP_LVL, true)
        end
		AssignPriority(ST_ZONE, zoneText4, ST_MINIMAP_LVL)
    end
    
    if zoneText3 then
		local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
		if eventTable[zoneText3] == nil then
			Soundtrack.AddEvent(ST_ZONE, zoneText3, ST_SUBZONE_LVL, true)
		end
		AssignPriority(ST_ZONE, zoneText3, ST_SUBZONE_LVL)
    end
    
    if zoneText2 then
		local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
		if eventTable[zoneText2] == nil then
			Soundtrack.AddEvent(ST_ZONE, zoneText2, ST_ZONE_LVL, true)
        end
		AssignPriority(ST_ZONE, zoneText2, ST_ZONE_LVL)
    end
    
    if zoneText1 then
		local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
		if eventTable[zoneText1] == nil then
			Soundtrack.AddEvent(ST_ZONE, zoneText1, ST_CONTINENT_LVL, true)
		end
		AssignPriority(ST_ZONE, zoneText1, ST_CONTINENT_LVL)
    end
   
end

local function OnZoneChanged()
	local zoneText = GetRealZoneText();
	if zoneText == nil then return end
	
    local continentName, zoneName = FindContinentByZone()
    local zoneSubText = GetSubZoneText()
    local minimapZoneText = GetMinimapZoneText()
	
	if zoneName ~= nil and zoneName ~= zoneText then
		if zoneSubText ~= nil and zoneSubText ~= "" then
			minimapZoneText = zoneSubText
		end
		if zoneText ~= nil and zoneText ~= "" then
			zoneSubText = zoneText
		end
		zoneText = zoneName
	end
	
    -- Construct full zone path
    local zoneText1, zoneText2, zoneText3, zoneText4;
    local zonePath;
        
    if not Soundtrack.IsNullOrEmpty(continentName) then
        zoneText1 = continentName;
		debug("OnZoneChanged Continent: " .. zoneText1);
        zonePath = continentName;
    end
        
    if not Soundtrack.IsNullOrEmpty(zoneText) then
        zoneText2 = continentName .. "/" .. zoneText;
		debug("OnZoneChanged ZoneText: " .. zoneText2);
        zonePath = zoneText2;
        --Soundtrack.Events.RenameEvent(ST_ZONE, zoneText, zoneText2);
    end
    
    if zoneText ~= zoneSubText and not Soundtrack.IsNullOrEmpty(zoneSubText) then
        zoneText3 = zonePath .. "/" .. zoneSubText;
		debug("OnZoneChanged SubZoneText: " .. zoneText3);
        zonePath = zoneText3;
        --Soundtrack.Events.RenameEvent(ST_ZONE, zoneSubText, zoneText3);
    end
    
    if zoneText ~= minimapZoneText and zoneSubText ~= minimapZoneText and not Soundtrack.IsNullOrEmpty(minimapZoneText) then
        zoneText4 = zonePath .. "/" .. minimapZoneText;
		debug("OnZoneChanged MinimapZoneText: " .. zoneText4);
        zonePath = zoneText4;
        --Soundtrack.Events.RenameEvent(ST_ZONE, minimapZoneText, zoneText4);
    end
	
    
   -- debug("Zone: " .. zonePath);
	
    if zoneText4 then
        if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			if eventTable[zoneText4] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText4, ST_MINIMAP_LVL, true)
			end
        end
		AssignPriority(ST_ZONE, zoneText4, ST_MINIMAP_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText4, false);
    else
        Soundtrack.StopEventAtLevel(ST_MINIMAP_LVL);
    end
    
    if zoneText3 then
        if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			if eventTable[zoneText3] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText3, ST_SUBZONE_LVL, true)
			end
        end
		AssignPriority(ST_ZONE, zoneText3, ST_SUBZONE_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText3, false);
    else
        Soundtrack.StopEventAtLevel(ST_SUBZONE_LVL);
    end
    
    if zoneText2 then
        if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			if eventTable[zoneText2] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText2, ST_ZONE_LVL, true)
			end
        end
		AssignPriority(ST_ZONE, zoneText2, ST_ZONE_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText2, false);
    else        
        Soundtrack.StopEventAtLevel(ST_ZONE_LVL);
    end
    
    if zoneText1 then
        if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			if eventTable[zoneText1] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText1, ST_CONTINENT_LVL, true)
			end
        end
		AssignPriority(ST_ZONE, zoneText1, ST_CONTINENT_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText1, false);
    else        
        Soundtrack.StopEventAtLevel(ST_CONTINENT_LVL);
    end
   
end

function Soundtrack.ZoneEvents.OnLoad(self)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("VARIABLES_LOADED")
end
    

local delayTime = 0
local updateTime = 1
local zoneType = nil
	
function Soundtrack.ZoneEvents.OnUpdate(self)
	
	local currentTime = GetTime()
	
	if currentTime >= delayTime then
		delayTime = currentTime + updateTime
		
		local inInstance, newZoneType = IsInInstance();
		if not newZoneType == zoneType then
			zoneType = newZoneType
			OnZoneChanged()
		end
	end
end	

function Soundtrack.ZoneEvents.OnEvent(self, event, ...)
    if not SoundtrackAddon.db.profile.settings.EnableZoneMusic then
        return
    end

	debug(event);
	
    if event == "ZONE_CHANGED" or 
       event == "ZONE_CHANGED_INDOORS" or
	   event == "ZONE_CHANGED_NEW_AREA" or
       event == "VARIABLES_LOADED" then
		debug("Event: "..event);
        OnZoneChanged()
    end
end    

function Soundtrack.ZoneEvents.Initialize()
	-- Add Instances and PVP 'continents'
    Soundtrack.AddEvent(ST_ZONE, SOUNDTRACK_INSTANCES, ST_CONTINENT_LVL, true);
	Soundtrack.AddEvent(ST_ZONE, SOUNDTRACK_PVP, ST_CONTINENT_LVL, true);	
	
	-- GetMapChildrenInfo(mapId[, mapType])
	-- mapType
	-- 0 = "Cosmic"
	-- 1 = "World"
	-- 2 = "Continent"
	-- 3 = "Zone"
	-- 4 = "Dungeon"
	-- 5 = "Micro"
	-- 6 = "Orphan"
	
	--[1]={ mapType=2, mapID=572, name="Draenor", parentMapID=946}
	
	-- Get all continents
	local continents = C_Map.GetMapChildrenInfo(946,2,1)
	if continents then
		-- Add continents
		for k,v in pairs(continents) do
			local continentName = v.name
			Soundtrack.AddEvent(ST_ZONE, continentName, ST_CONTINENT_LVL, true)
			-- Add zones for each continent
			local zones = C_Map.GetMapChildrenInfo(v.mapID,3)
			for a,b in pairs(zones) do
				local zoneName = continentName.."/"..b.name
				Soundtrack.AddEvent(ST_ZONE, zoneName, ST_ZONE_LVL, true)
				-- Add subzones for each zone
				--[[ Commented out b/c Subzones based on minimap, not map.
                local subzones = C_Map.GetMapChildrenInfo(b.mapID,3)
                for c,d in pairs(subzones) do
                    local subzoneName = zoneName.."/"..d.name
                    Soundtrack.AddEvent(ST_ZONE, subzoneName, ST_SUBZONE_LVL, true)
                end --]]
			end
		end
	end
end
