local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

local M33K = {}
Harness.LoadFullAddon(M33K)
M33K.Engine.Initialize()

Harness.BeginSuite("Blizzard Cooldown Viewer & Aura Engine Tests")

Harness.RunTest("1. IsBuffActive returns false when neither C_UnitAuras nor Cooldown Viewer matches", function()
    local TARGET_SPELLS = { [188370] = true, [26573] = true }
    local active, exp, dur = M33K.CooldownViewer.IsBuffActive(TARGET_SPELLS)
    Harness.AssertEquals(active, false, "Should not be active with empty environment")
end)

Harness.RunTest("2. Direct C_UnitAuras match returns true", function()
    -- Set active aura in C_UnitAuras
    _G.C_UnitAuras._auras[188370] = {
        duration = 12.0,
        expirationTime = 1012.0,
        icon = 135926,
    }

    local active, exp, dur = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, true, "Should return true from C_UnitAuras")
    Harness.AssertEquals(dur, 12.0, "Duration should match C_UnitAuras duration")

    -- Clean up
    _G.C_UnitAuras._auras[188370] = nil
end)

Harness.RunTest("3. Cooldown Viewer matches active icon with cooldownUseAuraDisplayTime == true", function()
    -- Add an active icon to BuffIconCooldownViewer
    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1010.0,
        cooldownDuration = 10.0,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    local active, exp, dur = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, true, "Should return true from BuffIconCooldownViewer")
    Harness.AssertEquals(dur, 10.0, "Duration should match Cooldown Viewer duration")

    -- Clean up
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("4. Cooldown Viewer ignores icon when cooldownUseAuraDisplayTime is false (regular CD)", function()
    -- Add a regular spell cooldown icon (not an active buff)
    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = false, -- NOT an aura display
        IsShown = function() return true end,
    }
    _G.EssentialCooldownViewer.itemFramePool._icons = { mockIcon }

    local active = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, false, "Should ignore icon when cooldownUseAuraDisplayTime is false")

    -- Clean up
    _G.EssentialCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("5. Cooldown Viewer matches linkedSpellIDs from cooldownInfo", function()
    local mockIcon = {
        cooldownUseAuraDisplayTime = true,
        IsShown = function() return true end,
        cooldownInfo = {
            spellID = 99999,
            linkedSpellIDs = { 188370, 44444 },
            cooldownDuration = 15.0,
            cooldownExpirationTime = 1015.0,
        },
    }
    _G.UtilityCooldownViewer.itemFramePool._icons = { mockIcon }

    local active, exp, dur = M33K.CooldownViewer.IsBuffActive({ [188370] = true })
    Harness.AssertEquals(active, true, "Should match via linkedSpellIDs table")

    -- Clean up
    _G.UtilityCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("6. Cooldown Viewer matches overrideSpellID via C_CooldownViewer fallback", function()
    -- Icon has only a cooldownID (cid)
    _G.C_CooldownViewer._cooldowns[42] = {
        spellID = 11111,
        overrideSpellID = 26573,
        cooldownDuration = 8.0,
        cooldownExpirationTime = 1008.0,
    }

    local mockIcon = {
        cooldownID = 42,
        cooldownUseAuraDisplayTime = true,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    local active, exp, dur = M33K.CooldownViewer.IsBuffActive({ [26573] = true })
    Harness.AssertEquals(active, true, "Should match via C_CooldownViewer overrideSpellID")

    -- Clean up
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    _G.C_CooldownViewer._cooldowns[42] = nil
end)

Harness.RunTest("7. Multiple target spell inputs supported (number, string, table)", function()
    _G.C_UnitAuras._auras[777] = { duration = 5.0, expirationTime = 1005.0 }

    Harness.AssertEquals(M33K.CooldownViewer.IsBuffActive(777), true, "Direct number input")
    Harness.AssertEquals(M33K.CooldownViewer.IsBuffActive("777"), true, "String number input")
    Harness.AssertEquals(M33K.CooldownViewer.IsBuffActive({ 777, 888 }), true, "Array table input")
    Harness.AssertEquals(M33K.CooldownViewer.IsBuffActive({ [777] = true }), true, "Set table input")

    _G.C_UnitAuras._auras[777] = nil
end)
