local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

local M33K = {}
Harness.LoadFullAddon(M33K)
M33K.Injection.Initialize()

Harness.BeginSuite("Cross-Addon Injection & Cooldown Viewer Integration Tests")

Harness.RunTest("1. Injection wraps BuffTrigger options generator and injects ONLY Tracked Buffs & Bars controls", function()
    local dummyData = {
        id = "TestCooldownAura",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    spellId = 188370,
                    useCooldownViewer = false,
                }
            }
        }
    }

    local options = OptionsPrivate.GetBuffTriggerOptions(dummyData, 1)
    Harness.Assert(options ~= nil, "Options table should be returned")

    local aura_options = options["trigger.1.aura_options"]
    Harness.Assert(aura_options ~= nil, "aura_options should exist")
    Harness.Assert(aura_options.cvHeader ~= nil, "cvHeader should be injected")
    Harness.Assert(aura_options.useCooldownViewer ~= nil, "useCooldownViewer toggle should be injected")
    Harness.Assert(aura_options.cvLinkedSpells ~= nil, "cvLinkedSpells input should be injected")
    Harness.Assert(aura_options.cvShowAllBuffs ~= nil, "cvShowAllBuffs checkbox should be injected")
    Harness.Assert(aura_options.cvPickerBuffsAndBars ~= nil, "cvPickerBuffsAndBars dropdown should be injected")
    Harness.Assert(aura_options.cvPickerCooldowns == nil, "cvPickerCooldowns should NOT be present on Buff triggers")
    Harness.Assert(aura_options.cvPickerAdd ~= nil, "cvPickerAdd button should be injected")
    Harness.Assert(aura_options.cvPickerRefresh ~= nil, "cvPickerRefresh button should be injected")
end)

Harness.RunTest("2. Injected controls hidden property respects unit == player", function()
    local playerData = {
        triggers = {
            [1] = { trigger = { type = "aura2", unit = "player", useCooldownViewer = true } }
        }
    }
    local targetData = {
        triggers = {
            [1] = { trigger = { type = "aura2", unit = "target", useCooldownViewer = true } }
        }
    }

    local playerOpts = OptionsPrivate.GetBuffTriggerOptions(playerData, 1)["trigger.1.aura_options"]
    local targetOpts = OptionsPrivate.GetBuffTriggerOptions(targetData, 1)["trigger.1.aura_options"]

    Harness.AssertEquals(playerOpts.useCooldownViewer.hidden(), false, "Player unit should NOT hide toggle")
    Harness.AssertEquals(targetOpts.useCooldownViewer.hidden(), true, "Target unit SHOULD hide toggle")
    Harness.AssertEquals(playerOpts.cvShowAllBuffs.hidden(), false, "Player unit should NOT hide show all buffs checkbox")
    Harness.AssertEquals(targetOpts.cvShowAllBuffs.hidden(), true, "Target unit SHOULD hide show all buffs checkbox")
    Harness.AssertEquals(playerOpts.cvPickerBuffsAndBars.hidden(), false, "Player unit should NOT hide Buffs/Bars picker")
    Harness.AssertEquals(targetOpts.cvPickerBuffsAndBars.hidden(), true, "Target unit SHOULD hide Buffs/Bars picker")
end)

Harness.RunTest("3. Injected setter updates trigger and linked spells", function()
    local data = {
        id = "MyConsecrationWA",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    spellId = 188370,
                }
            }
        }
    }

    local opts = OptionsPrivate.GetBuffTriggerOptions(data, 1)["trigger.1.aura_options"]

    -- Toggle useCooldownViewer
    opts.useCooldownViewer.set({}, true)
    Harness.AssertEquals(data.triggers[1].trigger.useCooldownViewer, true, "useCooldownViewer should be true")

    -- Set linked spell IDs manually
    opts.cvLinkedSpells.set({}, "188370, 26573")
    local linked = data.triggers[1].trigger.cvLinkedSpells
    Harness.Assert(type(linked) == "table", "cvLinkedSpells should be table")
    Harness.AssertEquals(linked[1], 188370, "First linked spell should be 188370")
    Harness.AssertEquals(linked[2], 26573, "Second linked spell should be 26573")
end)

