local EVENTS_TO_DISPLAY = 21
local TRACKS_TO_DISPLAY = 16
local ASSIGNED_TRACKS_TO_DISPLAY = 7
EVENTS_ITEM_HEIGHT = 21

--DEBUG = 1

local SEVT = {
    SelectedEventsTable = nil,
}

local eventTypes = {
    "Event Script",
    "Update Script",
    "Buff",
    "Debuff"
}

function SoundtrackFrame_Initialize()
    OptionsTab.Initialize()
end

function Soundtrack.IndexOf(_table, value)
    if _table == nil then
        return 0
    end

    for i = 1, #(_table) do
        if _table[i] == value then
            return i
        end
    end

    return 0
end

local eventSubFrames = {
    "SoundtrackFrameAssignedTracks",
    "SoundtrackFrame_EventSettings"
}

function SoundtrackFrame_ShowSubFrame(frameName)
    for index, value in ipairs(eventSubFrames) do
        if value == frameName then
            _G[value]:Show()
        else
            _G[value]:Hide()
        end
    end
end

function SoundtrackFrame_RefreshEventSettings()
end

function SoundtrackFrame_OnSelectedEventTabChanged()
    if SoundtrackFrame.showAssignedFrame then
        SoundtrackFrame_ShowSubFrame("SoundtrackFrameAssignedTracks")
        SoundtrackFrame_RefreshAssignedTracks()
    else
        SoundtrackFrame_ShowSubFrame("SoundtrackFrame_EventSettings")
        SoundtrackFrame_RefreshEventSettings()
    end
end

SoundtrackFrame_SelectedEvent = nil
SoundtrackFrame_SelectedTrack = nil

local function GetFlatEventsTable()
    return Soundtrack_FlatEvents[SEVT.SelectedEventsTable]
end

local suspendRenameEvent = false

function SoundtrackFrame_OnLoad(self)
    SoundtrackFrame.showAssignedFrame = true

    tinsert(UISpecialFrames, "SoundtrackFrame")

    PanelTemplates_SetNumTabs(self, 10)
    PanelTemplates_SetTab(self, 1)
end

function SoundtrackFrame_OnEvent(self, event, ...)
end

local function RefreshEventSettings()

    if SoundtrackFrame_SelectedEvent then
        suspendRenameEvent = true
        _G["SoundtrackFrame_EventName"]:SetText(SoundtrackFrame_SelectedEvent)
        suspendRenameEvent = false

        local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
        local event = eventTable[SoundtrackFrame_SelectedEvent]
        if event then
            SoundtrackFrame_RandomCheckButton:SetChecked(event.random)
            SoundtrackFrame_ContinuousCheckBox:SetChecked(event.continuous)
            SoundtrackFrame_SoundEffectCheckBox:SetChecked(event.soundEffect)
        end
    end
end

local function GetTabIndex(tableName)
    if (tableName == "Battle") then
        return 1
    elseif (tableName == "Boss") then
        return 2
    elseif (tableName == "Zone") then
        return 3
    elseif (tableName == "Dance") then
        return 4
    elseif (tableName == "Misc") then
        return 5
    elseif (tableName == "Custom") then
        return 6
    elseif (tableName == "Playlists") then
        return 7
    else
        return 0
    end
end

-- Makes sure we select the correct tab that
-- contains the currently playing event.
local function SelectActiveTab()
    local stackLevel = Soundtrack.Events.GetCurrentStackLevel()

    if stackLevel > 0 then
        -- Select currently playing table tab
        Soundtrack.TraceFrame("Selecting currently playing tab")
        local tableName = Soundtrack.Events.Stack[stackLevel].tableName
        SEVT.SelectedEventsTable = tableName
        PanelTemplates_SetTab(SoundtrackFrame, GetTabIndex(tableName))
        SoundtrackFrame_OnTabChanged()
    end

end

function SoundtrackFrame_StatusBarSetProgress(statusBarID, max, current)

    -- Skill bar objects
    local statusBar = _G[statusBarID]
    local statusBarBackground = _G[statusBarID .. "Background"]
    local statusBarFillBar = _G[statusBarID .. "FillBar"]
    local statusBarLabel = _G[statusBarID .. "Text1"]

    statusBarFillBar:Hide()
    statusBarBackground:Hide()

    -- Set bar color depending on skill cost
    if max then
        statusBar:SetStatusBarColor(0.0, 0.75, 0.0, 0.5)
        statusBarBackground:SetVertexColor(0.0, 0.5, 0.0, 0.5)
        statusBarFillBar:SetVertexColor(0.0, 1.0, 0.0, 0.5)
    else
        statusBar:SetStatusBarColor(0.25, 0.25, 0.25)
        statusBar:SetMinMaxValues(0, 0)
        statusBar:SetValue(1)
        statusBarBackground:SetVertexColor(0.75, 0.75, 0.75, 0.5)

        --statusBar:SetStatusBarColor(0.5, 0.5, 0.5, 0.5)
        --statusBarBackground:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        statusBarFillBar:Hide()
        --statusBarFillBar:SetVertexColor(1.0, 1.0, 1.0, 0.5) 
        return
    end

    statusBar:SetMinMaxValues(0, max)
    statusBar:SetValue(current)
    if current <= max and max ~= 0 then
        local fillBarWidth = (current / max) * (statusBar:GetWidth() - 4)
        statusBarFillBar:SetPoint("TOPRIGHT", statusBarLabel, "TOPLEFT", fillBarWidth, 0)
        statusBarFillBar:Show()
    else
        statusBarFillBar:Hide()
    end
end

-- Lunaqua: Moves the title
local MAX_TITLE_LENGTH = 30;
local backwards = true;
local hold = 0;
local holdLimit = 4;
local titleDelayTime = 0
local titleUpdateTime = .5
local function SoundtrackFrame_TimeToUpdateTitle()
    local titleCurrentTime = GetTime()
    if titleCurrentTime < titleDelayTime then
        return false
    else
        titleDelayTime = titleCurrentTime + titleUpdateTime
        return true
    end
end
local function SoundtrackFrame_NewMovingTitle(title, oldTitle)
    local titleClean = Soundtrack.Util.CleanString(title)
    if oldTitle == nil then
        backwards = false
        return string.sub(titleClean, 1, MAX_TITLE_LENGTH)
    end

    -- Check old title length
    if string.len(oldTitle) > MAX_TITLE_LENGTH then
        oldTitle = string.sub(oldTitle, 1, MAX_TITLE_LENGTH)
    end
    -- Check if oldTitle is part of title
    local oldTitleClean = Soundtrack.Util.CleanString(oldTitle)
    local arg1, arg2 = string.find(titleClean, oldTitleClean, 1, true)
    -- arg1 = starting position where string found
    -- arg2 = ending position of string found, inclusive

    if arg1 == nil then
        -- Different track name, start up a new title.
        backwards = false
        if string.len(titleClean) > MAX_TITLE_LENGTH then
            return string.sub(titleClean, 1, MAX_TITLE_LENGTH)
        else
            return titleClean
        end
    elseif SoundtrackFrame_TimeToUpdateTitle() then
        if string.len(titleClean) > MAX_TITLE_LENGTH then
            if backwards == true then
                -- Going backwards, check if at front of string
                if arg1 == 1 then
                    if hold < holdLimit then
                        -- Hold at end until hold = holdLimit
                        hold = hold + 1
                        return oldTitleClean
                    elseif hold >= holdLimit then
                        -- hold = holdLimit, string goes forward
                        hold = 0
                        backwards = false;
                        return string.sub(titleClean, arg1 + 1, arg2 + 1)
                    end
                else
                    return string.sub(titleClean, arg1 - 1, arg2 - 1)
                end
            else
                -- Going forwards, check if at end of string
                if arg2 == string.len(titleClean) then
                    if hold < holdLimit then
                        -- Hold at end until hold = holdLimit
                        hold = hold + 1
                        return oldTitleClean
                    elseif hold >= holdLimit then
                        -- hold = holdLimit, string goes backwards now
                        hold = 0
                        backwards = true;
                        return string.sub(titleClean, arg1 - 1, arg2 - 1)
                    end
                else
                    return string.sub(titleClean, arg1 + 1, arg2 + 1)
                end
            end
        else
            return titleClean;
        end
    else
        return oldTitleClean
    end
