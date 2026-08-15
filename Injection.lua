local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Injection = {}
local Injection = M33K.Injection

local hookedAuras = {}

-- Safely locate the trigger's sub-table in optionsTable without ever mutating root
local function FindTriggerOptionsSubTable(optionsTable, triggernum)
    if type(optionsTable) ~= "table" then return nil end

    -- 1. Check exact aura_options key
    if type(optionsTable["trigger." .. triggernum .. ".aura_options"]) == "table" then
        return optionsTable["trigger." .. triggernum .. ".aura_options"]
    end

    -- 2. Check any "trigger.<triggernum>.<anything>" key
    local prefix = "trigger." .. triggernum .. "."
    for k, v in pairs(optionsTable) do
        if type(k) == "string" and string.sub(k, 1, #prefix) == prefix and type(v) == "table" then
            return v
        end
    end

    return nil
end

local function IsSpellTrigger(trigger)
    if not trigger then return false end
    if trigger.type == "spell" then return true end
    if trigger.type == "status" or trigger.type == "event" then
        local ev = trigger.event
        if ev == "Action Usable"
           or ev == "Cooldown Progress (Spell)"
           or ev == "Spell Known"
           or ev == "Cast"
           or ev == "Spell Activation Overlay" then
            return true
        end
    end
    return false
end

-- Build dropdown values from a tracked entries table
local function BuildDropdownValues(tracked, defaultLabel)
    local vals = { ["0"] = defaultLabel or "-- Select a spell --" }
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

----------------------------------------------------------------------
-- Buff Trigger Options Wrapper (for aura2 triggers)
----------------------------------------------------------------------
function Injection.WrapBuffTriggerOptions(origFunc)
    return function(data, triggernum)
        local optionsTable = origFunc and origFunc(data, triggernum)
        if not optionsTable then return optionsTable end

        local trigger = data.triggers and data.triggers[triggernum] and data.triggers[triggernum].trigger
        if not trigger then return optionsTable end

        -- Only inject into player aura/buff triggers
        if not (trigger.type == "aura2" or trigger.type == "aura") then
            return optionsTable
        end

        local subTable = FindTriggerOptionsSubTable(optionsTable, triggernum)
        if not subTable then return optionsTable end

        local WA = _G.ThisWeeksAuras or _G.M33kAuras or _G.WeakAuras
        local dw = WA and WA.doubleWidth or 2

        -- Header
        subTable.cvHeader = {
            type = "header",
            name = "|cFF00B4FFBlizzard Cooldown Manager Tracking (M33kAuraUtils)|r",
            order = 50.0,
            hidden = function()
                return not (trigger.unit == "player")
            end,
        }

        -- Enable Toggle
        subTable.useCooldownViewer = {
            type = "toggle",
            name = "Enable Cooldown Viewer Tracking",
            desc = "Tracks active buff timers exclusively through the Blizzard Cooldown Manager (BuffIconCooldownViewer, BuffBarCooldownViewer).",
            order = 50.1,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player")
            end,
            get = function() return trigger.useCooldownViewer end,
            set = function(info, v)
                trigger.useCooldownViewer = v
                -- Auto-register/unregister into the event-driven sync path
                if v then
                    local targets = Injection.BuildTargetSpellList(trigger)
                    Injection.RegisterHookedAura(data.id, triggernum, targets)
                else
                    Injection.UnregisterHookedAura(data.id)
                end
                if WA and WA.Add then WA.Add(data) end
                if WA and WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
            end,
        }

        -- Linked Spell IDs (manual input)
        subTable.cvLinkedSpells = {
            type = "input",
            name = "Linked Spell IDs",
            desc = "Comma-separated list of spell IDs to match in Cooldown Manager (e.g. 188370, 26573).",
            order = 50.2,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player" and trigger.useCooldownViewer)
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

        -- Checkbox: Show Untracked / All Buffs
        subTable.cvShowAllBuffs = {
            type = "toggle",
            name = "Show Untracked Buffs",
            desc = "When checked, includes all potential buffs from the Blizzard Cooldown Manager database, even if not currently tracked on your bars.",
            order = 50.3,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player" and trigger.useCooldownViewer)
            end,
            get = function() return trigger.cvShowAllBuffs == true end,
            set = function(info, v)
                trigger.cvShowAllBuffs = v
                if WA and WA.Add then WA.Add(data) end
                if WA and WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
            end,
        }

        -- Dropdown: Tracked Buffs & Bars
        subTable.cvPickerBuffsAndBars = {
            type = "select",
            name = "Select Tracked Buff / Bar",
            desc = "Shows buffs and bars from your Blizzard Cooldown Manager. Select one to add it to your aura tracking.",
            order = 50.4,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player" and trigger.useCooldownViewer)
            end,
            values = function()
                if M33K.CooldownViewer and M33K.CooldownViewer.EnumerateTrackedBuffsAndBars then
                    local includeAll = (trigger.cvShowAllBuffs == true)
                    return BuildDropdownValues(M33K.CooldownViewer.EnumerateTrackedBuffsAndBars(includeAll), "-- Select Buff or Bar --")
                end
                return { ["0"] = "-- No buffs/bars found --" }
            end,
            get = function() return trigger._cvPickBuffOrBar or "0" end,
            set = function(info, v) trigger._cvPickBuffOrBar = v end,
        }

        -- Button: Add Selected Buff
        subTable.cvPickerAdd = {
            type = "execute",
            name = "Add Selected Buff",
            desc = "Adds the chosen buff to the Linked Spell IDs list.",
            order = 50.5,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player" and trigger.useCooldownViewer)
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

                    -- Keep the hooked aura registry up-to-date with the new spell list
                    if trigger.useCooldownViewer then
                        local targets = Injection.BuildTargetSpellList(trigger)
                        Injection.RegisterHookedAura(data.id, triggernum, targets)
                    end
                    if WA then
                        if WA.Add then WA.Add(data) end
                        if WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
                    end
                end
            end,
        }

        -- Button: Refresh Lists
        subTable.cvPickerRefresh = {
            type = "execute",
            name = "|cFF00B4FFRefresh Tracked Buffs|r",
            desc = "Re-scans the Blizzard Cooldown Manager for currently tracked buffs and bars.",
            order = 50.6,
            width = dw,
            hidden = function()
                return not (trigger.unit == "player" and trigger.useCooldownViewer)
            end,
            func = function()
                if WA and WA.ClearAndUpdateOptions then
                    WA.ClearAndUpdateOptions(data.id)
                end
            end,
        }

        return optionsTable
    end
end

----------------------------------------------------------------------
-- Spell Trigger Options Wrapper (for spell/action/status triggers)
----------------------------------------------------------------------
function Injection.WrapSpellTriggerOptions(origFunc)
    return function(data, triggernum)
        local optionsTable = origFunc and origFunc(data, triggernum)
        if not optionsTable then return optionsTable end

        local trigger = data.triggers and data.triggers[triggernum] and data.triggers[triggernum].trigger
        if not trigger then return optionsTable end

        -- Only inject if this is actually a spell trigger
        if not IsSpellTrigger(trigger) then
            return optionsTable
        end

        local subTable = FindTriggerOptionsSubTable(optionsTable, triggernum)
        if not subTable then return optionsTable end

        local WA = _G.ThisWeeksAuras or _G.M33kAuras or _G.WeakAuras
        local dw = WA and WA.doubleWidth or 2

        -- Header
        subTable.cvHeader = {
            type = "header",
            name = "|cFF00B4FFBlizzard Cooldown Manager Tracking (M33kAuraUtils)|r",
            order = 50.0,
            hidden = function()
                return not IsSpellTrigger(trigger)
            end,
        }

        -- Enable Toggle
        subTable.useCooldownViewer = {
            type = "toggle",
            name = "Enable Cooldown Viewer Tracking",
            desc = "Tracks spell cooldowns, charges, and usability through Blizzard Cooldown Manager (Essential & Utility Viewers).",
            order = 50.1,
            width = dw,
            hidden = function()
                return not IsSpellTrigger(trigger)
            end,
            get = function() return trigger.useCooldownViewer end,
            set = function(info, v)
                trigger.useCooldownViewer = v
                if WA and WA.Add then WA.Add(data) end
                if WA and WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
            end,
        }

        -- Linked Spell IDs (manual input)
        subTable.cvLinkedSpells = {
            type = "input",
            name = "Linked Spell IDs",
            desc = "Comma-separated list of spell IDs to track in Cooldown Manager.",
            order = 50.2,
            width = dw,
            hidden = function()
                return not (IsSpellTrigger(trigger) and trigger.useCooldownViewer)
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

        -- Checkbox: Show Untracked Cooldowns
        subTable.cvShowAllCooldowns = {
            type = "toggle",
            name = "Show Untracked Cooldowns",
            desc = "When checked, includes all cooldowns from the Blizzard Cooldown Manager database, even if not currently tracked on your bars.",
            order = 50.3,
            width = dw,
            hidden = function()
                return not (IsSpellTrigger(trigger) and trigger.useCooldownViewer)
            end,
            get = function() return trigger.cvShowAllCooldowns == true end,
            set = function(info, v)
                trigger.cvShowAllCooldowns = v
                if WA and WA.Add then WA.Add(data) end
                if WA and WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
            end,
        }

        -- Dropdown: Essential & Utility Cooldowns
        subTable.cvPickerCooldowns = {
            type = "select",
            name = "Select Tracked Cooldown",
            desc = "Shows essential and utility cooldowns from your Blizzard Cooldown Manager.",
            order = 50.4,
            width = dw,
            hidden = function()
                return not (IsSpellTrigger(trigger) and trigger.useCooldownViewer)
            end,
            values = function()
                if M33K.CooldownViewer and M33K.CooldownViewer.EnumerateCooldowns then
                    local includeAll = (trigger.cvShowAllCooldowns == true)
                    return BuildDropdownValues(M33K.CooldownViewer.EnumerateCooldowns(includeAll), "-- Select Cooldown --")
                end
                return { ["0"] = "-- No cooldowns found --" }
            end,
            get = function() return trigger._cvPickCooldown or "0" end,
            set = function(info, v) trigger._cvPickCooldown = v end,
        }

        -- Button: Add Selected Cooldown
        subTable.cvPickerAdd = {
            type = "execute",
            name = "Add Selected Cooldown",
            desc = "Sets the chosen cooldown spell as the active tracked spell.",
            order = 50.5,
            width = dw,
            hidden = function()
                return not (IsSpellTrigger(trigger) and trigger.useCooldownViewer)
            end,
            func = function()
                local sel = tonumber(trigger._cvPickCooldown)
                if sel and sel ~= 0 then
                    trigger.spellName = sel
                    trigger.spellId = sel
                    if type(trigger.cvLinkedSpells) ~= "table" then
                        trigger.cvLinkedSpells = {}
                    end

                    local isDup = false
                    for _, existing in ipairs(trigger.cvLinkedSpells) do
                        if existing == sel then isDup = true; break end
                    end
                    if not isDup then
                        table.insert(trigger.cvLinkedSpells, sel)
                    end

                    -- Auto-add linked/override IDs
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

                    trigger._cvPickCooldown = "0"

                    if WA then
                        if WA.Add then WA.Add(data) end
                        if WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
                    end
                end
            end,
        }

        -- Button: Refresh Cooldowns
        subTable.cvPickerRefresh = {
            type = "execute",
            name = "|cFF00B4FFRefresh Cooldowns|r",
            desc = "Re-scans the Blizzard Cooldown Manager for cooldowns.",
            order = 50.6,
            width = dw,
            hidden = function()
                return not (IsSpellTrigger(trigger) and trigger.useCooldownViewer)
            end,
            func = function()
                if WA and WA.ClearAndUpdateOptions then
                    WA.ClearAndUpdateOptions(data.id)
                end
            end,
        }

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

----------------------------------------------------------------------
-- Clear all trigger-owned fields from a state table, leaving any
-- WA-managed display/positioning keys untouched.
----------------------------------------------------------------------
local TRIGGER_FIELDS = {
    "show", "changed", "progressType",
    "duration", "expirationTime", "total", "remaining",
    "icon", "stacks", "applications", "charges", "maxCharges",
    "value", "spellId", "name",
    "usable", "notEnoughPower", "onCooldown",
}
local function ClearTriggerFields(s)
    for _, k in ipairs(TRIGGER_FIELDS) do
        s[k] = nil
    end
end

----------------------------------------------------------------------
-- Sync Aura State (Buffs / Auras)
----------------------------------------------------------------------
function Injection.SyncAuraState(auraId, triggernum, targetSpells)
    local frameworks = GetAuraFrameworks()
    if #frameworks == 0 then return end

    local active, exp, dur, icon, stacks, matchedID, name = M33K.CooldownViewer.IsBuffActive(targetSpells)

    for _, WA in ipairs(frameworks) do
        if WA and WA.GetTriggerStateForTrigger then
            local allStates = WA.GetTriggerStateForTrigger(auraId, triggernum)
            if allStates then
                -- Merge into existing state to preserve WA-managed display settings
                -- (position, anchor, size, etc.) that WA writes onto this table.
                local s = allStates[""] or {}
                allStates[""] = s

                if active then
                    local now = GetTime and GetTime() or 0
                    local rem = (exp and exp > 0) and math.max(0, exp - now) or 0

                    s.show = true
                    s.changed = true
                    s.progressType = "timed"
                    s.duration = dur or 0
                    s.expirationTime = exp or 0
                    s.total = dur or 0
                    s.remaining = rem
                    s.icon = icon or 136243
                    s.stacks = stacks or 0
                    s.applications = stacks or 0
                    s.charges = stacks or 0
                    s.value = stacks or 0
                    s.spellId = matchedID
                    s.name = name or ("Spell " .. (matchedID or 0))
                else
                    -- Clear all stale trigger fields so WA doesn't keep the timer alive.
                    -- WA-managed positioning keys on the table are left intact.
                    ClearTriggerFields(s)
                    s.show = false
                    s.changed = true
                end

                if WA.UpdatedTriggerState then
                    WA.UpdatedTriggerState(auraId)
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Sync Spell State (Spell Usable / Cooldown Progress)
----------------------------------------------------------------------
function Injection.SyncSpellState(auraId, triggernum, targetSpells, ignoreGCD)
    local frameworks = GetAuraFrameworks()
    if #frameworks == 0 then return end

    local isUsable, notEnoughPower, onCooldown, start, dur, exp, charges, maxCharges, icon, matchedID, name = M33K.CooldownViewer.IsSpellUsable(targetSpells, ignoreGCD)

    for _, WA in ipairs(frameworks) do
        if WA and WA.GetTriggerStateForTrigger then
            local allStates = WA.GetTriggerStateForTrigger(auraId, triggernum)
            if allStates then
                -- Merge into existing state to preserve WA-managed display settings
                -- (position, anchor, size, etc.) that WA writes onto this table.
                local s = allStates[""] or {}
                allStates[""] = s

                local now = GetTime and GetTime() or 0
                local rem = (exp and exp > now) and (exp - now) or 0

                if not isUsable then
                    -- Clear all stale trigger fields so WA untriggers cleanly.
                    -- WA-managed positioning keys on the table are left intact.
                    ClearTriggerFields(s)
                    s.show = false
                    s.changed = true
                else
                    s.show = true
                    s.changed = true
                    s.usable = true
                    s.notEnoughPower = notEnoughPower
                    s.onCooldown = onCooldown
                    s.progressType = "timed"
                    s.duration = dur or 0
                    s.expirationTime = exp or 0
                    s.total = dur or 0
                    s.remaining = rem
                    s.icon = icon or 136243
                    s.charges = charges or 0
                    s.maxCharges = maxCharges or 0
                    s.stacks = charges or 0
                    s.value = charges or 0
                    s.spellId = matchedID
                    s.name = name or ("Spell " .. (matchedID or 0))
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

    -- Hook OptionsPrivate globals
    local optPrivate = _G.OptionsPrivate
    if optPrivate then
        if optPrivate.GetBuffTriggerOptions and not optPrivate._cvBuffWrapped then
            optPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(optPrivate.GetBuffTriggerOptions)
            optPrivate._cvBuffWrapped = true
        end
        if optPrivate.GetSpellTriggerOptions and not optPrivate._cvSpellWrapped then
            optPrivate.GetSpellTriggerOptions = Injection.WrapSpellTriggerOptions(optPrivate.GetSpellTriggerOptions)
            optPrivate._cvSpellWrapped = true
        end
    end

    -- Hook trigger system registration on every available framework
    for _, WA in ipairs(frameworks) do
        if WA.RegisterTriggerSystemOptions and not WA._cvRegisterHooked then
            local orig_Register = WA.RegisterTriggerSystemOptions
            WA.RegisterTriggerSystemOptions = function(systemTypes, optionsFunc)
                local hasAura2 = false
                local hasGeneric = false
                for _, sysType in ipairs(systemTypes) do
                    if sysType == "aura2" or sysType == "aura" then
                        hasAura2 = true
                    elseif sysType == "status" or sysType == "event" or sysType == "custom" or sysType == "spell" then
                        hasGeneric = true
                    end
                end

                if hasAura2 then
                    optionsFunc = Injection.WrapBuffTriggerOptions(optionsFunc)
                end
                if hasGeneric then
                    optionsFunc = Injection.WrapSpellTriggerOptions(optionsFunc)
                end

                return orig_Register(systemTypes, optionsFunc)
            end
            WA._cvRegisterHooked = true
        end

        -- Hook WA.Add to auto-register CDM-enabled triggers whenever WA loads an aura.
        -- This ensures auras configured with CDM tracking are wired into the event-driven
        -- sync path on login, reload, and every time the aura is saved/updated.
        if WA.Add and not WA._cvAddHooked then
            local orig_Add = WA.Add
            WA.Add = function(data, ...)
                local result = orig_Add(data, ...)
                if data and data.id and data.triggers then
                    for tn, triggerEntry in pairs(data.triggers) do
                        local trigger = triggerEntry and triggerEntry.trigger
                        if trigger
                           and trigger.useCooldownViewer
                           and (trigger.type == "aura2" or trigger.type == "aura") then
                            local targets = Injection.BuildTargetSpellList(trigger)
                            Injection.RegisterHookedAura(data.id, tn, targets)
                        end
                    end
                end
                return result
            end
            WA._cvAddHooked = true
        end

        if WA.OptionsPrivate then
            if WA.OptionsPrivate.GetBuffTriggerOptions and not WA.OptionsPrivate._cvBuffWrapped then
                WA.OptionsPrivate.GetBuffTriggerOptions = Injection.WrapBuffTriggerOptions(WA.OptionsPrivate.GetBuffTriggerOptions)
                WA.OptionsPrivate._cvBuffWrapped = true
            end
            if WA.OptionsPrivate.GetSpellTriggerOptions and not WA.OptionsPrivate._cvSpellWrapped then
                WA.OptionsPrivate.GetSpellTriggerOptions = Injection.WrapSpellTriggerOptions(WA.OptionsPrivate.GetSpellTriggerOptions)
                WA.OptionsPrivate._cvSpellWrapped = true
            end
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

----------------------------------------------------------------------
-- SyncAllHookedAuras: called by Core.lua on UNIT_AURA / SPELL_UPDATE_*
-- events so CDM buff state flows through the regular WA evaluation path.
----------------------------------------------------------------------
function Injection.SyncAllHookedAuras()
    for auraId, info in pairs(hookedAuras) do
        Injection.SyncAuraState(auraId, info.triggernum, info.targetSpells)
    end
end