Harness.RunTest("4. Add Selected Buff button adds chosen tracked buff into linked spell IDs", function()
    local data = {
        id = "TestAddSelectedAura",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    useCooldownViewer = true,
                    cvLinkedSpells = {},
                }
            }
        }
    }

    local opts = OptionsPrivate.GetBuffTriggerOptions(data, 1)["trigger.1.aura_options"]

    -- Select a tracked buff from the dropdown
    opts.cvPickerBuffsAndBars.set({}, "188370")
    Harness.AssertEquals(data.triggers[1].trigger._cvPickBuffOrBar, "188370", "Selection stored")

    -- Click Add Selected Buff
    opts.cvPickerAdd.func()
    local linked = data.triggers[1].trigger.cvLinkedSpells
    Harness.Assert(type(linked) == "table", "cvLinkedSpells should be table")
    Harness.AssertEquals(linked[1], 188370, "Linked spells should now contain 188370")
    Harness.AssertEquals(data.triggers[1].trigger._cvPickBuffOrBar, "0", "Selection should reset to 0")
end)

Harness.RunTest("5. SyncAuraState pushes rich Cooldown Viewer state (stacks, duration, remaining, charges) into trigger state", function()
    local auraId = "TestAura1"
    local triggernum = 1

    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1012.0,
        cooldownDuration = 12.0,
        Applications = { Applications = 5 },
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    M33K.Injection.SyncAuraState(auraId, triggernum, { [188370] = true, [26573] = true })

    local state = ThisWeeksAuras.GetTriggerStateForTrigger(auraId, triggernum)[""]
    Harness.Assert(state ~= nil, "State should be populated")
    Harness.AssertEquals(state.show, true, "State show should be true")
    Harness.AssertEquals(state.expirationTime, 1012.0, "State expirationTime should be 1012.0")
    Harness.AssertEquals(state.duration, 12.0, "State duration should be 12.0")
    Harness.AssertEquals(state.total, 12.0, "State total should be 12.0")
    Harness.AssertEquals(state.stacks, 5, "State stacks should be 5")
    Harness.AssertEquals(state.applications, 5, "State applications should be 5")
    Harness.AssertEquals(state.charges, 5, "State charges should be 5")
    Harness.AssertEquals(state.spellId, 26573, "State spellId should be 26573")

    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("6. Injection hooks M33kAuras.RegisterTriggerSystemOptions directly with only tracked buffs", function()
    _G.M33kAuras._registeredOptions = {}

    local M33K = {}
    Harness.LoadFullAddon(M33K)
    M33K.Injection.Initialize()

    local mockOptionsGenerator = function(data, triggernum)
        return {
            ["trigger." .. triggernum .. ".aura_options"] = {
                existingOpt = { type = "toggle", name = "Existing" },
            }
        }
    end

    _G.M33kAuras.RegisterTriggerSystemOptions({ "aura2" }, mockOptionsGenerator)

    Harness.Assert(#_G.M33kAuras._registeredOptions > 0, "Options should be registered in M33kAuras")

    local regWrapper = _G.M33kAuras._registeredOptions[1].fn
    local dummyData = {
        id = "M33kTestAura",
        triggers = {
            [1] = {
                trigger = { type = "aura2", unit = "player" }
            }
        }
    }
    local result = regWrapper(dummyData, 1)
    local aura_opts = result["trigger.1.aura_options"]

    Harness.Assert(aura_opts.cvHeader ~= nil, "M33kAuras: cvHeader should be injected")
    Harness.Assert(aura_opts.useCooldownViewer ~= nil, "M33kAuras: useCooldownViewer should be injected")
    Harness.Assert(aura_opts.cvPickerBuffsAndBars ~= nil, "M33kAuras: cvPickerBuffsAndBars should be injected")
    Harness.Assert(aura_opts.cvPickerCooldowns == nil, "M33kAuras: cvPickerCooldowns should NOT be injected into Buff trigger")
end)

Harness.RunTest("7. SyncAuraState pushes state into M33kAuras environment when ThisWeeksAuras is absent", function()
    local savedTWA = _G.ThisWeeksAuras
    _G.ThisWeeksAuras = nil

    local auraId = "SoloM33kAura"
    local triggernum = 1

    local mockIcon = {
        spellID = 188370,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1020.0,
        cooldownDuration = 20.0,
        ChargeCount = { Current = 1 },
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    M33K.Injection.SyncAuraState(auraId, triggernum, { [188370] = true })

    local state = _G.M33kAuras.GetTriggerStateForTrigger(auraId, triggernum)[""]
    Harness.Assert(state ~= nil, "State should be populated in M33kAuras")
    Harness.AssertEquals(state.show, true, "State show should be true in M33kAuras")
    Harness.AssertEquals(state.expirationTime, 1020.0, "Expiration time matches in M33kAuras")
    Harness.AssertEquals(state.charges, 1, "Charges count matches in M33kAuras")
    Harness.AssertEquals(state.spellId, 188370, "Spell ID matches in M33kAuras")

    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    _G.ThisWeeksAuras = savedTWA
end)

Harness.RunTest("8. Show Untracked Buffs checkbox alters dropdown values between active-only and all-buffs", function()
    -- Category 3 (TrackedBuff) has 1 tracked spell and 1 untracked spell (via includeAll)
    _G.C_CooldownViewer._categorySets[3] = { 1001 } -- tracked set
    _G.C_CooldownViewer._cooldowns[1001] = { spellID = 1001, name = "ActiveBuff" }
    _G.C_CooldownViewer._cooldowns[1002] = { spellID = 1002, name = "UntrackedBuff" }

    -- Mock GetCooldownViewerCategorySet to return {1001} for false, and {1001, 1002} for true
    local orig_GetCat = _G.C_CooldownViewer.GetCooldownViewerCategorySet
    _G.C_CooldownViewer.GetCooldownViewerCategorySet = function(cat, includeAll)
        if cat == 3 then
            return includeAll and { 1001, 1002 } or { 1001 }
        end
        return {}
    end

    local data = {
        id = "TestToggleAura",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    useCooldownViewer = true,
                    cvShowAllBuffs = false,
                }
            }
        }
    }

    local opts = OptionsPrivate.GetBuffTriggerOptions(data, 1)["trigger.1.aura_options"]

    -- With cvShowAllBuffs = false (default)
    local valsTrackedOnly = opts.cvPickerBuffsAndBars.values()
    Harness.Assert(valsTrackedOnly["1001"] ~= nil, "Active buff 1001 should be present")
    Harness.Assert(valsTrackedOnly["1002"] == nil, "Untracked buff 1002 should NOT be present when checkbox is off")

    -- Toggle cvShowAllBuffs to true
    opts.cvShowAllBuffs.set({}, true)
    Harness.AssertEquals(data.triggers[1].trigger.cvShowAllBuffs, true, "cvShowAllBuffs should be true")

    local valsAll = opts.cvPickerBuffsAndBars.values()
    Harness.Assert(valsAll["1001"] ~= nil, "Active buff 1001 should be present")
    Harness.Assert(valsAll["1002"] ~= nil, "Untracked buff 1002 SHOULD be present when checkbox is on")

    -- Clean up & restore
    _G.C_CooldownViewer.GetCooldownViewerCategorySet = orig_GetCat
    _G.C_CooldownViewer._categorySets[3] = {}
    _G.C_CooldownViewer._cooldowns[1001] = nil
    _G.C_CooldownViewer._cooldowns[1002] = nil
end)