end
function SoundtrackFrame_MovingTitle()
    -- Refresh event
    local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
    local currentTrack = Soundtrack.Library.CurrentlyPlayingTrack

    local track
    if Soundtrack_Tracks ~= nil then
        -- Check to avoid nil error
        track = Soundtrack_Tracks[currentTrack]
    else
        track = false
    end
    if not track then
        SoundtrackFrame_StatusBarTrackText1:SetText(SOUNDTRACK_NO_TRACKS_PLAYING)
        SoundtrackFrame_StatusBarTrackText2:SetText("")
    else
        local oldTitle = SoundtrackFrame_StatusBarTrackText1:GetText()
        if SoundtrackFrame.nameHeaderType == "filePath" then
            local text = SoundtrackFrame_NewMovingTitle(track.title, oldTitle)
            SoundtrackFrame_StatusBarTrackText1:SetText(text)
        elseif SoundtrackFrame.nameHeaderType == "fileName" then
            local text = SoundtrackFrame_NewMovingTitle(track.title, oldTitle)
            SoundtrackFrame_StatusBarTrackText1:SetText(text)
        else
            if track.title == nil or track.title == "" then
                local text = SoundtrackFrame_NewMovingTitle(currentTrack, oldTitle)
                SoundtrackFrame_StatusBarTrackText1:SetText(text)
            else
                local text = SoundtrackFrame_NewMovingTitle(track.title, oldTitle)
                SoundtrackFrame_StatusBarTrackText1:SetText(text)
            end
        end
    end

    SoundtrackControlFrame_StatusBarTrackText1:SetText(SoundtrackFrame_StatusBarTrackText1:GetText())
    SoundtrackControlFrame_StatusBarTrackText2:SetText(SoundtrackFrame_StatusBarTrackText2:GetText())
end

function SoundtrackFrame_RefreshTrackProgress()
    if not Soundtrack.Library.CurrentlyPlayingTrack then
        SoundtrackFrame_StatusBarSetProgress("SoundtrackFrame_StatusBarTrack", nil, nil)
        SoundtrackFrame_StatusBarSetProgress("SoundtrackControlFrame_StatusBarTrack", nil, nil)
        return
    end

    local track = Soundtrack_Tracks[Soundtrack.Library.CurrentlyPlayingTrack]
    if not track then
        SoundtrackFrame_StatusBarSetProgress("SoundtrackFrame_StatusBarTrack", nil, nil)
        SoundtrackFrame_StatusBarSetProgress("SoundtrackControlFrame_StatusBarTrack", nil, nil)
        return
    end

    local timer = Soundtrack.Timers.Get("FadeOut")
    local currentTime = 0
    local duration = track.length
    if timer then
        currentTime = GetTime() - timer.Start
    end

    local textRemain = Soundtrack.Util.FormatDuration(duration - currentTime)
    SoundtrackFrame_StatusBarTrackText2:SetText(textRemain)
    SoundtrackControlFrame_StatusBarTrackText2:SetText(textRemain)

    SoundtrackFrame_StatusBarSetProgress("SoundtrackFrame_StatusBarTrack", duration, currentTime)
    SoundtrackFrame_StatusBarSetProgress("SoundtrackControlFrame_StatusBarTrack", duration, currentTime)
end

local function SoundtrackFrame_RefreshCurrentlyPlaying()
    -- Refresh event
    local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
    local currentTrack = Soundtrack.Library.CurrentlyPlayingTrack

    if stackLevel == 0 then
        SoundtrackFrame_StatusBarEventText1:SetText(SOUNDTRACK_NO_EVENT_PLAYING)
        SoundtrackFrame_StatusBarEventText2:SetText("")
        SoundtrackFrame_StatusBarSetProgress("SoundtrackFrame_StatusBarEvent", nil, nil)
        SoundtrackFrame_StatusBarSetProgress("SoundtrackControlFrame_StatusBarEvent", nil, nil)
    else
        local tableName = Soundtrack.Events.Stack[stackLevel].tableName
        local eventName = Soundtrack.Events.Stack[stackLevel].eventName
        SoundtrackFrame_StatusBarEventText1:SetText(Soundtrack.GetPathFileName(eventName))
        local event = Soundtrack.GetEvent(tableName, eventName)

        if event and event.tracks then
            local numTracks = getn(event.tracks)

            if Soundtrack.Library.CurrentlyPlayingTrack then
                local curTrackIndex = Soundtrack.IndexOf(event.tracks, currentTrack)
                SoundtrackFrame_StatusBarEventText2:SetText(curTrackIndex .. " / " .. numTracks)
                SoundtrackFrame_StatusBarSetProgress("SoundtrackFrame_StatusBarEvent", numTracks, curTrackIndex)
                SoundtrackFrame_StatusBarSetProgress("SoundtrackControlFrame_StatusBarEvent", numTracks, curTrackIndex)
            else
                SoundtrackFrame_StatusBarEventText2:SetText(numTracks .. " tracks")
            end
        else
            SoundtrackFrame_StatusBarEventText2:SetText("")
        end

    end

    SoundtrackFrame_MovingTitle()

    -- Refresh control frame too
    SoundtrackControlFrame_StatusBarTrackText1:SetWidth(215)
    SoundtrackControlFrame_StatusBarEventText1:SetWidth(215)
    SoundtrackControlFrame_StatusBarEventText1:SetText(SoundtrackFrame_StatusBarEventText1:GetText()) -- event name
    SoundtrackControlFrame_StatusBarEventText2:SetText(SoundtrackFrame_StatusBarEventText2:GetText()) -- track number in list
    SoundtrackControlFrame_StatusBarTrackText1:SetText(SoundtrackFrame_StatusBarTrackText1:GetText()) -- track name
    SoundtrackControlFrame_StatusBarTrackText2:SetText(SoundtrackFrame_StatusBarTrackText2:GetText()) -- time
end

SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST = {
    { name = "File Path", type = "filePath" },
    { name = "File Name", type = "fileName" },
    { name = "Title", type = "title" }
}

function SoundtrackFrame_ColumnHeaderNameDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(SoundtrackFrame_ColumnHeaderNameDropDown, self:GetID())
    SoundtrackFrame.nameHeaderType = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[self:GetID()].type
    Soundtrack.TraceFrame("Refreshing tracks with " .. SoundtrackFrame.nameHeaderType)
    if self.sortType == "name" and
            SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "fileName" or
            SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "filePath" or
            SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "title" then
        Soundtrack.SortTracks(SoundtrackFrame.nameHeaderType)
    else
        Soundtrack.SortTracks(self.sortType)
    end

    --SoundtrackFrame_RefreshCurrentlyPlaying()
end

function SoundtrackFrame_ColumnHeaderNameDropDown_Initialize()
    --Soundtrack.TraceFrame("Track sorting criteria: " .. SoundtrackAddon.db.profile.settings.TrackSortingCriteria)

    local info = UIDropDownMenu_CreateInfo()
    for i = 1, #(SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST), 1 do
        info.text = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[i].name
        info.func = SoundtrackFrame_ColumnHeaderNameDropDown_OnClick
        local checked = nil
        --[[if SoundtrackAddon.db.profile.settings.TrackSortingCriteria == info.text then
            Soundtrack.TraceFrame(info.Text .. " is checked!")
            checked = true
        end
        info.checked = checked]]
        UIDropDownMenu_AddButton(info)
    end
end


-- Functions to call from outside, to refresh the UI partially
function SoundtrackFrame_TouchEvents()

    SoundtrackFrame_RefreshCurrentlyPlaying()

    -- Refresh stack
    local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
    local currentEvent = "None"
    if stackLevel ~= 0 then
        currentEvent = Soundtrack.Events.Stack[stackLevel].eventName
    end

    local i
    for i = 1, Soundtrack.MaxStackLevel, 1 do
        local tableName = Soundtrack.Events.Stack[i].tableName
        local eventName = Soundtrack.Events.Stack[i].eventName
        local label = _G["SoundtrackControlFrameStack" .. i]
        if not eventName then
            label:SetText(i .. ") None")
        else
            local playOnceText
            local event = Soundtrack.GetEvent(tableName, eventName)
            if event.continuous then
                playOnceText = "Loop"
            else
                playOnceText = "Once"
            end
            local eventText = Soundtrack.GetPathFileName(eventName)
            label:SetText(i .. ") " .. eventText .. " (" .. playOnceText .. ")")
        end
    end

    SoundtrackFrame_RefreshEvents()
end

-- Functions to call from outside, to refresh the UI partially
function SoundtrackFrame_TouchTracks()
    SoundtrackFrame_RefreshTracks()
    SoundtrackFrame_RefreshCurrentlyPlaying()
end

function SoundtrackFrame_RefreshProfilesFrame()
end

