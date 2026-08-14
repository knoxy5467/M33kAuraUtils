local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K
_G.M33K = M33K

local frame = CreateFrame("Frame", "M33kAuraUtilsEventFrame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == AddonName then
            M33K.Database.Initialize()
            M33K.Options.Initialize()
        end

    elseif event == "PLAYER_LOGIN" then
        M33K.Engine.Initialize()
        M33K.UI.CreateMainFrame()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if CombatLogGetCurrentEventInfo then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if subEvent == "SPELL_CAST_SUCCESS" then
                M33K.Engine.OnSpellCastSuccess(sourceGUID, spellId)
            end
        end

    elseif event == "UNIT_AURA" then
        local unit = ...
        M33K.Engine.OnUnitAura(unit)

    elseif event == "PLAYER_ENTERING_WORLD" then
        M33K.Engine.Reset()
    end
end)