Harness.RunTest("9. Injection wraps SpellTrigger options and injects Cooldown Manager picker", function()
    local dummyData = {
        id = "TestSpellTriggerAura",
        triggers = {
            [1] = {
                trigger = {
                    type = "spell",
                    spellName = 31884,
                    useCooldownViewer = true,
                }
            }
        }
    }

    local options = OptionsPrivate.GetSpellTriggerOptions(dummyData, 1)
    Harness.Assert(options ~= nil, "Options table should be returned")

    local spell_options = options["trigger.1.spell_options"]
    Harness.Assert(spell_options ~= nil, "spell_options should exist")
    Harness.Assert(spell_options.cvHeader ~= nil, "cvHeader should be injected")
    Harness.Assert(spell_options.useCooldownViewer ~= nil, "useCooldownViewer should be injected")
    Harness.Assert(spell_options.cvShowAllCooldowns ~= nil, "cvShowAllCooldowns should be injected")
    Harness.Assert(spell_options.cvPickerCooldowns ~= nil, "cvPickerCooldowns should be injected")
    Harness.Assert(spell_options.cvPickerAdd ~= nil, "cvPickerAdd should be injected")
end)

Harness.RunTest("10. Spell trigger Add Selected Cooldown sets trigger.spellName and linkedSpells", function()
    local data = {
        id = "TestSpellSelectAura",
        triggers = {
            [1] = {
                trigger = {
                    type = "spell",
                    useCooldownViewer = true,
                }
            }
        }
    }

    local opts = OptionsPrivate.GetSpellTriggerOptions(data, 1)["trigger.1.spell_options"]
    opts.cvPickerCooldowns.set({}, "31884")
    opts.cvPickerAdd.func()

    Harness.AssertEquals(data.triggers[1].trigger.spellName, 31884, "spellName should be set to 31884")
    Harness.AssertEquals(data.triggers[1].trigger.spellId, 31884, "spellId should be set to 31884")
    Harness.AssertEquals(data.triggers[1].trigger.cvLinkedSpells[1], 31884, "Linked spells should include 31884")
end)

