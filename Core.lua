local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

local EventFrame = CreateFrame and CreateFrame("Frame", "M33kAuraUtilsEventFrame") or nil

local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == AddonName then
            if M33K.Database and M33K.Database.Initialize then
                M33K.Database.Initialize()
            end
            if M33K.Engine and M33K.Engine.Initialize then
                M33K.Engine.Initialize()
            end
            if M33K.Injection and M33K.Injection.Initialize then
                M33K.Injection.Initialize()
            end
            if M33K.IntegTest and M33K.IntegTest.InitializeSlashHooks then
                M33K.IntegTest.InitializeSlashHooks()
            end
        elseif arg1 == "ThisWeeksAurasOptions" or arg1 == "WeakAurasOptions" or arg1 == "M33kAurasOptions" or arg1 == "ThisWeeksAuras" or arg1 == "WeakAuras" or arg1 == "M33kAuras" then
            if M33K.Injection and M33K.Injection.Initialize then
                M33K.Injection.Initialize()
            end
            if M33K.IntegTest and M33K.IntegTest.InitializeSlashHooks then
                M33K.IntegTest.InitializeSlashHooks()
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if M33K.Injection and M33K.Injection.Initialize then
            M33K.Injection.Initialize()
        end
        if M33K.IntegTest and M33K.IntegTest.InitializeSlashHooks then
            M33K.IntegTest.InitializeSlashHooks()
        end
    elseif event == "UNIT_AURA"
        or event == "SPELL_UPDATE_COOLDOWN"
        or event == "SPELL_UPDATE_CHARGES"
        or event == "SPELL_UPDATE_USABLE" then
        -- Drive CDM buff/spell state into WA on the same events WA itself uses,
        -- so our injected trigger behaves identically to the native trigger path.
        if M33K.Injection and M33K.Injection.SyncAllHookedAuras then
            M33K.Injection.SyncAllHookedAuras()
        end
    end
end

if EventFrame then
    EventFrame:RegisterEvent("ADDON_LOADED")
    EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    EventFrame:RegisterEvent("UNIT_AURA")
    EventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    EventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    EventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    EventFrame:SetScript("OnEvent", OnEvent)
end
