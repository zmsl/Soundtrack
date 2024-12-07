
local PROFILES_COPY_CONFIRM = "PROFILES_COPY_CONFIRM"
local PROFILES_DELETE_CONFIRM = "PROFILES_DELETE_CONFIRM"
local PROFILES_RESET_CONFIRM = "PROFILES_RESET_CONFIRM"
local PROFILE_ALREADY_EXISTS = "PROFILE_ALREADY_EXISTS"

function ProfilesTab_OnLoad()
    LoadProfileDropDown.initialize = function () ProfilesTab_InitDropDown(ProfilesTab_LoadProfileDropDownItemSelected, false) end
    LoadProfileDropDownText:SetText("Load Profile")

    CopyFromProfileDropDown.initialize = function () ProfilesTab_InitDropDown(ProfilesTab_CopyFromProfileDropDownItemSelected, true) end
    CopyFromProfileDropDownText:SetText("Copy From")

    DeleteProfileDropDown.initialize = function () ProfilesTab_InitDropDown(ProfilesTab_DeleteProfileDropDownItemSelected, true) end
    DeleteProfileDropDownText:SetText("Delete Profile")
end

function ProfilesTab_InitDropDown(func, skipCurrentProfile)
    local profiles = SoundtrackAddon.db:GetProfiles()
    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    local info = UIDropDownMenu_CreateInfo()
    info.func = func
    for k, profileName in pairs(profiles) do
        if not skipCurrentProfile or profileName ~= currentProfile then
            info.text = profileName
            info.arg1 = profileName
            info.checked = profileName == currentProfile
            UIDropDownMenu_AddButton(info)
        end
    end
end

function ProfilesTab_LoadProfileDropDownItemSelected(self, profileName)
    Soundtrack.TraceProfiles("Selected profile to load: " .. profileName)
    SoundtrackAddon.db:SetProfile(profileName)
    ProfilesTab_ReloadProfile()
end

function ProfilesTab_CopyFromProfileDropDownItemSelected(self, profileName)
    Soundtrack.TraceProfiles("Selected profile to copy from: " .. profileName)

    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    StaticPopupDialogs[PROFILES_COPY_CONFIRM] = {
        text = "Are you sure you want to OVERRIDE the " .. currentProfile .. " profile with settings from " .. profileName .. "? You cannot undo this.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            SoundtrackAddon.db:CopyProfile(profileName)
            ProfilesTab_ReloadProfile()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show(PROFILES_COPY_CONFIRM)
end

function ProfilesTab_DeleteProfileDropDownItemSelected(self, profileName)
    Soundtrack.TraceProfiles("Selected profile to delete: " .. profileName)

    StaticPopupDialogs[PROFILES_DELETE_CONFIRM] = {
        text = "Are you sure you want to DELETE the " .. profileName .. " profile? You cannot undo this.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            SoundtrackAddon.db:DeleteProfile(profileName)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show(PROFILES_DELETE_CONFIRM)
end

function ProfilesTab_CreateNewProfile()
    local profileName = NewProfileEditBox:GetText()
    Soundtrack.TraceProfiles("Requested to create new profile: " .. profileName)

    local profiles = SoundtrackAddon.db:GetProfiles()
    if HasValue(profiles, profileName) then
        StaticPopupDialogs[PROFILE_ALREADY_EXISTS] = {
            text = "Profile already exists, not creating.",
            button1 = "Ok",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show(PROFILE_ALREADY_EXISTS)
    end

    SoundtrackAddon.db:SetProfile(profileName)
    NewProfileEditBox:SetText("")
    ProfilesTab_ReloadProfile()
end

function ProfilesTab_ResetCurrentProfile()
    Soundtrack.TraceProfiles("Requested to reset current profile")
    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    StaticPopupDialogs[PROFILES_RESET_CONFIRM] = {
        text = "Are you sure you want to RESET the " .. currentProfile .. " profile to default values? You cannot undo this.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            SoundtrackAddon.db:ResetProfile()
            ProfilesTab_ReloadProfile()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show(PROFILES_RESET_CONFIRM)
end

function ProfilesTab_ReloadProfile()
    _TracksLoaded = false
    SoundtrackAddon:VARIABLES_LOADED()
    ProfilesTab_RefreshProfilesFrame()
end

function ProfilesTab_RefreshProfilesFrame()
    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    CurrentProfileName:SetText(currentProfile)
end
