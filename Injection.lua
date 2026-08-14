local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Injection = {}
local Injection = M33K.Injection

local hookedAuras = {}
local isInitialized = false

local function GetAuraFramework()
    return _G.ThisWeeksAuras or _G.WeakAuras or _G.M33kAuras
end

function Injection.WrapBuffTriggerOptions(origFunc)
    return function(data, triggernum)
        local optionsTable = origFunc and origFunc(data, triggernum)
        if not optionsTable then return optionsTable end

        local trigger = data.triggers and data.triggers[triggernum] and data.triggers[triggernum].trigger
        if not trigger then return optionsTable end

        local aura_options = optionsTable["trigger." .. triggernum .. ".aura_options"] or optionsTable
        if aura_options then
            local WA = GetAuraFramework()

            -- Inject Cooldown Viewer Header
            aura_options.cvHeader = {
                type = "header",
                name = "|cFF00B4FFBlizzard Cooldown Viewer Tracking (M33kAuraUtils)|r",
                order = 50.0,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
            }

            -- Inject Cooldown Viewer Toggle
            aura_options.useCooldownViewer = {
                type = "toggle",
                name = "Enable Cooldown Viewer Tracking",
                desc = "Tracks active buff timers through Blizzard Cooldown Viewers (BuffIconCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer) and C_UnitAuras.",
                order = 50.1,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
                get = function() return trigger.useCooldownViewer end,
                set = function(info, v)
                    trigger.useCooldownViewer = v
                    if WA and WA.Add then
                        WA.Add(data)
                    end
                    if WA and WA.ClearAndUpdateOptions then
                        WA.ClearAndUpdateOptions(data.id)
                    end
                end,
            }

            -- Inject Linked Spell IDs Input
            aura_options.cvLinkedSpells = {
                type = "input",
                name = "Linked Spell IDs",
                desc = "Comma-separated list of spell IDs to match in Cooldown Viewer (e.g. 188370, 26573).",
                order = 50.2,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                get = function()
                    if type(trigger.cvLinkedSpells) == "table" then
                        return table.concat(trigger.cvLinkedSpells, ", ")
                    end
                    return tostring(trigger.cvLinkedSpells or "")
                end,
                set = function(info, v)
                    local list = {}
                    for id in string.gmatch(v or "", "(%d+)") do
                        table.insert(list, tonumber(id))
                    end
                    trigger.cvLinkedSpells = list
                    if WA and WA.Add then
                        WA.Add(data)
                    end
                end,
            }
        end

        return optionsTable
    end
end

function Injection.BuildTargetSpellList(trigger)
    local targets = {}
    if trigger.spellId then targets[trigger.spellId] = true end
    if trigger.spellName then targets[trigger.spellName] = true end
    if type(trigger.spellIds) == "table" then
        for _, id in ipairs(trigger.spellIds) do targets[id] = true end
    end
    if type(trigger.cvLinkedSpells) == "table" then
        for _, id in ipairs(trigger.cvLinkedSpells) do targets[id] = true end
    end
    return targets
end

function Injection.SyncAuraState(auraId, triggernum, targetSpells)
    local WA = GetAuraFramework()
    if not WA or not WA.GetTriggerStateForTrigger then return end

    local allStates = WA.GetTriggerStateForTrigger(auraId, triggernum)
    if not allStates then return end

    local active, exp, dur, icon = M33K.CooldownViewer.IsBuffActive(targetSpells)

    if active then
        allStates[""] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = dur or 0,
            expirationTime = exp or 0,
            icon = icon or 136243,
        }
    else
        allStates[""] = {
            show = false,
            changed = true,
        }
    end

    if WA.UpdatedTriggerState then
        WA.UpdatedTriggerState(auraId)
    end
end

function Injection.Initialize()
    local WA = GetAuraFramework()
    if not WA then return false end

    -- Hook Buff trigger options in OptionsPrivate / Options globals
    local optPrivate = _G.OptionsPrivate or (WA and WA.OptionsPrivate)
    if optPrivate and optPrivate.GetBuffTriggerOptions then
        optPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(optPrivate.GetBuffTriggerOptions)
    end

    -- Hook trigger system registration
    if WA.RegisterTriggerSystemOptions and not isInitialized then
        local orig_Register = WA.RegisterTriggerSystemOptions
        WA.RegisterTriggerSystemOptions = function(systemTypes, optionsFunc)
            for _, sysType in ipairs(systemTypes) do
                if sysType == "aura2" then
                    optionsFunc = Injection.WrapBuffTriggerOptions(optionsFunc)
                end
            end
            return orig_Register(systemTypes, optionsFunc)
        end
        isInitialized = true
    end

    return true
end

function Injection.RegisterHookedAura(auraId, triggernum, targetSpells)
    hookedAuras[auraId] = {
        triggernum = triggernum,
        targetSpells = targetSpells,
    }
end

function Injection.UnregisterHookedAura(auraId)
    hookedAuras[auraId] = nil
end
