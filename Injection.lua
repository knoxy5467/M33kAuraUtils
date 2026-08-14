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

-- Build dropdown values from a tracked entries table
local function BuildDropdownValues(tracked)
    local vals = { ["0"] = "-- Select a spell --" }
    if not tracked then return vals end

    for spellID, entry in pairs(tracked) do
        local label = entry.name or ("Spell " .. spellID)
        local iconStr = ""
        if entry.icon and entry.icon ~= 136243 then
            iconStr = "|T" .. entry.icon .. ":0|t "
        end
        local catTag = ""
        if entry.category then
            if entry.category == "Buff" then
                catTag = " |cFF00FF00[Buff]|r"
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
            local WA = GetAuraFramework()
            local dw = WA and WA.doubleWidth or 2

            -- Inject Cooldown Viewer Header
            aura_options.cvHeader = {
                type = "header",
                name = "|cFF00B4FFCooldown Viewer Tracking (M33kAuraUtils)|r",
                order = 50.0,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player")
                end,
            }

            -- Inject Cooldown Viewer Toggle
            aura_options.useCooldownViewer = {
                type = "toggle",
                name = "Enable Cooldown Viewer Tracking",
                desc = "Tracks active buff timers through Blizzard Cooldown Viewers and C_UnitAuras.",
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
                desc = "Comma-separated list of spell IDs to match (e.g. 188370, 26573).",
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

            -- Dropdown: Buffs only (from BuffIconCooldownViewer, filtered to buff timers)
            aura_options.cvPickerBuffs = {
                type = "select",
                name = "Buffs",
                desc = "Active buff timers from the Blizzard Cooldown Manager.",
                order = 50.3,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                values = function()
                    if M33K.CooldownViewer and M33K.CooldownViewer.EnumerateTracked then
                        return BuildDropdownValues(M33K.CooldownViewer.EnumerateTracked("Buff", true))
                    end
                    return { ["0"] = "-- No buffs found --" }
                end,
                get = function() return trigger._cvPickBuff or "0" end,
                set = function(info, v) trigger._cvPickBuff = v end,
            }

            -- Dropdown: Essential Cooldowns (from CDM data layer)
            aura_options.cvPickerEssential = {
                type = "select",
                name = "Essential Cooldowns",
                desc = "Essential cooldowns from the Blizzard Cooldown Manager.",
                order = 50.4,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                values = function()
                    if M33K.CooldownViewer then
                        -- Merge live viewer icons + CDM data layer
                        local merged = {}
                        local fromViewer = M33K.CooldownViewer.EnumerateTracked("Essential", false)
                        for k, v in pairs(fromViewer) do merged[k] = v end
                        local fromCDM = M33K.CooldownViewer.EnumerateFromCDM("Essential")
                        for k, v in pairs(fromCDM) do if not merged[k] then merged[k] = v end end
                        return BuildDropdownValues(merged)
                    end
                    return { ["0"] = "-- No essentials found --" }
                end,
                get = function() return trigger._cvPickEssential or "0" end,
                set = function(info, v) trigger._cvPickEssential = v end,
            }

            -- Dropdown: Utility Cooldowns (from CDM data layer)
            aura_options.cvPickerUtility = {
                type = "select",
                name = "Utility Cooldowns",
                desc = "Utility cooldowns from the Blizzard Cooldown Manager.",
                order = 50.5,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                values = function()
                    if M33K.CooldownViewer then
                        local merged = {}
                        local fromViewer = M33K.CooldownViewer.EnumerateTracked("Utility", false)
                        for k, v in pairs(fromViewer) do merged[k] = v end
                        local fromCDM = M33K.CooldownViewer.EnumerateFromCDM("Utility")
                        for k, v in pairs(fromCDM) do if not merged[k] then merged[k] = v end end
                        return BuildDropdownValues(merged)
                    end
                    return { ["0"] = "-- No utilities found --" }
                end,
                get = function() return trigger._cvPickUtility or "0" end,
                set = function(info, v) trigger._cvPickUtility = v end,
            }

            -- Button: Add selected spell(s) from any picker
            aura_options.cvPickerAdd = {
                type = "execute",
                name = "Add Selected",
                desc = "Adds the spell selected in any dropdown above to the Linked Spell IDs list.",
                order = 50.6,
                width = dw,
                hidden = function()
                    return not (trigger.type == "aura2" and trigger.unit == "player" and trigger.useCooldownViewer)
                end,
                func = function()
                    if type(trigger.cvLinkedSpells) ~= "table" then
                        trigger.cvLinkedSpells = {}
                    end

                    -- Collect selections from all three pickers
                    local selections = {
                        tonumber(trigger._cvPickBuff),
                        tonumber(trigger._cvPickEssential),
                        tonumber(trigger._cvPickUtility),
                    }

                    local added = false
                    for _, sel in ipairs(selections) do
                        if sel and sel ~= 0 then
                            -- Don't add duplicates
                            local isDup = false
                            for _, existing in ipairs(trigger.cvLinkedSpells) do
                                if existing == sel then isDup = true; break end
                            end
                            if not isDup then
                                table.insert(trigger.cvLinkedSpells, sel)
                                added = true
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
                        end
                    end

                    -- Reset picker selections
                    trigger._cvPickBuff = "0"
                    trigger._cvPickEssential = "0"
                    trigger._cvPickUtility = "0"

                    if added and WA then
                        if WA.Add then WA.Add(data) end
                        if WA.ClearAndUpdateOptions then WA.ClearAndUpdateOptions(data.id) end
                    end
                end,
            }

            -- Button: Refresh all lists
            aura_options.cvPickerRefresh = {
                type = "execute",
                name = "|cFF00B4FFRefresh Lists|r",
                desc = "Re-scans the Blizzard Cooldown Manager for all categories.",
                order = 50.7,
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
