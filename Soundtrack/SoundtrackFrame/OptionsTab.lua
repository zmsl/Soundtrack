
OptionsTab = {}

function OptionsTab.Initialize()
    OptionsTab_PlaybackButtonsLocationDropDown_OnLoad()
    OptionsTab_SilenceDropDown_OnLoad()
    OptionsTab_LowHealthPercentDropDown_OnLoad()
    OptionsTab_BattleCooldownDropDown_OnLoad()
end

function OptionsTab.Refresh()
    local s = SoundtrackAddon.db.profile.settings

    OptionsTab_EnableMinimapButton:SetChecked(not SoundtrackAddon.db.profile.minimap.hide)
    OptionsTab_EnableDebugMode:SetChecked(s.Debug)
    OptionsTab_ShowTrackInformation:SetChecked(s.ShowTrackInformation)
    OptionsTab_LockNowPlayingFrame:SetChecked(s.LockNowPlayingFrame)
    OptionsTab_ShowDefaultMusic:SetChecked(s.ShowDefaultMusic)
    OptionsTab_ShowPlaybackControls:SetChecked(s.ShowPlaybackControls)
    OptionsTab_LockPlaybackControls:SetChecked(s.LockPlaybackControls)
    OptionsTab_ShowEventStack:SetChecked(s.ShowEventStack)
    OptionsTab_AutoAddZones:SetChecked(s.AutoAddZones)
    OptionsTab_AutoEscalateBattleMusic:SetChecked(s.EscalateBattleMusic)
    OptionsTab_YourEnemyLevelOnly:SetChecked(s.YourEnemyLevelOnly)

    OptionsTab_EnableZoneMusic:SetChecked(s.EnableZoneMusic)
    OptionsTab_EnableBattleMusic:SetChecked(s.EnableBattleMusic)
    OptionsTab_EnableMiscMusic:SetChecked(s.EnableMiscMusic)
    OptionsTab_EnableCustomMusic:SetChecked(s.EnableCustomMusic)

    OptionsTab_HidePlaybackButtons:SetChecked(s.HideControlButtons)

    local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
    Soundtrack.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
    if cvar_LoopMusic == "0" then
        OptionsTab_LoopMusic:SetChecked(false)
    else
        OptionsTab_LoopMusic:SetChecked(true)
    end
end

-- General check boxes

function OptionsTab_ToggleLoopMusic()
    if OptionsTab_LoopMusic:GetChecked() == 1 then
        SetCVar("Sound_ZoneMusicNoDelay", 1, "SoundtrackSound_ZoneMusicNoDelay_1")
        local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
        Soundtrack.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
    else
        SetCVar("Sound_ZoneMusicNoDelay", 0, "SoundtrackSound_ZoneMusicNoDelay_0")
        local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
        Soundtrack.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
    end
end

function OptionsTab_ToggleShowPlaybackControls()
    SoundtrackAddon.db.profile.settings.ShowPlaybackControls = not SoundtrackAddon.db.profile.settings.ShowPlaybackControls
    SoundtrackFrame_RefreshPlaybackControls()
end

function OptionsTab_ToggleMinimapButton()
    SoundtrackMinimap_ToggleMinimap()

    if not SoundtrackAddon.db.profile.settings.EnableMinimapButton then
    end
end

function OptionsTab_ToggleDebugMode()
    SoundtrackAddon.db.profile.settings.Debug = not SoundtrackAddon.db.profile.settings.Debug
    Soundtrack.Util.InitDebugChatFrame()
end

function OptionsTab_ToggleShowTrackInformation()
    SoundtrackAddon.db.profile.settings.ShowTrackInformation = not SoundtrackAddon.db.profile.settings.ShowTrackInformation
end

function OptionsTab_ToggleShowEventStack()
    SoundtrackAddon.db.profile.settings.ShowEventStack = not SoundtrackAddon.db.profile.settings.ShowEventStack
    SoundtrackFrame_RefreshPlaybackControls()
end

function OptionsTab_ToggleShowDefaultMusic()
    SoundtrackAddon.db.profile.settings.ShowDefaultMusic = not SoundtrackAddon.db.profile.settings.ShowDefaultMusic
    _TracksLoaded = false
    LoadTracks()
end

-- Playback button locations