function SoundtrackFrame_SetControlsButtonsPosition()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return
    end

    local nextButton = _G["SoundtrackControlFrame_NextButton"]
    local playButton = _G["SoundtrackControlFrame_PlayButton"]
    local stopButton = _G["SoundtrackControlFrame_StopButton"]
    local previousButton = _G["SoundtrackControlFrame_PreviousButton"]
    local trueStopButton = _G["SoundtrackControlFrame_TrueStopButton"]
    local reportButton = _G["SoundtrackControlFrame_ReportButton"]
    local infoButton = _G["SoundtrackControlFrame_InfoButton"]
    if nextButton and playButton and stopButton and previousButton and
            trueStopButton and reportButton and infoButton then
        local position = SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition
        SoundtrackControlFrame_NextButton:ClearAllPoints()
        SoundtrackControlFrame_PlayButton:ClearAllPoints()
        SoundtrackControlFrame_StopButton:ClearAllPoints()
        SoundtrackControlFrame_PreviousButton:ClearAllPoints()
        SoundtrackControlFrame_TrueStopButton:ClearAllPoints()
        SoundtrackControlFrame_ReportButton:ClearAllPoints()
        SoundtrackControlFrame_InfoButton:ClearAllPoints()
        if position == "LEFT" then
            SoundtrackControlFrame_NextButton:SetPoint("BOTTOMRIGHT", "SoundtrackControlFrame_StatusBarEvent", "BOTTOMLEFT", -12, -1)
            SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
            SoundtrackControlFrame_TrueStopButton:SetPoint("TOP", "SoundtrackControlFrame_PlayButton", "BOTTOM")
            SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
            SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
        elseif position == "TOPLEFT" then
            SoundtrackControlFrame_PreviousButton:SetPoint("BOTTOMLEFT", "SoundtrackControlFrame_StatusBarEvent", "TOPLEFT", -3, 7)
            SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_PlayButton", "RIGHT")
            SoundtrackControlFrame_InfoButton:SetPoint("LEFT", "SoundtrackControlFrame_NextButton", "RIGHT")
            SoundtrackControlFrame_TrueStopButton:SetPoint("LEFT", "SoundtrackControlFrame_InfoButton", "RIGHT")
            SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
        elseif position == "TOPRIGHT" then
            SoundtrackControlFrame_ReportButton:SetPoint("BOTTOMRIGHT", "SoundtrackControlFrame_StatusBarEvent", "TOPRIGHT", 3, 7)
            SoundtrackControlFrame_TrueStopButton:SetPoint("RIGHT", "SoundtrackControlFrame_ReportButton", "LEFT")
            SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
            SoundtrackControlFrame_NextButton:SetPoint("RIGHT", "SoundtrackControlFrame_InfoButton", "LEFT")
            SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
        elseif position == "RIGHT" then
            SoundtrackControlFrame_PreviousButton:SetPoint("BOTTOMLEFT", "SoundtrackControlFrame_StatusBarEvent", "BOTTOMRIGHT", 12, -1)
            SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_StopButton", "RIGHT")
            SoundtrackControlFrame_TrueStopButton:SetPoint("TOP", "SoundtrackControlFrame_PlayButton", "BOTTOM")
            SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
            SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
        elseif position == "BOTTOMRIGHT" then
            SoundtrackControlFrame_NextButton:SetPoint("TOPRIGHT", "SoundtrackControlFrame_StatusBarTrack", "BOTTOMRIGHT", 3, -7)
            SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
            SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
            SoundtrackControlFrame_TrueStopButton:SetPoint("RIGHT", "SoundtrackControlFrame_PreviousButton", "LEFT")
            SoundtrackControlFrame_ReportButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
            SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_ReportButton", "LEFT")
        elseif position == "BOTTOMLEFT" then
            SoundtrackControlFrame_PreviousButton:SetPoint("TOPLEFT", "SoundtrackControlFrame_StatusBarTrack", "BOTTOMLEFT", -3, -7)
            SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
            SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_PlayButton", "RIGHT")
            SoundtrackControlFrame_InfoButton:SetPoint("LEFT", "SoundtrackControlFrame_NextButton", "RIGHT")
            SoundtrackControlFrame_TrueStopButton:SetPoint("LEFT", "SoundtrackControlFrame_InfoButton", "RIGHT")
            SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
        end
    end
end

function SoundtrackFrame_HideControlButtons()
    local nextButton = _G["SoundtrackControlFrame_NextButton"]
    local playButton = _G["SoundtrackControlFrame_PlayButton"]
    local stopButton = _G["SoundtrackControlFrame_StopButton"]
    local previousButton = _G["SoundtrackControlFrame_PreviousButton"]
    local trueStopButton = _G["SoundtrackControlFrame_TrueStopButton"]
    local reportButton = _G["SoundtrackControlFrame_ReportButton"]
    local infoButton = _G["SoundtrackControlFrame_InfoButton"]
    if nextButton and playButton and stopButton and previousButton and
            trueStopButton and reportButton and infoButton then
        if SoundtrackAddon.db.profile.settings.HideControlButtons then
            SoundtrackControlFrame_NextButton:Hide()
            SoundtrackControlFrame_PlayButton:Hide()
            SoundtrackControlFrame_StopButton:Hide()
            SoundtrackControlFrame_PreviousButton:Hide()
            SoundtrackControlFrame_TrueStopButton:Hide()
            SoundtrackControlFrame_ReportButton:Hide()
            SoundtrackControlFrame_InfoButton:Hide()
        else
            SoundtrackControlFrame_NextButton:Show()
            SoundtrackControlFrame_PlayButton:Show()
            SoundtrackControlFrame_StopButton:Show()
            SoundtrackControlFrame_PreviousButton:Show()
            SoundtrackControlFrame_TrueStopButton:Show()
            SoundtrackControlFrame_ReportButton:Show()
            SoundtrackControlFrame_InfoButton:Show()
        end
        SoundtrackControlFrame_NextButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_PlayButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_StopButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_PreviousButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_TrueStopButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_ReportButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
        SoundtrackControlFrame_InfoButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
    end
end

function SoundtrackFrame_RefreshPlaybackControls()
    if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
        return
    end

    SoundtrackFrame_SetControlsButtonsPosition()
    SoundtrackFrame_HideControlButtons()

    if SoundtrackAddon.db.profile.settings.HideControlButtons == false then
        local stopButton = _G["SoundtrackControlFrame_StopButton"]
        local playButton = _G["SoundtrackControlFrame_PlayButton"]

        if stopButton and playButton then
            if Soundtrack.Events.Paused then
                stopButton:Hide()
                playButton:Show()
            else
                stopButton:Show()
                playButton:Hide()
            end
        end
    end

    local stopButton2 = _G["SoundtrackFrame_StopButton"]
    local playButton2 = _G["SoundtrackFrame_PlayButton"]

    if stopButton2 and playButton2 then
        if Soundtrack.Events.Paused then
            stopButton2:Hide()
            playButton2:Show()
        else
            stopButton2:Show()
            playButton2:Hide()
        end
    end

    local controlFrame = _G["SoundtrackControlFrame"]

    if controlFrame then
        if SoundtrackAddon.db.profile.settings.ShowPlaybackControls then
            controlFrame:Show()

            if (SoundtrackAddon.db.profile.settings.ShowEventStack) then
                SoundtrackControlFrameStackTitle:Show()
                SoundtrackControlFrameStack1:Show()
                SoundtrackControlFrameStack2:Show()
                SoundtrackControlFrameStack3:Show()
                SoundtrackControlFrameStack4:Show()
                SoundtrackControlFrameStack5:Show()
                SoundtrackControlFrameStack6:Show()
                SoundtrackControlFrameStack7:Show()
                SoundtrackControlFrameStack8:Show()
                SoundtrackControlFrameStack9:Show()
                SoundtrackControlFrameStack10:Show()
                SoundtrackControlFrameStack11:Show()
                SoundtrackControlFrameStack12:Show()
                SoundtrackControlFrameStack13:Show()
                SoundtrackControlFrameStack14:Show()
                SoundtrackControlFrameStack15:Show()
                SoundtrackControlFrameStack16:Show()
            else
                SoundtrackControlFrameStackTitle:Hide()
                SoundtrackControlFrameStack1:Hide()
                SoundtrackControlFrameStack2:Hide()
                SoundtrackControlFrameStack3:Hide()
                SoundtrackControlFrameStack4:Hide()
                SoundtrackControlFrameStack5:Hide()
                SoundtrackControlFrameStack6:Hide()
                SoundtrackControlFrameStack7:Hide()
                SoundtrackControlFrameStack8:Hide()
                SoundtrackControlFrameStack9:Hide()
                SoundtrackControlFrameStack10:Hide()
                SoundtrackControlFrameStack11:Hide()
                SoundtrackControlFrameStack12:Hide()
                SoundtrackControlFrameStack13:Hide()
                SoundtrackControlFrameStack14:Hide()
                SoundtrackControlFrameStack15:Hide()
                SoundtrackControlFrameStack16:Hide()
            end
        else
            controlFrame:Hide()
        end
    end
end

function SoundtrackFrame_ToggleRandomMusic()
    local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
    if eventTable[SoundtrackFrame_SelectedEvent] then
        eventTable[SoundtrackFrame_SelectedEvent].random = not eventTable[SoundtrackFrame_SelectedEvent].random
    end
end

function SoundtrackFrame_ToggleSoundEffect()
    local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
    if eventTable[SoundtrackFrame_SelectedEvent] then
        eventTable[SoundtrackFrame_SelectedEvent].soundEffect = not eventTable[SoundtrackFrame_SelectedEvent].soundEffect
    end
end

