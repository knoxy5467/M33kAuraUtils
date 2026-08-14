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
    Harness.AssertEquals(tracked[188370].category, "Buff", "category should be Buff")

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

Harness.RunTest("9. EnumerateTracked with buffsOnly filters out non-buff entries", function()
    local buffIcon = {
        spellID = 188370,
        cooldownUseAuraDisplayTime = true,
        IsShown = function() return true end,
    }
    local cdIcon = {
        spellID = 12345,
        cooldownUseAuraDisplayTime = false,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { buffIcon, cdIcon }

    local tracked = M33K.CooldownViewer.EnumerateTracked("Buff", true)
    Harness.Assert(tracked[188370] ~= nil, "Buff icon should be included")
    Harness.Assert(tracked[12345] == nil, "CD icon should be excluded with buffsOnly")

    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("10. EnumerateTracked category filter restricts to single viewer", function()
    local essIcon = {
        spellID = 33333,
        cooldownUseAuraDisplayTime = false,
        IsShown = function() return true end,
    }
    local utilIcon = {
        spellID = 44444,
        cooldownUseAuraDisplayTime = false,
        IsShown = function() return true end,
    }
    _G.EssentialCooldownViewer.itemFramePool._icons = { essIcon }
    _G.UtilityCooldownViewer.itemFramePool._icons = { utilIcon }

    local essentialOnly = M33K.CooldownViewer.EnumerateTracked("Essential", false)
    Harness.Assert(essentialOnly[33333] ~= nil, "Essential spell should be included")
    Harness.Assert(essentialOnly[44444] == nil, "Utility spell should be excluded")
    Harness.AssertEquals(essentialOnly[33333].category, "Essential", "Category should be Essential")

    local utilityOnly = M33K.CooldownViewer.EnumerateTracked("Utility", false)
    Harness.Assert(utilityOnly[44444] ~= nil, "Utility spell should be included")
    Harness.Assert(utilityOnly[33333] == nil, "Essential spell should be excluded")
    Harness.AssertEquals(utilityOnly[44444].category, "Utility", "Category should be Utility")

    _G.EssentialCooldownViewer.itemFramePool._icons = {}
    _G.UtilityCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("11. EnumerateFromCDM queries data layer via GetCooldownViewerCategorySet", function()
    -- Populate CDM data layer with Essential cooldowns
    _G.C_CooldownViewer._categorySets[1] = { 101, 102 }  -- Essential category
    _G.C_CooldownViewer._cooldowns[101] = {
        spellID = 77777,
        overrideSpellID = 88888,
        linkedSpellIDs = { 99999 },
    }
    _G.C_CooldownViewer._cooldowns[102] = {
        spellID = 66666,
    }

    local essential = M33K.CooldownViewer.EnumerateFromCDM("Essential")
    Harness.Assert(essential[77777] ~= nil, "Should find spell 77777 from CDM Essential")
    Harness.AssertEquals(essential[77777].category, "Essential", "Category should be Essential")

    -- Verify linked IDs collected
    local linked = essential[77777].linkedSpellIDs
    Harness.Assert(type(linked) == "table", "linkedSpellIDs should be a table")
    local found88888 = false
    local found99999 = false
    for _, id in ipairs(linked) do
        if id == 88888 then found88888 = true end
        if id == 99999 then found99999 = true end
    end
    Harness.Assert(found88888, "Should include overrideSpellID 88888")
    Harness.Assert(found99999, "Should include linkedSpellID 99999")

    Harness.Assert(essential[66666] ~= nil, "Should find spell 66666 from CDM Essential")

    -- Clean up
    _G.C_CooldownViewer._categorySets[1] = {}
    _G.C_CooldownViewer._cooldowns[101] = nil
    _G.C_CooldownViewer._cooldowns[102] = nil
end)

Harness.RunTest("12. EnumerateFromCDM returns empty for Buff category (not supported by CDM)", function()
    local buffs = M33K.CooldownViewer.EnumerateFromCDM("Buff")
    local count = 0
    for _ in pairs(buffs) do count = count + 1 end
    Harness.AssertEquals(count, 0, "CDM does not have a Buff category, should return empty")
end)

Harness.RunTest("13. EnumerateAll merges viewer frames and CDM data layer", function()
    -- Buff from viewer
    local buffIcon = {
        spellID = 188370,
        cooldownUseAuraDisplayTime = true,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { buffIcon }

    -- Essential from CDM data layer
    _G.C_CooldownViewer._categorySets[1] = { 201 }
    _G.C_CooldownViewer._cooldowns[201] = { spellID = 55555 }

    local all = M33K.CooldownViewer.EnumerateAll()
    Harness.Assert(all[188370] ~= nil, "Buff from viewer should be in EnumerateAll")
    Harness.Assert(all[55555] ~= nil, "Essential from CDM should be in EnumerateAll")

    -- Clean up
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    _G.C_CooldownViewer._categorySets[1] = {}
    _G.C_CooldownViewer._cooldowns[201] = nil
end)

Harness.RunTest("14. EnumerateTracked returns empty when viewers have no entries", function()
    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    _G.EssentialCooldownViewer.itemFramePool._icons = {}
    _G.UtilityCooldownViewer.itemFramePool._icons = {}

    local tracked = M33K.CooldownViewer.EnumerateTracked()
    local count = 0
    for _ in pairs(tracked) do count = count + 1 end
    Harness.AssertEquals(count, 0, "Should return empty table when no active viewer entries")
end)
