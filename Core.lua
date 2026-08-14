local AddonName, GAT = ...

local frame = CreateFrame("Frame", "GroundAuraTrackerEventFrame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == AddonName then
            GAT.Database.Initialize()
            GAT.Options.Initialize()
        end

    elseif event == "PLAYER_LOGIN" then
        GAT.Engine.Initialize()
        GAT.UI.CreateMainFrame()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if CombatLogGetCurrentEventInfo then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if subEvent == "SPELL_CAST_SUCCESS" then
                GAT.Engine.OnSpellCastSuccess(sourceGUID, spellId)
            end
        end

    elseif event == "UNIT_AURA" then
        local unit = ...
        GAT.Engine.OnUnitAura(unit)

    elseif event == "PLAYER_ENTERING_WORLD" then
        GAT.Engine.Reset()
    end
end)
