-- Minimap Button Handling

local function debug(msg)
    Soundtrack.Util.DebugPrint(msg)
end

local icon = LibStub("LibDBIcon-1.0")

function SoundtrackMinimap_Initialize()
    if icon:IsRegistered("SoundtrackAddon") then
        icon:Refresh("SoundtrackAddon", SoundtrackAddon.db.profile.minimap)
        return
    end

    local soundtrackMinimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("SoundtrackMinimap", {
        type = "data source",
        text = "Soundtrack",
        icon = "Interface\\Icons\\INV_Misc_Flute_01",
        OnClick = function (self, button) SoundtrackMinimap_IconFrame_OnClick(self, button) end,
        OnTooltipShow = function (tooltip) SoundtrackMinimap_OnTooltipShow(tooltip) end,
    })

    icon:Register("SoundtrackAddon", soundtrackMinimapLDB, SoundtrackAddon.db.profile.minimap)
    end

function SoundtrackMinimap_IconFrame_OnClick(self, button)
    debug("Minimap button OnClick")
    SoundtrackFrame_Toggle()
end

function SoundtrackMinimap_OnTooltipShow(tooltip)
    tooltip:AddLine("Soundtrack")
    tooltip:AddLine(SOUNDTRACK_MINIMAP)
    tooltip:AddLine("|cffeda55fClick|r to toggle Soundtrack")
end

function SoundtrackMinimap_ToggleMinimap()
    SoundtrackAddon.db.profile.minimap.hide = not SoundtrackAddon.db.profile.minimap.hide
    if SoundtrackAddon.db.profile.minimap.hide then
        Soundtrack.TraceFrame(SOUNDTRACK_MINIMAP_BUTTON_HIDDEN)
        icon:Hide("SoundtrackAddon")
    else
        icon:Show("SoundtrackAddon")
    end
end
