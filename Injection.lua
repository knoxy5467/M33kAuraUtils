local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Injection = {}
local Injection = M33K.Injection

local hookedAuras = {}

function Injection.WrapBuffTriggerOptions(origFunc)
    return function(data, triggernum)
        local optionsTable = origFunc and origFunc(data, triggernum)
        if not optionsTable then return optionsTable end

        local trigger = data.triggers and data.triggers[triggernum] and data.triggers[triggernum].trigger
        if not trigger then return optionsTable end

        local aura_options = optionsTable["trigger." .. triggernum .. ".aura_options"]
        if aura_options then
            -- Inject Smart Ground Tracking header
            aura_options.groundTrackingHeader = {
                type = "header",
                name = "|cFF00FF00Smart Ground Aura Tracking|r",
                order = 50.0,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
            }

            -- Inject Toggle
            aura_options.useGroundTracking = {
                type = "toggle",
                name = "Enable Ground Zone Tracking",
                desc = "Tracks both ground zone duration and whether the player is standing inside.",
                order = 50.1,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
                get = function() return trigger.useGroundTracking end,
                set = function(info, v)
                    trigger.useGroundTracking = v
                    if ThisWeeksAuras and ThisWeeksAuras.Add then
                        ThisWeeksAuras.Add(data)
                    end
                    if ThisWeeksAuras and ThisWeeksAuras.ClearAndUpdateOptions then
                        ThisWeeksAuras.ClearAndUpdateOptions(data.id)
                    end
                end,
            }

            -- Inject Ground Duration Input
            aura_options.groundDuration = {
                type = "input",
                name = "Ground Duration (sec)",
                desc = "Lifetime of the ground-placed effect in seconds.",
                order = 50.2,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useGroundTracking)
                end,
                get = function() return tostring(trigger.groundDuration or 12) end,
                set = function(info, v)
                    trigger.groundDuration = tonumber(v) or 12
                    if ThisWeeksAuras and ThisWeeksAuras.Add then
                        ThisWeeksAuras.Add(data)
                    end
                end,
            }
        end

        return optionsTable
    end
end

function Injection.SyncAuraState(auraId, triggernum, spellId, duration)
    if not ThisWeeksAuras or not ThisWeeksAuras.GetTriggerStateForTrigger then return end

    local allStates = ThisWeeksAuras.GetTriggerStateForTrigger(auraId, triggernum)
    if not allStates then return end

    local state, remaining, dur, spellData = M33K.Engine.GetActiveState()

    allStates[""] = {
        show = remaining > 0,
        changed = true,
        progressType = "timed",
        duration = duration or dur or 12,
        expirationTime = (GetTime and GetTime() or 0) + remaining,
        inside = (state == M33K.Engine.STATE_ACTIVE_INSIDE),
        name = spellData and spellData.name or "",
        icon = spellData and spellData.icon or 135926,
    }

    if ThisWeeksAuras.UpdatedTriggerState then
        ThisWeeksAuras.UpdatedTriggerState(auraId)
    end
end

function Injection.Initialize()
    if not ThisWeeksAuras then return false end

    -- Hook options generator
    if OptionsPrivate and OptionsPrivate.GetBuffTriggerOptions then
        OptionsPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(OptionsPrivate.GetBuffTriggerOptions)
    end

    if ThisWeeksAuras.RegisterTriggerSystemOptions then
        local orig_Register = ThisWeeksAuras.RegisterTriggerSystemOptions
        ThisWeeksAuras.RegisterTriggerSystemOptions = function(systemTypes, optionsFunc)
            for _, sysType in ipairs(systemTypes) do
                if sysType == "aura2" then
                    optionsFunc = Injection.WrapBuffTriggerOptions(optionsFunc)
                end
            end
            return orig_Register(systemTypes, optionsFunc)
        end
    end

    -- Hook runtime engine updates
    M33K.Engine.RegisterCallback("ThisWeeksAuras_Sync", function(state, remaining, duration, spellData)
        for auraId, info in pairs(hookedAuras) do
            Injection.SyncAuraState(auraId, info.triggernum, info.spellId, info.duration)
        end
    end)

    return true
end

function Injection.RegisterHookedAura(auraId, triggernum, spellId, duration)
    hookedAuras[auraId] = {
        triggernum = triggernum,
        spellId = spellId,
        duration = duration,
    }
end

function Injection.UnregisterHookedAura(auraId)
    hookedAuras[auraId] = nil
end