function SoundtrackFrame_ToggleContinuousMusic()
    local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
    if eventTable[SoundtrackFrame_SelectedEvent] then
        eventTable[SoundtrackFrame_SelectedEvent].continuous = not eventTable[SoundtrackFrame_SelectedEvent].continuous
    end
end

function SoundtrackFrame_OnShow()
    SoundtrackFrame_RefreshCurrentlyPlaying()
    SelectActiveTab()
    SoundtrackFrame_RefreshShowingTab()
end

function SoundtrackFrame_OnHide()
    Soundtrack.StopEventAtLevel(ST_PREVIEW_LVL) -- TODO Anthony (Preview music)

    if SEVT.SelectedEventsTable ~= "Playlists" then
        Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL) -- TODO Anthony
    end
end

function SoundtrackFrame_RefreshCustomEvent()

    local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent]

    if customEvent == nil then
        return
    end

    if customEvent then
        -- TODO at startup
        if customEvent.priority == nil then
            customEventPriority = 1
        end

        _G["SoundtrackFrame_Priority"]:SetText(tostring(customEvent.priority))
        --_G["SoundtrackFrame_CustomContinuous"]:SetChecked(customEvent.continuous)
        if customEvent.type == "Event Script" then
            _G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
            _G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.trigger)
            _G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
        elseif customEvent.type == "Buff" then
            _G["SoundtrackFrame_FontStringTrigger"]:SetText("Spell ID")
            _G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.spellId)
            _G["SoundtrackFrame_EventScript"]:SetText("Buff events do not need a script.\nThey remain active while the specified buff is active.")
            -- TODO Make readonly
        elseif customEvent.type == "Update Script" then
            _G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
            _G["SoundtrackFrame_EventTrigger"]:SetText("OnUpdate")
            _G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
            -- TODO Make readonly
        end
    end


    -- temp
    if customEvent.type == nil then
        Soundtrack.TraceFrame("Nil type on " .. SoundtrackFrame_SelectedEvent)
        customEvent.type = "Update Script"
    end

    local eventTypeIndex = Soundtrack.IndexOf(eventTypes, customEvent.type)
    UIDropDownMenu_SetSelectedID(SoundtrackFrame_EventTypeDropDown, eventTypeIndex)
    UIDropDownMenu_SetText(SoundtrackFrame_EventTypeDropDown, customEvent.type)
    --SoundtrackFrame_EventTypeDropDown_OnLoad(self)
end

function SoundtrackFrameEventButton_OnClick(self, mouseButton, down)

    Soundtrack.TraceFrame("EventButton_OnClick")

    Soundtrack.Events.Pause(false)

    local flatEventsTable = GetFlatEventsTable()
    local button = _G["SoundtrackFrameEventButton" .. self:GetID() .. "ButtonTextName"]
    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
    SoundtrackFrame_SelectedEvent = flatEventsTable[self:GetID() + listOffset].tag -- The event name.

    -- TODO only react if clicking the expand/collapse button

    local event = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent]
    if mouseButton == "RightButton" then
        -- Do nothing
    elseif event.expanded then
        event.expanded = false
        Soundtrack.TraceFrame(SoundtrackFrame_SelectedEvent .. " is now collapsed")
    else
        event.expanded = true
        Soundtrack.TraceFrame(SoundtrackFrame_SelectedEvent .. " is now expanded")
    end

    Soundtrack_OnTreeChanged(SEVT.SelectedEventsTable)

    SoundtrackFrame_RefreshEvents()

    if (mouseButton == "RightButton" and SEVT.SelectedEventsTable == "Zone") then
        -- Toggle menu
        local menu = _G["SoundtrackFrameEventMenu"]
        menu.point = "TOPRIGHT"
        menu.relativePoint = "CENTER"
        ToggleDropDownMenu(1, nil, menu, button, 0, 0)
    elseif SEVT.SelectedEventsTable == "Playlists" then
        Soundtrack.PlayEvent(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent)
    end

    if SEVT.SelectedEventsTable == "Custom" then
        SoundtrackFrame_RefreshCustomEvent()
    end
end

function SoundtrackFrameAddZoneButton_OnClick()
    Soundtrack_ZoneEvents_AddZones();

    -- Select the newly added area.
    if (GetSubZoneText() ~= nil) then
        SoundtrackFrame_SelectedEvent = GetSubZoneText()
    else
        SoundtrackFrame_SelectedEvent = GetRealZoneText()
    end

    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameCollapseAllZoneButton_OnClick()
    Soundtrack.TraceFrame("Collapsing all zone events")
    for key, eventNode in pairs(SoundtrackAddon.db.profile.events["Zone"]) do
        eventNode.expanded = false
    end
    Soundtrack_OnTreeChanged("Zone")
    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameExpandAllZoneButton_OnClick()
    Soundtrack.TraceFrame("Expanding all zone events")
    for key, eventNode in pairs(SoundtrackAddon.db.profile.events["Zone"]) do
        eventNode.expanded = true
    end
    Soundtrack_OnTreeChanged("Zone")
    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameAddBossTargetButton_OnClick()
    local targetName = UnitName("target")
    if targetName then
        SoundtrackFrame_AddNamedBoss(targetName)
    else
        StaticPopup_Show("SOUNDTRACK_ADD_BOSS")
    end
end
StaticPopupDialogs["SOUNDTRACK_ADD_BOSS"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_ADD_BOSS_TIP,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 100,
    OnAccept = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddNamedBoss(editBox:GetText())
    end,
    OnShow = function(self)
        _G[self:GetName() .. "EditBox"]:SetFocus()
    end,
    OnHide = function(self)
        if (ChatFrame1EditBox:IsVisible()) then
            ChatFrame1EditBox:SetFocus()
        end
        _G[self:GetName() .. "EditBox"]:SetText("")
    end,
    EditBoxOnEnterPressed = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddNamedBoss(editBox:GetText())
        self:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:Hide()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}
function SoundtrackFrame_AddNamedBoss(targetName)
    Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
    local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
    Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
    SoundtrackFrame_SelectedEvent = targetName
    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameAddWorldBossTargetButton_OnClick()
    local targetName = UnitName("target")
    if targetName then
        SoundtrackFrame_AddNamedWorldBoss(targetName)
    else
        StaticPopup_Show("SOUNDTRACK_ADD_WORLD_BOSS")
    end
end
StaticPopupDialogs["SOUNDTRACK_ADD_WORLD_BOSS"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_ADD_BOSS_TIP,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 100,
    OnAccept = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddNamedWorldBoss(editBox:GetText())
    end,
    OnShow = function(self)
        _G[self:GetName() .. "EditBox"]:SetFocus()
    end,
    OnHide = function(self)
        if (ChatFrame1EditBox:IsVisible()) then
            ChatFrame1EditBox:SetFocus()
        end
        _G[self:GetName() .. "EditBox"]:SetText("")
    end,
    EditBoxOnEnterPressed = function(self)
        local editBox = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddNamedWorldBoss(editBox:GetText())
        self:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:Hide()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 0
}
function SoundtrackFrame_AddNamedWorldBoss(targetName)
    Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
    local bossTable = Soundtrack.Events.GetTable(ST_BOSS)
    local bossEvent = bossTable[targetName]
    bossEvent.worldboss = true
    local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
    Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
    local bossEvent = bossTable[lowhealthbossname]
    bossEvent.worldboss = true
    SoundtrackFrame_SelectedEvent = targetName
    SoundtrackFrame_RefreshEvents()
end

-- Added by Lunaqua
function SoundtrackFrameRemoveZoneButton_OnClick()
    StaticPopup_Show("SOUNDTRACK_REMOVE_ZONE_POPUP")
end
function SoundtrackFrame_RemoveZone(eventName)
    Soundtrack.Events.DeleteEvent("Zone", eventName)
end
StaticPopupDialogs["SOUNDTRACK_REMOVE_ZONE_POPUP"] = {
    preferredIndex = 3,
    text = "Do you want to remove this zone?",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self)
        SoundtrackFrame_RemoveZone(SoundtrackFrame_SelectedEvent)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

function SoundtrackFrameAddPlaylistButton_OnClick(self)
    StaticPopup_Show("SOUNDTRACK_ADD_PLAYLIST_POPUP")
end
function SoundtrackFrame_AddPlaylist(playlistName)
    if playlistName == "" then
        local name = "New Event"
        local index = 1

        local indexedName = name .. " " .. index

        while Soundtrack.GetEvent("Playlists", indexedName) ~= nil do
            index = index + 1
            indexedName = name .. " " .. index
        end

        playlistName = indexedName
    end
    Soundtrack.AddEvent("Playlists", playlistName, ST_PLAYLIST_LVL, true)
    SoundtrackFrame_SelectedEvent = playlistName
    Soundtrack_SortEvents("Playlists")
    SoundtrackFrame_RefreshEvents()
