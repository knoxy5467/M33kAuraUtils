local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

local M33K = {}
Harness.LoadFullAddon(M33K)
M33K.Injection.Initialize()

Harness.BeginSuite("Cross-Addon Injection & Cooldown Viewer Integration Tests")

Harness.RunTest("1. Injection wraps BuffTrigger options generator and injects Cooldown Viewer controls", function()
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

    -- Set linked spell IDs
    opts.cvLinkedSpells.set({}, "188370, 26573")
    local linked = data.triggers[1].trigger.cvLinkedSpells
    Harness.Assert(type(linked) == "table", "cvLinkedSpells should be table")
    Harness.AssertEquals(linked[1], 188370, "First linked spell should be 188370")
    Harness.AssertEquals(linked[2], 26573, "Second linked spell should be 26573")
end)

Harness.RunTest("4. SyncAuraState pushes Cooldown Viewer state into ThisWeeksAuras trigger state", function()
    local auraId = "TestAura1"
    local triggernum = 1

    -- Setup active icon in BuffIconCooldownViewer
    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1012.0,
        cooldownDuration = 12.0,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    M33K.Injection.SyncAuraState(auraId, triggernum, { [188370] = true, [26573] = true })

    local state = ThisWeeksAuras.GetTriggerStateForTrigger(auraId, triggernum)[""]
    Harness.Assert(state ~= nil, "State should be populated")
    Harness.AssertEquals(state.show, true, "State show should be true")
    Harness.AssertEquals(state.expirationTime, 1012.0, "State expirationTime should be 1012.0")
    Harness.AssertEquals(state.duration, 12.0, "State duration should be 12.0")

    -- Clean up
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)
