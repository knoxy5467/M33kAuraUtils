local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Initialize Addon State
local GAT = {}
Harness.LoadFullAddon(GAT)

Harness.BeginSuite("Dual-State Tracking Engine Tests")

Harness.RunTest("1. Engine Initial State is EXPIRED", function()
    Harness.SetTime(1000.0)
    Harness.ClearPlayerAuras()
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_EXPIRED, "Initial state should be EXPIRED")
    Harness.AssertEquals(remaining, 0, "Remaining time should be 0")
end)

Harness.RunTest("2. Cast Consecration transitions to ACTIVE_INSIDE", function()
    Harness.SetTime(1000.0)
    Harness.ClearPlayerAuras()
    Harness.ApplyPlayerAura(188370, "Consecration") -- Buff active
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")

    -- Simulate SPELL_CAST_SUCCESS for Consecration (26573)
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_ACTIVE_INSIDE, "State should be ACTIVE_INSIDE")
    Harness.AssertEquals(remaining, 12, "Remaining duration should be 12s")
    Harness.AssertEquals(spell.name, "Consecration", "Active spell should be Consecration")
end)

Harness.RunTest("3. Stepping out of Consecration transitions to ACTIVE_OUTSIDE", function()
    Harness.SetTime(1000.0)
    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    -- Advance time 3 seconds and drop buff
    Harness.AdvanceTime(3.0)
    Harness.RemovePlayerAura(188370)
    GAT.Engine.OnUnitAura("player")

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_ACTIVE_OUTSIDE, "State should transition to ACTIVE_OUTSIDE")
    Harness.AssertEquals(remaining, 9, "Remaining time should be 9s")
end)

Harness.RunTest("4. Stepping back into Consecration transitions back to ACTIVE_INSIDE", function()
    Harness.SetTime(1000.0)
    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    -- Step out at +3s
    Harness.AdvanceTime(3.0)
    Harness.RemovePlayerAura(188370)
    GAT.Engine.OnUnitAura("player")

    -- Step back in at +5s
    Harness.AdvanceTime(2.0)
    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.OnUnitAura("player")

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_ACTIVE_INSIDE, "State should return to ACTIVE_INSIDE")
    Harness.AssertEquals(remaining, 7, "Remaining time should be 7s")
end)

Harness.RunTest("5. Consecration Expiration when timer finishes", function()
    Harness.SetTime(1000.0)
    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    -- Advance past 12s
    Harness.AdvanceTime(12.5)
    Harness.RemovePlayerAura(188370)
    GAT.Engine.OnUnitAura("player")

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_EXPIRED, "State should be EXPIRED")
    Harness.AssertEquals(remaining, 0, "Remaining time should be 0")
end)

Harness.RunTest("6. Premature recast resets ground duration", function()
    Harness.SetTime(1000.0)
    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    -- Recast at +8s
    Harness.AdvanceTime(8.0)
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_ACTIVE_INSIDE, "State should remain ACTIVE_INSIDE")
    Harness.AssertEquals(remaining, 12, "Remaining time should reset to full 12s")
end)

Harness.RunTest("7. Death Knight Death & Decay (43265) Support", function()
    Harness.SetTime(2000.0)
    Harness.ClearPlayerAuras()
    Harness.ApplyPlayerAura(188290, "Death and Decay")
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")

    GAT.Engine.OnSpellCastSuccess("Player-1234", 43265)

    local state, remaining, duration, spell = GAT.Engine.GetActiveState()
    Harness.AssertEquals(state, GAT.Engine.STATE_ACTIVE_INSIDE, "D&D should be ACTIVE_INSIDE")
    Harness.AssertEquals(remaining, 10, "D&D duration should be 10s")
    Harness.AssertEquals(spell.name, "Death and Decay", "Active spell is Death and Decay")
end)

Harness.RunTest("8. Callbacks trigger on state change", function()
    Harness.SetTime(3000.0)
    Harness.ClearPlayerAuras()
    GAT.Engine.Initialize()
    GAT.Engine._SetPlayerGUID("Player-1234")

    local callbackReceived = false
    local receivedState = nil
    GAT.Engine.RegisterCallback("TestListener", function(state, remaining, duration, spell)
        callbackReceived = true
        receivedState = state
    end)

    Harness.ApplyPlayerAura(188370, "Consecration")
    GAT.Engine.OnSpellCastSuccess("Player-1234", 26573)

    Harness.Assert(callbackReceived, "Callback should have been invoked")
    Harness.AssertEquals(receivedState, GAT.Engine.STATE_ACTIVE_INSIDE, "Callback received state ACTIVE_INSIDE")
end)
