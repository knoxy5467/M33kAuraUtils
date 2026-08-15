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