Harness.RunTest("11. SyncSpellState pushes usable, charges, duration, and cooldown state to trigger state", function()
    local auraId = "TestSpellAura"
    local triggernum = 1

    Harness.SetTime(1000.0)
    _G.C_Spell._cooldowns[31884] = { startTime = 0, duration = 0, isEnabled = true }
    _G.C_Spell._charges[31884] = { currentCharges = 2, maxCharges = 2 }

    M33K.Injection.SyncSpellState(auraId, triggernum, { [31884] = true }, false)

    local state = ThisWeeksAuras.GetTriggerStateForTrigger(auraId, triggernum)[""]
    Harness.Assert(state ~= nil, "State should be populated")
    Harness.AssertEquals(state.show, true, "Spell should be usable (show=true)")
    Harness.AssertEquals(state.usable, true, "usable flag should be true")
    Harness.AssertEquals(state.charges, 2, "charges should be 2")
    Harness.AssertEquals(state.maxCharges, 2, "maxCharges should be 2")
    Harness.AssertEquals(state.spellId, 31884, "spellId should match")

    _G.C_Spell._cooldowns[31884] = nil
    _G.C_Spell._charges[31884] = nil
end)

Harness.RunTest("12. Generic non-spell triggers (Health/Power/Combat Log) are not corrupted and flatten properly", function()
    -- Mock a generic trigger (e.g. Health trigger with type="status", event="Health")
    local mockGenericOptionsFunc = function(data, triggernum)
        return {
            ["trigger." .. triggernum .. ".Health"] = {
                __title = "Health",
                __order = 10,
                healthValue = { type = "input", name = "Health Value", order = 1 },
            }
        }
    end

    local wrapped = M33K.Injection.WrapSpellTriggerOptions(mockGenericOptionsFunc)

    local data = {
        triggers = {
            [1] = {
                trigger = {
                    type = "status",
                    event = "Health",
                }
            }
        }
    }

    local result = wrapped(data, 1)
    Harness.Assert(result ~= nil, "Result table should exist")
    Harness.Assert(result["trigger.1.Health"] ~= nil, "trigger.1.Health section should exist")

    -- Verify no naked keys leaked onto the root result table
    Harness.AssertEquals(result.cvHeader, nil, "cvHeader must NOT leak onto root options table")
    Harness.AssertEquals(result.useCooldownViewer, nil, "useCooldownViewer must NOT leak onto root options table")
    Harness.AssertEquals(result.cvPickerCooldowns, nil, "cvPickerCooldowns must NOT leak onto root options table")

    -- Verify simulate flattenRegionOptions
    local base = 1000
    local flattened = {}
    for groupKey, options in pairs(result) do
        Harness.Assert(options.__order ~= nil, "Every group in allOptions MUST have an __order field")
        local groupBase = base * options.__order
        for optKey, opt in pairs(options) do
            if not string.find(optKey, "^__") then
                flattened[groupKey .. "." .. optKey] = opt
            end
        end
    end

    Harness.Assert(flattened["trigger.1.Health.healthValue"] ~= nil, "Flattened options contain healthValue")
end)