local locations = { "LEFT", "TOPLEFT", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOMLEFT" }

local function GetPlaybackButtonsLocations()
    return {
        "Left",
        "Top Left",
        "Top Right",
        "Right",
        "Bottom Right",
        "Bottom Left",
    }
end

local function GetCurrentPlaybackButtonsLocation()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return 1
    end

    local i
    for i = 1, #(locations), 1 do
        if SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition == locations[i] then
            return i
        end
    end

    return 1
end

function OptionsTab_PlaybackButtonsLocationDropDown_OnLoad()
    SoundtrackFrame.selectedLocation = GetCurrentPlaybackButtonsLocation()
    UIDropDownMenu_Initialize(OptionsTab_PlaybackButtonsLocationDropDown, OptionsTab_PlaybackButtonsLocationDropDown_Initialize)
end

function OptionsTab_PlaybackButtonsLocationDropDown_Initialize()
    OptionsTab_PlaybackButtonsLocationDropDown_LoadLocations(GetPlaybackButtonsLocations())
    UIDropDownMenu_SetSelectedID(OptionsTab_PlaybackButtonsLocationDropDown, SoundtrackFrame.selectedLocation)
    UIDropDownMenu_SetWidth(OptionsTab_PlaybackButtonsLocationDropDown, 160)
end

function OptionsTab_PlaybackButtonsLocationDropDown_LoadLocations(locationsTexts)
    local currentLocation = SoundtrackFrame.selectedLocation
    local info

    for i, locationText in ipairs(locationsTexts) do
        local checked = false
        if currentLocation == i then
            checked = true
            UIDropDownMenu_SetText(OptionsTab_PlaybackButtonsLocationDropDown, locationText)
        end

        info = {}
        info.text = locationText
        info.func = OptionsTab_PlaybackButtonsLocationDropDown_OnClick
        UIDropDownMenu_AddButton(info)
    end
end

function OptionsTab_PlaybackButtonsLocationDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(OptionsTab_PlaybackButtonsLocationDropDown, self:GetID())
    SoundtrackFrame.selectedLocation = self:GetID()
    -- Save settings.
    SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition = locations[SoundtrackFrame.selectedLocation]
    SoundtrackFrame_RefreshPlaybackControls()
end

-- Battle cooldown

local cooldowns = { 0, 1, 2, 3, 5, 10, 15, 30 }

local function GetBattleCooldowns()
    return {
        "No cooldown",
        "1 second",
        "2 seconds",
        "3 seconds",
        "5 seconds",
        "10 seconds",
        "15 seconds",
        "30 seconds",
    }
end

local function GetCurrentBattleCooldown()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return 1
    end

    -- TODO replace with IndexOf
    for i, c in ipairs(cooldowns) do
        if SoundtrackAddon.db.profile.settings.BattleCooldown == c then
            return i
        end
    end

    return 1
end

function OptionsTab_BattleCooldownDropDown_OnLoad()
    SoundtrackFrame.selectedCooldown = GetCurrentBattleCooldown()
    UIDropDownMenu_Initialize(OptionsTab_BattleCooldownDropDown, OptionsTab_BattleCooldownDropDown_Initialize)
end

function OptionsTab_BattleCooldownDropDown_Initialize()
    OptionsTab_BattleCooldownDropDown_LoadCooldowns(GetBattleCooldowns())
    UIDropDownMenu_SetSelectedID(OptionsTab_BattleCooldownDropDown, SoundtrackFrame.selectedCooldown)
    UIDropDownMenu_SetWidth(OptionsTab_BattleCooldownDropDown, 130)
end

function OptionsTab_BattleCooldownDropDown_LoadCooldowns(cooldownTexts)
    local currentCooldown = SoundtrackFrame.selectedCooldown
    local info

    for i, cooldownText in ipairs(cooldownTexts) do
        local checked = nil
        if currentCooldown == i then
            checked = 1
            UIDropDownMenu_SetText(OptionsTab_BattleCooldownDropDown, cooldownText)
        end

        info = {}
        info.text = cooldownText
        info.func = OptionsTab_BattleCooldownDropDown_OnClick
        info.checked = checked
        UIDropDownMenu_AddButton(info)
    end
end

function OptionsTab_BattleCooldownDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(OptionsTab_BattleCooldownDropDown, self:GetID())
    SoundtrackFrame.selectedCooldown = self:GetID()
    -- Save settings.
    SoundtrackAddon.db.profile.settings.BattleCooldown = cooldowns[SoundtrackFrame.selectedCooldown]
end

-- Low health percent dropdown

local lowhealthpercents = { 0, .05, .1, .15, .20, .25, .3, .35, .4, .45, .5 }

local function GetLowHealthPercents()
    return {
        "0%",
        "5%",
        "10%",
        "15%",
        "20%",
        "25%",
        "30%",
        "35%",
        "40%",
        "45%",
        "50%",
    }
end

local function GetCurrentLowHealthPercent()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return 1
    end

    local i
    for i = 1, #(lowhealthpercents), 1 do
        if SoundtrackAddon.db.profile.settings.LowHealthPercent == lowhealthpercents[i] then
            return i
        end
    end

    return 0
end

function OptionsTab_LowHealthPercentDropDown_OnLoad()
    SoundtrackFrame.selectedLowHealthPercent = GetCurrentLowHealthPercent()
    UIDropDownMenu_SetSelectedID(OptionsTab_LowHealthPercentDropDown, SoundtrackFrame.selectedLowHealthPercent)
    UIDropDownMenu_Initialize(OptionsTab_LowHealthPercentDropDown, OptionsTab_LowHealthPercentDropDown_Initialize)
    UIDropDownMenu_SetWidth(OptionsTab_LowHealthPercentDropDown, 130)
end

function OptionsTab_LowHealthPercentDropDown_LoadPercents(lowHealthTexts)
    local currentLowHealthPercent = SoundtrackFrame.selectedLowHealthPercent
    local info

    for i = 1, #(lowHealthTexts), 1 do
        local checked = nil
        if (currentLowHealthPercent == i) then
            checked = 1
            UIDropDownMenu_SetText(OptionsTab_LowHealthPercentDropDown, lowHealthTexts[i])
        end

        info = {}
        info.text = lowHealthTexts[i]
        info.func = OptionsTab_LowHealthPercentDropDown_OnClick
        info.checked = checked
        UIDropDownMenu_AddButton(info)
    end
end

function OptionsTab_LowHealthPercentDropDown_Initialize()
    OptionsTab_LowHealthPercentDropDown_LoadPercents(GetLowHealthPercents())
end

function OptionsTab_LowHealthPercentDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(OptionsTab_LowHealthPercentDropDown, self:GetID())
    SoundtrackFrame.selectedLowHealthPercent = self:GetID()
    -- Save settings.
    SoundtrackAddon.db.profile.settings.LowHealthPercent = lowhealthpercents[SoundtrackFrame.selectedLowHealthPercent]
end

-- Silence dropdown

local silences = { 0, 5, 10, 20, 30, 40, 60, 90, 120, 300 }

local function GetSilences()
    return {
        "No silence",
        "5 seconds",
        "10 seconds",
        "20 seconds",
        "30 seconds",
        "40 seconds",
        "1 minute",
        "1.5 minute",
        "2 minutes",
        "5 minutes"
    }
end

local function GetCurrentSilence()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return 1
    end

    -- Replace with index of
    local savedSilenceSeconds = SoundtrackAddon.db.profile.settings.Silence
    local i
    for i = 1, #(silences), 1 do
        if savedSilenceSeconds == silences[i] then
            return i
        end
    end

    return 1
end

function OptionsTab_SilenceDropDown_OnLoad()
    SoundtrackFrame.selectedSilence = GetCurrentSilence()
    UIDropDownMenu_Initialize(OptionsTab_SilenceDropDown, OptionsTab_SilenceDropDown_Initialize)
    UIDropDownMenu_SetWidth(OptionsTab_SilenceDropDown, 130)
end

function OptionsTab_SilenceDropDown_Initialize()
    OptionsTab_SilenceDropDown_LoadSilences(GetSilences())
    UIDropDownMenu_SetSelectedID(OptionsTab_SilenceDropDown, SoundtrackFrame.selectedSilence)
end

function OptionsTab_SilenceDropDown_LoadSilences(silencesTexts)
    local currentSilence = SoundtrackFrame.selectedSilence
    local info

    for i = 1, #(silencesTexts), 1 do
        local checked = false
        if (currentSilence == i) then
            checked = true
        end

        info = UIDropDownMenu_CreateInfo()
        info.text = silencesTexts[i]
        info.func = OptionsTab_SilenceDropDown_OnClick
        info.checked = checked
        UIDropDownMenu_AddButton(info)
    end
end

function OptionsTab_SilenceDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(OptionsTab_SilenceDropDown, self:GetID())
    SoundtrackFrame.selectedSilence = self:GetID()
    SoundtrackAddon.db.profile.settings.Silence = silences[SoundtrackFrame.selectedSilence]
end