end
StaticPopupDialogs["SOUNDTRACK_ADD_PLAYLIST_POPUP"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_ENTER_PLAYLIST_NAME,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 100,
    OnAccept = function(self)
        local playlistName = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddPlaylist(playlistName:GetText())
    end,
    OnShow = function(self)
        _G[self:GetName() .. "EditBox"]:SetFocus()
        _G[self:GetName() .. "EditBox"]:SetText("")
    end,
    OnHide = function(self)
    end,
    EditBoxOnEnterPressed = function(self)
        local playlistName = _G[self:GetName()]
        SoundtrackFrame_AddPlaylist(playlistName:GetText())
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}

function SoundtrackFrameDeletePlaylistButton_OnClick()
    Soundtrack.TraceFrame("Deleting " .. SoundtrackFrame_SelectedEvent)
    Soundtrack.Events.DeleteEvent(ST_PLAYLISTS, SoundtrackFrame_SelectedEvent)
    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameEventMenu_Initialize()
    --[[Title
    local info = {}
    info.text = "Soundtrack"
    info.notClickable = 1
    info.isTitle = 1
    UIDropDownMenu_AddButton(info, 1)]]
end

function SoundtrackFrame_StatusBar_OnClick(self, mouseButton, down)
    Soundtrack.TraceFrame("StatusBar_OnClick")
    local menu = _G["SoundtrackControlFrame_PlaylistMenu"]
    local button = _G["SoundtrackControlFrame_StatusBarTrack"]
    menu.point = "TOPLEFT"
    menu.relativePoint = "BOTTOMLEFT"
    ToggleDropDownMenu(1, nil, menu, button, 0, 0)
end

function SoundtrackControlFrame_PlaylistMenu_OnClick(self)
    Soundtrack.TraceFrame("PlaylistMenu_OnClick")

    local table = Soundtrack.Events.GetTable(ST_PLAYLISTS)
    Soundtrack.TraceFrame(self:GetID())

    local i = 1
    local eventName = nil
    for k, v in pairs(table) do
        if i == self:GetID() then
            eventName = k
        end
        i = i + 1
    end

    if eventName then
        Soundtrack.PlayEvent(ST_PLAYLISTS, eventName)
    end
end

function SoundtrackControlFrame_PlaylistMenu_Initialize()

    local playlistTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)

    table.sort(playlistTable, function(a, b)
        return a < b
    end)
    table.sort(playlistTable, function(a, b)
        return a > b
    end)
    table.sort(playlistTable, function(a, b)
        return a > b
    end)
    table.sort(playlistTable, function(a, b)
        return a < b
    end)

    for k, v in pairs(playlistTable) do
        local info = {}
        info.text = k
        info.value = k
        info.func = SoundtrackControlFrame_PlaylistMenu_OnClick
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info, 1)
    end
end

function SoundtrackFrameTrackMenu_Initialize()
    -- Remove track
    local info = {}
    info.text = SOUNDTRACK_REMOVE_TRACK
    info.value = "RemoveTrack"
    info.func = function(self)
        Soundtrack.Library.RemoveTrackWithConfirmation()
    end
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info, 1)
end

function SoundtrackFrameTrackCheckBox_OnClick(self, mouseButton, down)
    local checkBox = _G["SoundtrackFrameTrackButton" .. self:GetID() .. "CheckBox"]

    --local button = _G["SoundtrackFrameTrackButton"..self:GetID().."ButtonTextName")  
    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
    SoundtrackFrame_SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

    if SoundtrackFrame_SelectedEvent then
        if (SoundtrackFrame_IsTrackActive(SoundtrackFrame_SelectedTrack)) then
            Soundtrack.Events.Remove(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent, SoundtrackFrame_SelectedTrack)
        else
            -- Add the track to the events list.
            Soundtrack.AssignTrack(SoundtrackFrame_SelectedEvent, SoundtrackFrame_SelectedTrack)
        end
    end

    -- To refresh assigned track counts.
    SoundtrackFrame_RefreshEvents()
    SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAssignedTrackCheckBox_OnClick(self, mouseButton, down)
    local checkBox = _G["SoundtrackFrameAssignedTrackButton" .. self:GetID() .. "CheckBox"]

    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

    local assignedTracks = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent].tracks
    SoundtrackFrame_SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

    if (SoundtrackFrame_IsTrackActive(SoundtrackFrame_SelectedTrack)) then
        Soundtrack.Events.Remove(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent, SoundtrackFrame_SelectedTrack)
    else
        -- Add the track to the events list.
        Soundtrack.AssignTrack(SoundtrackFrame_SelectedEvent, SoundtrackFrame_SelectedTrack)
    end

    -- To refresh assigned track counts.
    SoundtrackFrame_RefreshEvents()
    SoundtrackFrame_RefreshTracks()
end

-- Plays a track using a temporary "preview" event on stack level 16
function PlayPreviewTrack(trackName)
    -- Make sure the preview event exists
    Soundtrack.Events.DeleteEvent(ST_MISC, "Preview")
    Soundtrack.AddEvent(ST_MISC, "Preview", ST_PREVIEW_LVL, true)
    Soundtrack.AssignTrack("Preview", trackName)
    Soundtrack.PlayEvent(ST_MISC, "Preview", true)
end

function SoundtrackFrameTrackButton_OnClick(self, mouseButton, down)

    Soundtrack.TraceFrame("OnClick")

    Soundtrack.Events.Pause(false)

    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
    SoundtrackFrame_SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

    PlayPreviewTrack(SoundtrackFrame_SelectedTrack)

    SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAssignedTrackButton_OnClick(self, mouseButton, down)

    Soundtrack.Events.Pause(false)

    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

    local assignedTracks = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent].tracks

    SoundtrackFrame_SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

    PlayPreviewTrack(SoundtrackFrame_SelectedTrack)

    SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAllButton_OnClick()
    -- Start by clearing all tracks
    Soundtrack.Events.ClearEvent(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent)

    -- The highlight all of them
    local i
    for i = 1, #(Soundtrack_SortedTracks), 1 do
        Soundtrack.AssignTrack(SoundtrackFrame_SelectedEvent, Soundtrack_SortedTracks[i])
    end
    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameClearButton_OnClick()
    if not SoundtrackFrame_SelectedEvent then
        Soundtrack.Error("The Clear button was enabled without a selected event")
        return
    end

    -- TODO Confirm

    Soundtrack.Events.ClearEvent(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent)

    SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrame_RefreshShowingTab()
    SEVT.SelectedEventsTable = nil
    SoundtrackFrameEventFrame:Hide()
    SoundtrackFrameOptionsTab:Hide()
    SoundtrackFrameProfilesFrame:Hide()
    SoundtrackFrameAboutFrame:Hide()
    -- Battle events tab
    if (SoundtrackFrame.selectedTab == 1) then
        SEVT.SelectedEventsTable = "Battle"
        SoundtrackFrameEventFrame:Show()
        -- Boss tab
    elseif (SoundtrackFrame.selectedTab == 2) then
        SEVT.SelectedEventsTable = "Boss"
        SoundtrackFrameEventFrame:Show()
        -- Zones tab
    elseif (SoundtrackFrame.selectedTab == 3) then
        SEVT.SelectedEventsTable = "Zone"
        SoundtrackFrameEventFrame:Show()
        -- Dance tab
    elseif (SoundtrackFrame.selectedTab == 4) then
        SEVT.SelectedEventsTable = "Dance"
        SoundtrackFrameEventFrame:Show()
        -- Misc tab
    elseif (SoundtrackFrame.selectedTab == 5) then
        SEVT.SelectedEventsTable = "Misc"
        SoundtrackFrameEventFrame:Show()

        -- Custom tab
    elseif (SoundtrackFrame.selectedTab == 6) then
        SEVT.SelectedEventsTable = "Custom"
        SoundtrackFrameEventFrame:Show()

        -- Playlists tab
    elseif (SoundtrackFrame.selectedTab == 7) then
        SEVT.SelectedEventsTable = "Playlists"
        SoundtrackFrameEventFrame:Show()
        -- Options tab
    elseif (SoundtrackFrame.selectedTab == 8) then
        SoundtrackFrameOptionsTab:Show()
        -- Profiles tab
    elseif (SoundtrackFrame.selectedTab == 9) then
        SoundtrackFrameProfilesFrame:Show()
        -- About tab
    elseif (SoundtrackFrame.selectedTab == 10) then
        SoundtrackFrameAboutFrame:Show()
    end

    SoundtrackFrame_OnTabChanged()
end

