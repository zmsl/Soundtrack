--[[
    Soundtrack addon for World of Warcraft

    Mount events functions.
]]

local function debug(msg)
    Soundtrack.TraceEvents(msg)
end


local function Soundtrack_MountEvents_PlayIfTracksAvailable(tableName, eventName)
	local stackTable = Soundtrack.Events.Stack[ST_MOUNT_LVL].tableName
    local stackEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
	if tableName == stackTable and eventName == stackEvent then
		return
	end
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if eventTable[eventName] then
		local trackList = eventTable[eventName].tracks
		if trackList then
			local numTracks = table.getn(trackList)
			if numTracks >= 1 then
				Soundtrack.PlayEvent(tableName, eventName);
			end
		end
	end
end
local function Soundtrack_MountEvents_StopIfTracksAvailable(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	local stackEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
	if eventTable[eventName] and eventName == stackEvent then
		local trackList = eventTable[eventName].tracks
		if trackList then
			local numTracks = table.getn(trackList)
			if numTracks >= 1 then
				Soundtrack.StopEvent(tableName, eventName);
			end
		end
	end
end

local delayTime = 0
local updateTime = .1
local isCurrentlyFlying = false
local InFlight = false

function Soundtrack.MountEvents.OnUpdate(self, deltaT)
    local currentTime = GetTime()
    if currentTime >= delayTime then
	    delayTime = currentTime + updateTime
		if not SoundtrackAddon.db.profile.settings.EnableMiscMusic then
			return
		end
		
		-- Really inefficient way to detect taxis...
		local unitOnTaxi = UnitOnTaxi("player")
		
		if InFlight and not unitOnTaxi then
			InFlight = false
			debug("UnitOnTaxi and in Flight! Stop flight")
			Soundtrack_MountEvents_StopIfTracksAvailable(ST_MISC, SOUNDTRACK_FLIGHT)
		elseif not InFlight and unitOnTaxi then 
			debug("UnitOnTaxi and not in Flight! Start flight")
			InFlight = true
			Soundtrack_MountEvents_PlayIfTracksAvailable(ST_MISC, SOUNDTRACK_FLIGHT)
		end
		
		if not unitOnTaxi then
			local isFlying = IsFlying()
			--local canFly = IsFlyableArea()
			local isMounted = IsMounted()
			
			if isMounted then
				if isFlying or isCurrentlyFlying then
					isCurrentlyFlying = true
					Soundtrack_MountEvents_PlayIfTracksAvailable(ST_MISC, SOUNDTRACK_MOUNT_FLYING)
				else
					Soundtrack_MountEvents_PlayIfTracksAvailable(ST_MISC, SOUNDTRACK_MOUNT_GROUND)
				end
			else
				isCurrentlyFlying = false
				Soundtrack_MountEvents_StopIfTracksAvailable(ST_MISC, SOUNDTRACK_MOUNT_FLYING)
				Soundtrack_MountEvents_StopIfTracksAvailable(ST_MISC, SOUNDTRACK_MOUNT_GROUND)
			end
				
		end
	end
end

function Soundtrack.MountEvents.Initialize()
    Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_MOUNT_GROUND, ST_MOUNT_LVL, true)
    Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_FLIGHT, ST_MOUNT_LVL, true)
    Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_MOUNT_FLYING, ST_MOUNT_LVL, true)
end
