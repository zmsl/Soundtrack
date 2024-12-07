--[[

	Soundtrack Fix

	Contains fixes for saved data.

--]]

local _version, _build, _date, _tocversion = GetBuildInfo()

--BfA 8.01
--Soundtrack Fix May not be needed anymore to clean up BfA 8.0.1
--Csciguy

function Soundtrack.Fix() 

	-- WoD 6.0.2
	-- GetMapContinents() and GetMapZones() changed return from zones to index and zones
	-- Remove continent and zone numbers
	local continentNames = { GetMapContinents() }
	for i = 1, #continentNames, 2 do
		local cName = continentNames[i];
		Soundtrack.RemoveEvent(ST_ZONE, cName);
		
		local zoneNames = { GetMapZones(i) };
		for j = 1, #zoneNames, 1 do
			local zName = zoneNames[j];
			local zEvent = cName .. "/" .. zName;
			Soundtrack.RemoveEvent(ST_ZONE, zEvent);
		end
	end	
end