function SoundtrackFrame_OnTabChanged()

    if (SEVT.SelectedEventsTable == nil) then

    else
        Soundtrack.StopEvent(ST_MISC, "Preview") -- Stop preview track

        -- Select first event if possible 
        SoundtrackFrame_SelectedEvent = nil

        local table = GetFlatEventsTable()

        if table and #(GetFlatEventsTable()) >= 1 then
            SoundtrackFrame_SelectedEvent = table[1].tag
        end

        SoundtrackFrame_RefreshEvents()

        if SEVT.SelectedEventsTable == "Zone" then
            SoundtrackFrameAddZoneButton:Show()
            SoundtrackFrameRemoveZoneButton:Show()
            SoundtrackFrameCollapseAllZoneButton:Show()
            SoundtrackFrameExpandAllZoneButton:Show()
        else
            SoundtrackFrameAddZoneButton:Hide()
            SoundtrackFrameRemoveZoneButton:Hide()
            SoundtrackFrameCollapseAllZoneButton:Hide()
            SoundtrackFrameExpandAllZoneButton:Hide()
        end

        if SEVT.SelectedEventsTable == "Boss" then
            SoundtrackFrameAddBossTargetButton:Show()
            SoundtrackFrameAddWorldBossTargetButton:Show()
            SoundtrackFrameDeleteTargetButton:Show()
        else
            SoundtrackFrameAddBossTargetButton:Hide()
            SoundtrackFrameAddWorldBossTargetButton:Hide()
            SoundtrackFrameDeleteTargetButton:Hide()
        end

        if SEVT.SelectedEventsTable == "Custom" then
            SoundtrackFrameAddCustomEventButton:Show()
            SoundtrackFrameEditCustomEventButton:Show()
            SoundtrackFrameDeleteCustomEventButton:Show()
            --_G["SoundtrackFrameRightPanelTracks"]:Hide()
            --_G["SoundtrackFrameRightPanelEditEvent"]:Show()
        else
            SoundtrackFrameAddCustomEventButton:Hide()
            SoundtrackFrameEditCustomEventButton:Hide()
            SoundtrackFrameDeleteCustomEventButton:Hide()
            _G["SoundtrackFrameRightPanelTracks"]:Show()
            _G["SoundtrackFrameRightPanelEditEvent"]:Hide()
        end

        if SEVT.SelectedEventsTable == "Playlists" then
            SoundtrackFrameAddPlaylistButton:Show()
            --SoundtrackFrameRenamePlaylistButton:Show()
            SoundtrackFrameDeletePlaylistButton:Show()
        else
            SoundtrackFrameAddPlaylistButton:Hide()
            --SoundtrackFrameRenamePlaylistButton:Hide()
            SoundtrackFrameDeletePlaylistButton:Hide()
        end

        if SEVT.SelectedEventsTable ~= "Options" then
            SoundtrackFrame_OnSelectedEventTabChanged()
        end

        if SEVT.SelectedEventsTable ~= "Playlists" then
            Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL) -- Stop playlists when we go out of the playlist panel
        end
    end
end

function SoundtrackFrame_OnFilterChanged()
    Soundtrack.trackFilter = SoundtrackFrame_TrackFilter:GetText()
    Soundtrack.SortTracks()
end

function SoundtrackFrame_OnEventFilterChanged()
    Soundtrack.eventFilter = SoundtrackFrame_EventFilter:GetText()
    Soundtrack.SortAllEvents()
end

function SoundtrackFrame_DisableAllEventButtons()
    for i = 1, EVENTS_TO_DISPLAY, 1 do
        local button = _G["SoundtrackFrameEventButton" .. i]
        button:Hide()
    end
end

function SoundtrackFrame_DisableAllTrackButtons()
    for i = 1, TRACKS_TO_DISPLAY, 1 do
        local button = _G["SoundtrackFrameTrackButton" .. i]
        button:Hide()
    end
end

function SoundtrackFrame_DisableAllAssignedTrackButtons()
    for i = 1, ASSIGNED_TRACKS_TO_DISPLAY, 1 do
        local button = _G["SoundtrackAssignedTrackButton" .. i]
        button:Hide()
    end
end

-- Replaces each folder in an event path with spaces
local function GetLeafText(eventPath)
    if eventPath then
        return string.gsub(eventPath, "[^/]*/", "    ")
    else
        return eventPath
    end
end

-- Counts the number of / in a path to calculate the depth
local function GetEventDepth(eventPath)
    local count = 0
    local i = 0
    while true do
        i = string.find(eventPath, "/", i + 1)
        -- find 'next' newline
        if i == nil then
            return count
        end
        count = count + 1
    end
end

function SoundtrackFrame_RefreshEvents()
    if not SoundtrackFrame:IsVisible() or not SEVT.SelectedEventsTable then
        Soundtrack.TraceFrame("Skipping event refresh")
        return
    end

    -- TODO Should not have to do this here
    Soundtrack.TraceFrame("SEVT.SelectedEventsTable: " .. SEVT.SelectedEventsTable);
    local flatEventsTable = GetFlatEventsTable()

    -- The selected event was deleted, activate another one if possible
    if SEVT.SelectedEventsTable and SoundtrackFrame_SelectedEvent then
        if not SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent] then
            if table.maxn(flatEventsTable) > 0 then
                SoundtrackFrame_SelectedEvent = flatEventsTable[1].tag
            else
                SoundtrackFrame_SelectedEvent = ""
            end
        end
    end

    SoundtrackFrame_DisableAllEventButtons()
    local numEvents = #(flatEventsTable)

    local button
    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
    local buttonIndex
    local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
    local currentEvent
    if stackLevel ~= 0 then
        currentEvent = Soundtrack.Events.Stack[stackLevel].eventName
    end

    for i, eventNode in ipairs(flatEventsTable) do
        local eventName = eventNode.tag or error("nil event!")

        if (i > listOffset and i < listOffset + EVENTS_TO_DISPLAY) then
            buttonIndex = i - listOffset
            if (buttonIndex <= EVENTS_TO_DISPLAY) then

                button = _G["SoundtrackFrameEventButton" .. buttonIndex]
                local fo = button:CreateFontString()    -- 02/11/2016 added to Justify the Text
                --fo:SetJustifyH("RIGHT")
                fo:SetJustifyH("LEFT") --CSCIGUY changed 8-7-18
                fo:SetFont("Fonts/FRIZQT__.TTF", 10)
                fo:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                fo:SetText(GetLeafText(eventName))
                fo:SetWidth(180)--CSCIGUY added 8-7-18
                fo:SetHeight(16)--CSCIGUY added 8-7-18
                button:SetFontString(fo)

                button:SetNormalFontObject("GameFontHighlightSmall")
                button:SetHighlightFontObject("GameFontNormalSmall")

                button:SetID(buttonIndex)
                button:Show()

                local event = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][eventName]

                -- Add expandable (+ or -) texture
                local collapserTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "CollapserTexture"]
                local expanderTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "ExpanderTexture"]
                collapserTexture:Hide()
                expanderTexture:Hide()

                local eventDepth = GetEventDepth(eventName)
                expandTextureIndent = 16 * eventDepth
                collapserTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)
                expanderTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)

                local expandable = eventNode.nodes and #eventNode.nodes >= 1
                if expandable then
                    if event.expanded then
                        collapserTexture:Show()
                        fo:SetText("    " .. GetLeafText(eventName))
                    else
                        expanderTexture:Show()
                        fo:SetText("    " .. GetLeafText(eventName))
                    end
                    button:UnlockHighlight()
                else
                    button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
                    expanderTexture:Hide()
                end

                -- Show number of assigned tracks
                if event then
                    local numAssignedTracks = table.maxn(event.tracks)
                    if (numAssignedTracks == 0) then
                        local tempText = button:GetText()
                        fo:SetText(tempText .. "   ")
                    else
                        local tempText = button:GetText()
                        fo:SetText(tempText .. " (" .. numAssignedTracks .. ")")
                    end
                end

                icon = _G["SoundtrackFrameEventButton" .. buttonIndex .. "Icon"]
                icon:Hide()

                -- Update the highlight if that track is active for the event.
                -- Todo : does this work?
                if (eventName == SoundtrackFrame_SelectedEvent) then
                    button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
                    button:LockHighlight()
                else
                    button:UnlockHighlight()
                end

                -- Update the icon
                if currentEvent == eventName then
                    icon:Show()
                end
            end
        end
        --i = i + 1    
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(SoundtrackFrameEventScrollFrame, numEvents + 1, EVENTS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

    SoundtrackFrame_RefreshTracks()
    --SoundtrackFrame_RefreshCurrentlyPlaying()
    RefreshEventSettings()
end

function SoundtrackFrame_RenameEvent()


    if SoundtrackFrame_SelectedEvent and not suspendRenameEvent then
        Soundtrack.Events.RenameEvent(SEVT.SelectedEventsTable,
                SoundtrackFrame_SelectedEvent,
                _G["SoundtrackFrame_EventName"]:GetText())
        SoundtrackFrame_RefreshEvents()
    end
end

-- Checks if a particular track is already set for an event
function SoundtrackFrame_IsTrackActive(trackName)

    local event = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent]
    if not event then
        return false
    end

    for i, tn in ipairs(event.tracks) do
        if (tn == trackName) then
            return true
        end
    end

    return false
end

