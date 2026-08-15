local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Injection = {}
local Injection = M33K.Injection

local hookedAuras = {}

-- Build dropdown values from a tracked entries table
local function BuildDropdownValues(tracked, defaultLabel)
    local vals = { ["0"] = defaultLabel or "-- Select a tracked spell --" }
    if not tracked then return vals end

    for spellID, entry in pairs(tracked) do
        local label = entry.name or ("Spell " .. spellID)
        local iconStr = ""
        if entry.icon and entry.icon ~= 136243 then
            iconStr = "|T" .. entry.icon .. ":0|t "
        end
        local catTag = ""
        if entry.category then
            if entry.category == "TrackedBuff" or entry.category == "Buff" then
                catTag = " |cFF00FF00[Tracked Buff]|r"
            elseif entry.category == "TrackedBar" or entry.category == "Bar" then
                catTag = " |cFF00FFFF[Tracked Bar]|r"
            elseif entry.category == "Essential" then
                catTag = " |cFFFF6600[Essential]|r"
            elseif entry.category == "Utility" then
                catTag = " |cFF3399FF[Utility]|r"
            end
        end
        vals[tostring(spellID)] = iconStr .. label .. " (" .. spellID .. ")" .. catTag
    end
    return vals
end

function Injection.WrapBuffTriggerOptions(origFunc)
    return function(data, triggernum)
        local optionsTable = origFunc and origFunc(data, triggernum)
        if not optionsTable then return optionsTable end

        local trigger = data.triggers and data.triggers[triggernum] and data.triggers[triggernum].trigger
        if not trigger then return optionsTable end

        local aura_options = optionsTable["trigger." .. triggernum .. ".aura_options"] or optionsTable
        if aura_options then
            local WA = _G.ThisWeeksAuras or _G.M33kAuras or _G.WeakAuras
            local dw = WA and WA.doubleWidth or 2

            -- Inject Cooldown Viewer Header
            aura_options.cvHeader = {
                type = "header",
                name = "|cFF00B4FFBlizzard Cooldown Manager Tracking (M33kAuraUtils)|r",
                order = 50.0,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
            }

            -- Inject Cooldown Viewer Toggle
            aura_options.useCooldownViewer = {
                type = "toggle",
                name = "Enable Cooldown Viewer Tracking",
                desc = "Tracks active buff timers through Blizzard Cooldown Manager (BuffIconCooldownViewer, BuffBarCooldownViewer) and C_UnitAuras.",
                order = 50.1,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
                get = function() return trigger.useCooldownViewer end,
                set = function(info, v)
                    trigger.useCooldownViewer = v
                    if WA and WA.Add then WA.Add(data) end
                    if WA and WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
                end,
            }

            -- Linked Spell IDs (manual input)
            aura_options.cvLinkedSpells = {
                type = "input",
                name = "Linked Spell IDs",
                desc = "Comma-separated list of spell IDs to match in Cooldown Manager (e.g. 188370, 26573).",
                order = 50.2,
                width = dw,
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
                    if WA and WA.Add then WA.Add(data) end
                end,
            }

            -- Dropdown: Tracked Buffs & Bars ONLY (strictly for aura/buff triggers)
            aura_options.cvPickerBuffsAndBars = {
                type = "select",
                name = "Select Tracked Buff / Bar",
                desc = "Shows buffs and bars actively tracked in your Blizzard Cooldown Manager. Select one to add it to your aura tracking.",
                order = 50.3,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                values = function()
                    if M33K.CooldownViewer and M33K.CooldownViewer.EnumerateTrackedBuffsAndBars then
                        return BuildDropdownValues(M33K.CooldownViewer.EnumerateTrackedBuffsAndBars(), "-- Select Tracked Buff or Bar --")
                    end
                    return { ["0"] = "-- No actively tracked buffs/bars found --" }
                end,
                get = function() return trigger._cvPickBuffOrBar or "0" end,
                set = function(info, v) trigger._cvPickBuffOrBar = v end,
            }

            -- Button: Add Selected Spell
            aura_options.cvPickerAdd = {
                type = "execute",
                name = "Add Selected Buff",
                desc = "Adds the chosen buff to the Linked Spell IDs list.",
                order = 50.4,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                func = function()
                    if type(trigger.cvLinkedSpells) ~= "table" then
                        trigger.cvLinkedSpells = {}
                    end

                    local sel = tonumber(trigger._cvPickBuffOrBar)
                    if sel and sel ~= 0 then
                        local isDup = false
                        for _, existing in ipairs(trigger.cvLinkedSpells) do
                            if existing == sel then isDup = true; break end
                        end
                        if not isDup then
                            table.insert(trigger.cvLinkedSpells, sel)
                        end

                        -- Auto-add linked/override IDs from CDM entry
                        if M33K.CooldownViewer then
                            local all = M33K.CooldownViewer.EnumerateAll()
                            local entry = all[sel]
                            if entry and type(entry.linkedSpellIDs) == "table" then
                                for _, lid in ipairs(entry.linkedSpellIDs) do
                                    local lidDup = false
                                    for _, existing in ipairs(trigger.cvLinkedSpells) do
                                        if existing == lid then lidDup = true; break end
                                    end
                                    if not lidDup then
                                        table.insert(trigger.cvLinkedSpells, lid)
                                    end
                                end
                            end
                        end

                        trigger._cvPickBuffOrBar = "0"

                        if WA then
                            if WA.Add then WA.Add(data) end
                            if WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
                        end
                    end
                end,
            }

            -- Button: Refresh Lists
            aura_options.cvPickerRefresh = {
                type = "execute",
                name = "|cFF00B4FFRefresh Tracked Buffs|r",
                desc = "Re-scans the Blizzard Cooldown Manager for currently tracked buffs and bars.",
                order = 50.5,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                func = function()
                    if WA and WA.ClearAndUpdateOptions then
                        WA.ClearAndUpdateOptions(data.id)
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

local function GetAuraFrameworks()
    local frameworks = {}
    if _G.ThisWeeksAuras then table.insert(frameworks, _G.ThisWeeksAuras) end
    if _G.M33kAuras then table.insert(frameworks, _G.M33kAuras) end
    if _G.WeakAuras then table.insert(frameworks, _G.WeakAuras) end
    return frameworks
end

function Injection.SyncAuraState(auraId, triggernum, targetSpells)
    local frameworks = GetAuraFrameworks()
    if #frameworks == 0 then return end

    local active, exp, dur, icon, stacks, matchedID, name = M33K.CooldownViewer.IsBuffActive(targetSpells)

    for _, WA in ipairs(frameworks) do
        if WA and WA.GetTriggerStateForTrigger then
            local allStates = WA.GetTriggerStateForTrigger(auraId, triggernum)
            if allStates then
                if active then
                    local now = GetTime and GetTime() or 0
                    local rem = (exp and exp > 0) and math.max(0, exp - now) or 0

                    allStates[""] = {
                        show = true,
                        changed = true,
                        progressType = "timed",
                        duration = dur or 0,
                        expirationTime = exp or 0,
                        total = dur or 0,
                        remaining = rem,
                        icon = icon or 136243,
                        stacks = stacks or 0,
                        applications = stacks or 0,
                        charges = stacks or 0,
                        value = stacks or 0,
                        spellId = matchedID,
                        name = name or ("Spell " .. (matchedID or 0)),
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
        end
    end
end

function Injection.Initialize()
    local frameworks = GetAuraFrameworks()
    if #frameworks == 0 then return false end

    -- Hook Buff trigger options in OptionsPrivate / Options globals
    local optPrivate = _G.OptionsPrivate
    if optPrivate and optPrivate.GetBuffTriggerOptions and not optPrivate._cvWrapped then
        optPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(optPrivate.GetBuffTriggerOptions)
        optPrivate._cvWrapped = true
    end

    -- Hook trigger system registration on every available framework
    for _, WA in ipairs(frameworks) do
        if WA.RegisterTriggerSystemOptions and not WA._cvRegisterHooked then
            local orig_Register = WA.RegisterTriggerSystemOptions
            WA.RegisterTriggerSystemOptions = function(systemTypes, optionsFunc)
                for _, sysType in ipairs(systemTypes) do
                    if sysType == "aura2" then
                        optionsFunc = Injection.WrapBuffTriggerOptions(optionsFunc)
                    end
                end
                return orig_Register(systemTypes, optionsFunc)
            end
            WA._cvRegisterHooked = true
        end

        if WA.OptionsPrivate and WA.OptionsPrivate.GetBuffTriggerOptions and not WA.OptionsPrivate._cvWrapped then
            WA.OptionsPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(WA.OptionsPrivate.GetBuffTriggerOptions)
            WA.OptionsPrivate._cvWrapped = true
        end
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
