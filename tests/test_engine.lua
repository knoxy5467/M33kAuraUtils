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

Harness.RunTest("8. EnumerateTracked returns all active viewer entries", function()
    local buffIcon = {
        spellID = 188370,
        cooldownUseAuraDisplayTime = true,
        IsShown = function() return true end,
        cooldownInfo = {
            spellID = 188370,
            linkedSpellIDs = { 26573 },
            overrideSpellID = 55555,
        },
    }
    local cdIcon = {
        spellID = 12345,
        cooldownUseAuraDisplayTime = false,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { buffIcon, cdIcon }

    local tracked = M33K.CooldownViewer.EnumerateTracked()

    Harness.Assert(tracked[188370] ~= nil, "Should enumerate buff icon spell 188370")
    Harness.AssertEquals(tracked[188370].isBuffTimer, true, "188370 should be tagged as buff timer")
    Harness.AssertEquals(tracked[188370].viewerName, "BuffIconCooldownViewer", "viewerName should match")

    -- linkedSpellIDs collected
    local linked = tracked[188370].linkedSpellIDs
    Harness.Assert(type(linked) == "table", "linkedSpellIDs should be a table")
    local found26573 = false
    local found55555 = false
    for _, id in ipairs(linked) do
        if id == 26573 then found26573 = true end
        if id == 55555 then found55555 = true end
    end
    Harness.Assert(found26573, "linkedSpellIDs should contain 26573")
    Harness.Assert(found55555, "linkedSpellIDs should contain overrideSpellID 55555")

    -- CD icon should also be enumerated but tagged as non-buff
    Harness.Assert(tracked[12345] ~= nil, "Should enumerate CD icon spell 12345")
    Harness.AssertEquals(tracked[12345].isBuffTimer, false, "12345 should NOT be tagged as buff timer")

    -- Clean up
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("9. EnumerateTracked returns empty table when viewers have no entries", function()
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    _G.EssentialCooldownViewer.itemFramePool._icons = {}
    _G.UtilityCooldownViewer.itemFramePool._icons = {}

    local tracked = M33K.CooldownViewer.EnumerateTracked()
    local count = 0
    for _ in pairs(tracked) do count = count + 1 end
    Harness.AssertEquals(count, 0, "Should return empty table when no active viewer entries")
end)