function SoundtrackFrame_Toggle()
    if (SoundtrackFrame:IsVisible()) then
        SoundtrackFrame:Hide()
    else
        SoundtrackFrame:Show()
    end
end

function SoundtrackFrame_EventTypeDropDown_OnLoad(self)
    UIDropDownMenu_Initialize(self, SoundtrackFrame_EventTypeDropDown_Initialize)
    UIDropDownMenu_SetWidth(self, 130)
end

function SoundtrackFrame_EventTypeDropDown_AddInfo(id, caption)
    local info = UIDropDownMenu_CreateInfo()
    info.value = id
    info.text = caption
    info.func = SoundtrackFrame_EventTypeDropDown_OnClick
    local checked = nil
    local selectedId = UIDropDownMenu_GetSelectedID(SoundtrackFrame_EventTypeDropDown)
    if (selectedId ~= nil and selectedId == id) then
        checked = 1
    end
    info.checked = checked
    UIDropDownMenu_AddButton(info)
end

function SoundtrackFrame_EventTypeDropDown_Initialize()
    for i = 1, #(eventTypes) do
        SoundtrackFrame_EventTypeDropDown_AddInfo(i, eventTypes[i])
    end
end

function SoundtrackFrame_EventTypeDropDown_OnClick(self)

    local oldSelectedId = UIDropDownMenu_GetSelectedID(SoundtrackFrame_EventTypeDropDown)
    local selectedId = self:GetID()

    if (selectedId == oldSelectedId) then
        return
    end

    local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent]

    customEvent.type = eventTypes[selectedId]

    if eventTypes[selectedId] == "Update Script" then
        if customEvent.script == nil then
            customEvent.swcript = "type your update script here"
        end
    elseif eventTypes[selectedId] == "Buff" then
        if customEvent.spellId == nil then
            customEvent.spellId = "0"
        end
    elseif eventTypes[selectedId] == "Event Script" then
        if customEvent.trigger == nil then
            customEvent.trigger = "UNIT_AURA"
        end
        if customEvent.script == nil then
            customEvent.script = "type in your event script here"
        end
    end

    SoundtrackFrame_RefreshCustomEvent()
end

