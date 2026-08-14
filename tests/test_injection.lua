local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Setup mock ThisWeeksAuras environment
local mockTWA, mockPrivate = Harness.SetupMockThisWeeksAuras()

-- Load full addon + Injection module
local M33K = {}
Harness.LoadFullAddon(M33K)
Harness.LoadAddonFile("Injection.lua", M33K)
M33K.Database.Initialize()
M33K.Engine.Initialize()
M33K.Injection.Initialize()

Harness.BeginSuite("Cross-Addon Injection & ThisWeeksAuras Hook Tests")

Harness.RunTest("1. Injection wraps BuffTrigger options generator and injects controls", function()
    local dummyData = {
        id = "ConsecrateAura_Test",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    useGroundTracking = false,
                    groundDuration = 12,
                }
            }
        }
    }

    local wrappedOptions = OptionsPrivate.GetBuffTriggerOptions(dummyData, 1)
    Harness.Assert(wrappedOptions ~= nil, "Wrapped options table should not be nil")

    local aura_options = wrappedOptions["trigger.1.aura_options"]
    Harness.Assert(aura_options ~= nil, "trigger.1.aura_options should exist")

    -- Verify injected fields
    Harness.Assert(aura_options.groundTrackingHeader ~= nil, "groundTrackingHeader should be injected")
    Harness.Assert(aura_options.useGroundTracking ~= nil, "useGroundTracking toggle should be injected")
    Harness.Assert(aura_options.groundDuration ~= nil, "groundDuration input should be injected")
end)

Harness.RunTest("2. Injected controls hidden property respects unit == player", function()
    local dataPlayer = {
        id = "AuraPlayer",
        triggers = { [1] = { trigger = { type = "aura2", unit = "player" } } }
    }
    local dataTarget = {
        id = "AuraTarget",
        triggers = { [1] = { trigger = { type = "aura2", unit = "target" } } }
    }

    local optPlayer = OptionsPrivate.GetBuffTriggerOptions(dataPlayer, 1)["trigger.1.aura_options"]
    local optTarget = OptionsPrivate.GetBuffTriggerOptions(dataTarget, 1)["trigger.1.aura_options"]

    -- Hidden function should return false for player (visible) and true for target (hidden)
    Harness.AssertEquals(optPlayer.useGroundTracking.hidden(), false, "Should be visible for unit = player")
    Harness.AssertEquals(optTarget.useGroundTracking.hidden(), true, "Should be hidden for unit = target")
end)

Harness.RunTest("3. Injected setter updates aura data and triggers ThisWeeksAuras.Add", function()
    local dummyData = {
        id = "ConsecrateAura_Test",
        triggers = {
            [1] = {
                trigger = {
                    type = "aura2",
                    unit = "player",
                    useGroundTracking = false,
                    groundDuration = 12,
                }
            }
        }
    }

    local opt = OptionsPrivate.GetBuffTriggerOptions(dummyData, 1)["trigger.1.aura_options"]

    -- Call setter for useGroundTracking
    opt.useGroundTracking.set({}, true)
    Harness.AssertEquals(dummyData.triggers[1].trigger.useGroundTracking, true, "trigger.useGroundTracking should become true")
    Harness.Assert(mockTWA.GetData("ConsecrateAura_Test") ~= nil, "ThisWeeksAuras.Add should have recorded the aura")
    Harness.AssertEquals(mockTWA.optionsUpdatedId, "ConsecrateAura_Test", "ClearAndUpdateOptions should have been called")

    -- Call setter for groundDuration
    opt.groundDuration.set({}, 15)
    Harness.AssertEquals(dummyData.triggers[1].trigger.groundDuration, 15, "trigger.groundDuration should become 15")
end)

Harness.RunTest("4. SyncAuraState pushes dual-state into ThisWeeksAuras trigger state", function()
    Harness.SetTime(1000.0)
    M33K.Engine._SetExpiration(1010.0, 12.0, { name = "Consecration", icon = 135926 })
    M33K.Engine._SetStandingInside(true)

    M33K.Injection.RegisterHookedAura("ConsecrateAura_Test", 1, 26573, 12)
    M33K.Injection.SyncAuraState("ConsecrateAura_Test", 1, 26573, 12)

    local states = mockTWA.GetTriggerStateForTrigger("ConsecrateAura_Test", 1)
    Harness.Assert(states[""] ~= nil, "State table should have entry for ''")
    Harness.AssertEquals(states[""].show, true, "State show should be true")
    Harness.AssertEquals(states[""].inside, true, "State inside should be true")
    Harness.AssertEquals(states[""].duration, 12, "State duration should be 12")
    Harness.Assert(mockTWA.updatedAuras["ConsecrateAura_Test"] == true, "UpdatedTriggerState should be called")
end)