-- get shown and you can check things on/off anyways.
function SoundtrackFrame_RefreshTracks()
    if (not SoundtrackFrame:IsVisible() or SEVT.SelectedEventsTable == nil) then
        return
    end

    SoundtrackFrame_DisableAllTrackButtons()
    local numTracks = table.maxn(Soundtrack_SortedTracks)
    local icon
    local button
    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
    local buttonIndex
    for i = 1, numTracks, 1 do
        if (i > listOffset and i < listOffset + TRACKS_TO_DISPLAY) then
            buttonIndex = i - listOffset
            if (buttonIndex <= TRACKS_TO_DISPLAY) then

                local nameText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextName"]

                if SoundtrackFrame.nameHeaderType == "filePath" or SoundtrackFrame.nameHeaderType == nil then
                    nameText:SetText(Soundtrack_SortedTracks[i])
                elseif SoundtrackFrame.nameHeaderType == "fileName" then
                    nameText:SetText(Soundtrack.GetPathFileName(Soundtrack_SortedTracks[i]))
                elseif SoundtrackFrame.nameHeaderType == "title" then
                    nameText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].title)
                end

                local albumText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
                albumText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].album)

                local artistText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextArtist"]
                artistText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].artist)

                button = _G["SoundtrackFrameTrackButton" .. buttonIndex]

                button:SetID(buttonIndex)

                button:Show()

                -- Show duration of track
                local durationLabel = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextDuration"]
                local duration = Soundtrack_Tracks[Soundtrack_SortedTracks[i]].length
                durationLabel:SetText(Soundtrack.Util.FormatDuration(duration))

                icon = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "Icon"]
                icon:Hide()

                local checkBox = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "CheckBox"]
                checkBox:SetID(buttonIndex)

                if (Soundtrack_SortedTracks[i] == SoundtrackFrame_SelectedTrack) then
                    button:LockHighlight()

                else
                    button:UnlockHighlight()
                end

                if (SoundtrackFrame_SelectedEvent ~= nil) then
                    -- Update the highlight if that track is active for the event.
                    if (SoundtrackFrame_IsTrackActive(Soundtrack_SortedTracks[i])) then
                        checkBox:SetChecked(true)
                    else
                        checkBox:SetChecked(false)
                    end

                    -- Update the icon
                    if (Soundtrack.Library.CurrentlyPlayingTrack == Soundtrack_SortedTracks[i]) then
                        icon:Show()
                    end
                end

                if (buttonIndex > numTracks) then
                    --ignoreButton:Hide()
                else
                    --ignoreButton:Show()
                end
            end
        end
        --i = i + 1    
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(SoundtrackFrameTrackScrollFrame, numTracks + 1, TRACKS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

    SoundtrackFrame_RefreshAssignedTracks()
end

local function SoundtrackFrame_RefreshUpDownButtons()
    local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
    if (eventTable[SoundtrackFrame_SelectedEvent] ~= nil) then
        local event = eventTable[SoundtrackFrame_SelectedEvent]
        local currentIndex = Soundtrack.IndexOf(event.tracks, SoundtrackFrame_SelectedTrack)

        if (currentIndex > 0 and currentIndex > 1) then
            _G["SoundtrackFrameMoveUp"]:Enable()
        else
            _G["SoundtrackFrameMoveUp"]:Disable()
        end

        if (currentIndex > 0 and currentIndex < #(event.tracks)) then
            _G["SoundtrackFrameMoveDown"]:Enable()
        else
            _G["SoundtrackFrameMoveDown"]:Disable()
        end

    end
end

function SoundtrackFrame_RefreshAssignedTracks()

    if (not SoundtrackFrame:IsVisible() or SEVT.SelectedEventsTable == nil) then
        return
    end

    SoundtrackFrame_DisableAllAssignedTrackButtons()

    if (SoundtrackFrame_SelectedEvent == nil) then
        return
    end

    local event = SoundtrackAddon.db.profile.events[SEVT.SelectedEventsTable][SoundtrackFrame_SelectedEvent]
    if event == nil then
        return
    end

    local priorityText
    if (event.priority == nil) then
        priorityText = "Priority: " .. "Unset"
    else
        priorityText = "Priority: " .. event.priority
    end

    local nameText
    local name
    local icon
    local button
    local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)
    local buttonIndex
    --local i=1
    --for key,value in Soundtrack_Tracks do

    local assignedTracks = event.tracks

    local i

    for i = 1, #(assignedTracks), 1 do
        if (i > listOffset and i < listOffset + ASSIGNED_TRACKS_TO_DISPLAY) then
            buttonIndex = i - listOffset
            if (buttonIndex <= ASSIGNED_TRACKS_TO_DISPLAY) then

                local nameText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextName"]

                if SoundtrackFrame.nameHeaderType == "filePath" or SoundtrackFrame.nameHeaderType == nil then
                    nameText:SetText(assignedTracks[i])
                elseif SoundtrackFrame.nameHeaderType == "fileName" then
                    nameText:SetText(Soundtrack.GetPathFileName(assignedTracks[i]))
                elseif SoundtrackFrame.nameHeaderType == "title" then
                    nameText:SetText(Soundtrack_Tracks[assignedTracks[i]].title)
                end

                local albumText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
                albumText:SetText(Soundtrack_Tracks[assignedTracks[i]].album)

                local artistText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextArtist"]
                artistText:SetText(Soundtrack_Tracks[assignedTracks[i]].artist)

                button = _G["SoundtrackAssignedTrackButton" .. buttonIndex]
                button:SetID(buttonIndex)
                button:Show()

                -- Show duration of track
                local durationLabel = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextDuration"]
                local duration = Soundtrack_Tracks[assignedTracks[i]].length
                durationLabel:SetText(Soundtrack.Util.FormatDuration(duration))

                icon = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "Icon"]
                icon:Hide()

                local checkBox = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "CheckBox"]
                checkBox:SetID(buttonIndex)

                if (assignedTracks[i] == SoundtrackFrame_SelectedTrack) then
                    button:LockHighlight()
                else
                    button:UnlockHighlight()
                end

                if (SoundtrackFrame_SelectedEvent ~= nil) then
                    -- Update the highlight if that track is active for the event.
                    if (SoundtrackFrame_IsTrackActive(assignedTracks[i])) then
                        checkBox:SetChecked(true)
                    else
                        checkBox:SetChecked(false)
                    end


                    -- Update the icon
                    if (Soundtrack.Library.CurrentlyPlayingTrack == assignedTracks[i]) then
                        icon:Show()
                    end
                end

                if (buttonIndex > #(assignedTracks)) then
                    --ignoreButton:Hide()
                else
                    --ignoreButton:Show()
                end
            end
        end
        --i = i + 1    
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(SoundtrackFrameAssignedTracksScrollFrame, #(assignedTracks) + 1, ASSIGNED_TRACKS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

    SoundtrackFrame_RefreshUpDownButtons()
end

function SoundtrackFrame_MoveAssignedTrack(direction)
    local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
    if (eventTable[SoundtrackFrame_SelectedEvent] ~= nil) then
        local event = eventTable[SoundtrackFrame_SelectedEvent]
        local currentIndex = Soundtrack.IndexOf(event.tracks, SoundtrackFrame_SelectedTrack)

        if (currentIndex > 0) then
            if (direction < 0 and currentIndex > 1) then
                -- Move up
                local newIndex = currentIndex - 1
                local temp = event.tracks[newIndex]
                event.tracks[newIndex] = event.tracks[currentIndex]
                event.tracks[currentIndex] = temp
            elseif (direction > 0 and currentIndex < #(event.tracks)) then
                -- Move down
                local newIndex = currentIndex + 1
                local temp = event.tracks[newIndex]
                event.tracks[newIndex] = event.tracks[currentIndex]
                event.tracks[currentIndex] = temp
            end
        end

        SoundtrackFrame_RefreshAssignedTracks()
    end

end

function SoundtrackFrameAddCustomEventButton_OnClick(self)
    StaticPopup_Show("SOUNDTRACK_ADD_CUSTOM_POPUP")
end
function SoundtrackFrame_AddCustomEvent(eventName, self)
    _G["SoundtrackFrameRightPanelTracks"]:Hide()
    _G["SoundtrackFrameRightPanelEditEvent"]:Show()

    if eventName == "" then
        local name = "New Event"
        local index = 1

        local indexedName = name .. " " .. index

        while Soundtrack.GetEvent("Custom", indexedName) ~= nil do
            index = index + 1
            indexedName = name .. " " .. index
        end

        eventName = indexedName
    end

    local script = "-- Custom script\n"
            .. "Soundtrack_Custom_PlayEvent(\"Custom\", \"" .. eventName .. "\") \n"
            .. "Soundtrack_Custom_StopEvent(\"Custom\", \"" .. eventName .. "\") \n"

    Soundtrack.CustomEvents.RegisterEventScript(self, eventName, "Custom", "UNIT_AURA", 4, true, script)
    SoundtrackFrame_SelectedEvent = eventName
    SoundtrackFrame_RefreshEvents()
    SoundtrackFrame_RefreshCustomEvent()
end
StaticPopupDialogs["SOUNDTRACK_ADD_CUSTOM_POPUP"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_ENTER_CUSTOM_NAME,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 100,
    OnAccept = function(self)
        local eventName = _G[self:GetName() .. "EditBox"]
        SoundtrackFrame_AddCustomEvent(eventName:GetText(), self)
    end,
    OnShow = function(self)
        _G[self:GetName() .. "EditBox"]:SetFocus()
        _G[self:GetName() .. "EditBox"]:SetText("")
    end,
    OnHide = function(self)
    end,
    EditBoxOnEnterPressed = function(self)
        local eventName = _G[self:GetName()]
        SoundtrackFrame_AddCustomEvent(eventName:GetText(), self)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
}

function SoundtrackFrameEditCustomEventButton_OnClick()
    _G["SoundtrackFrameRightPanelTracks"]:Hide()
    _G["SoundtrackFrameRightPanelEditEvent"]:Show()

    SoundtrackFrame_RefreshCustomEvent()
end

function SoundtrackFrameSaveCustomEventButton_OnClick()
    Soundtrack.TraceFrame("Saving " .. SoundtrackFrame_SelectedEvent)
    local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent]

    customEvent.priority = tonumber(getglobal("SoundtrackFrame_Priority"):GetText())
    customEvent.continuous = getglobal("SoundtrackFrame_ContinuousCheckBox"):GetChecked()

    local eventTable = Soundtrack.Events.GetTable("Custom")
    if (eventTable[SoundtrackFrame_SelectedEvent] ~= nil) then
        eventTable[SoundtrackFrame_SelectedEvent].priority = customEvent.priority
        eventTable[SoundtrackFrame_SelectedEvent].continuous = customEvent.continuous
        eventTable[SoundtrackFrame_SelectedEvent].soundEffect = customEvent.soundEffect
    end

    local eventType = customEvent.type
    Soundtrack.TraceFrame(customEvent.type);
    if eventType == "Event Script" then
        customEvent.eventtype = "Event Script";
        customEvent.trigger = getglobal("SoundtrackFrame_EventTrigger"):GetText()
        Soundtrack.CustomEvents.RegisterTrigger(_G["SoundtrackCustomDUMMY"], customEvent.trigger)
    elseif eventType == "Buff" then
        customEvent.eventtype = "Buff";
        customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
        Soundtrack.TraceFrame(customEvent.spellId)
    elseif eventType == "Debuff" then
        customEvent.eventtype = "Debuff";
        customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
        Soundtrack.TraceFrame(customEvent.spellId)
    elseif eventType == "Update Script" then
        customEvent.eventtype = "Update Script";
    end
    customEvent.script = getglobal("SoundtrackFrame_EventScript"):GetText()

    getglobal("SoundtrackFrameRightPanelEditEvent"):Hide()
    getglobal("SoundtrackFrameRightPanelTracks"):Show()
end

function SoundtrackFrameDeleteCustomEventButton_OnClick()
    if SoundtrackFrame_SelectedEvent then
        StaticPopup_Show("SOUNDTRACK_DELETE_CUSTOM_POPUP")
    end
end
function SoundtrackFrame_DeleteCustom(eventName)
    SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent] = nil
    Soundtrack.Events.DeleteEvent("Custom", eventName)
    SoundtrackFrame_RefreshEvents()
end
StaticPopupDialogs["SOUNDTRACK_DELETE_CUSTOM_POPUP"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_REMOVE_QUESTION,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        SoundtrackFrame_DeleteCustom(SoundtrackFrame_SelectedEvent)
    end,
    enterClicksFirstButton = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

function SoundtrackFrameDeleteMiscEventButton_OnClick()
    if SoundtrackFrame_SelectedEvent then
        StaticPopup_Show("SOUNDTRACK_DELETE_MISC_POPUP")
    end
end
function SoundtrackFrame_DeleteMisc(eventName)
    Soundtrack.Events.DeleteEvent("Misc", eventName)
    SoundtrackFrame_RefreshEvents()
end
StaticPopupDialogs["SOUNDTRACK_DELETE_MISC_POPUP"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_REMOVE_QUESTION,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        SoundtrackFrame_DeleteMisc(SoundtrackFrame_SelectedEvent)
    end,
    enterClicksFirstButton = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

function serialize (o)
    if type(o) == "number" then
        return tostring(o)
    elseif type(o) == "string" then
        return string.format("%q", o)
    elseif type(o) == "table" then
        local result
        result = "{\n"
        for k, v in pairs(o) do
            local val = serialize(v)
            if val ~= nil then
                result = result .. "  [\"" .. k .. "\"] = "
                result = result .. val
                result = result .. ",\n"
            end
        end
        result = result .. "}\n"
        return result
    else
        error("cannot serialize a " .. type(o))
    end
end

-- DELETE TARGET BUTTON
function SoundtrackFrameDeleteTargetButton_OnClick()
    if SoundtrackFrame_SelectedEvent then
        StaticPopup_Show("SOUNDTRACK_DELETE_TARGET_POPUP")
    end
end
function SoundtrackFrame_DeleteTarget(eventName)
    Soundtrack.TraceFrame("Deleting " .. SoundtrackFrame_SelectedEvent)
    Soundtrack.Events.DeleteEvent("Boss", eventName)
    SoundtrackFrame_RefreshEvents()
end
StaticPopupDialogs["SOUNDTRACK_DELETE_TARGET_POPUP"] = {
    preferredIndex = 3,
    text = SOUNDTRACK_REMOVE_QUESTION,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        SoundtrackFrame_DeleteTarget(SoundtrackFrame_SelectedEvent)
    end,
    enterClicksFirstButton = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

-- COPIED TRACKS BUTTONS
CopiedTracks = {}
function SoundtrackFrameCopyCopiedTracksButton_OnClick()
    if SoundtrackFrame_SelectedEvent then
        CopiedTracks = {}
        local eventTable = Soundtrack.Events.GetTable(SEVT.SelectedEventsTable)
        local event = eventTable[SoundtrackFrame_SelectedEvent]
        for i = 0, #(event.tracks) do
            CopiedTracks[i] = event.tracks[i]
        end
        SoundtrackFrame_RefreshEvents()
    end
end
function SoundtrackFramePasteCopiedTracksButton_OnClick()
    if SoundtrackFrame_SelectedEvent then
        for i = 0, #(CopiedTracks) do
            Soundtrack.Events.Add(SEVT.SelectedEventsTable, SoundtrackFrame_SelectedEvent, CopiedTracks[i])
        end
        SoundtrackFrame_RefreshEvents()
    end
end
function SoundtrackFrameClearCopiedTracksButton_OnClick()
    CopiedTracks = {}
end	
