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

Harness.RunTest("2. Direct C_UnitAuras match returns true with stacks, duration, name, and ID", function()
    _G.C_UnitAuras._auras[188370] = {
        name = "Consecration",
        duration = 12.0,
        expirationTime = 1012.0,
        icon = 135926,
        applications = 3,
    }

    local active, exp, dur, icon, stacks, matchedID, name = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, true, "Should return true from C_UnitAuras")
    Harness.AssertEquals(dur, 12.0, "Duration should match C_UnitAuras duration")
    Harness.AssertEquals(exp, 1012.0, "Expiration time should match")
    Harness.AssertEquals(icon, 135926, "Icon should match")
    Harness.AssertEquals(stacks, 3, "Stacks should be 3")
    Harness.AssertEquals(matchedID, 188370, "Matched ID should be 188370")
    Harness.AssertEquals(name, "Consecration", "Name should be Consecration")

    _G.C_UnitAuras._auras[188370] = nil
end)

Harness.RunTest("3. Cooldown Viewer matches active icon with cooldownUseAuraDisplayTime == true and extracts stacks", function()
    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1010.0,
        cooldownDuration = 10.0,
        Applications = { Applications = 2 },
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }

    local active, exp, dur, icon, stacks, matchedID, name = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, true, "Should return true from BuffIconCooldownViewer")
    Harness.AssertEquals(dur, 10.0, "Duration should match Cooldown Viewer duration")
    Harness.AssertEquals(stacks, 2, "Stacks from Applications subframe should be 2")
    Harness.AssertEquals(matchedID, 26573, "Matched ID should be 26573")

    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
end)

Harness.RunTest("4. Cooldown Viewer ignores icon when cooldownUseAuraDisplayTime is false (regular CD)", function()
    local mockIcon = {
        spellID = 26573,
        cooldownUseAuraDisplayTime = false,
        IsShown = function() return true end,
    }
    _G.EssentialCooldownViewer.itemFramePool._icons = { mockIcon }

    local active = M33K.CooldownViewer.IsBuffActive({ [188370] = true, [26573] = true })
    Harness.AssertEquals(active, false, "Should ignore icon when cooldownUseAuraDisplayTime is false")

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
            charges = 4,
        },
    }
    _G.UtilityCooldownViewer.itemFramePool._icons = { mockIcon }

    local active, exp, dur, icon, stacks, matchedID = M33K.CooldownViewer.IsBuffActive({ [188370] = true })
    Harness.AssertEquals(active, true, "Should match via linkedSpellIDs table")
    Harness.AssertEquals(matchedID, 188370, "Matched ID should be 188370")
    Harness.AssertEquals(stacks, 4, "Stacks from cooldownInfo.charges should be 4")

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

Harness.RunTest("8. EnumerateFromCDM queries CDM TrackedBuff and TrackedBar categories", function()
    _G.C_CooldownViewer._categorySets[3] = { 301 }  -- TrackedBuff
    _G.C_CooldownViewer._categorySets[4] = { 401 }  -- TrackedBar
    _G.C_CooldownViewer._cooldowns[301] = {
        spellID = 188370,
        cooldownDuration = 12.0,
        applications = 1,
    }
    _G.C_CooldownViewer._cooldowns[401] = {
        spellID = 53385,
        cooldownDuration = 6.0,
    }

    local buffs = M33K.CooldownViewer.EnumerateFromCDM("TrackedBuff")
    Harness.Assert(buffs[188370] ~= nil, "TrackedBuff 188370 should be found")
    Harness.AssertEquals(buffs[188370].category, "TrackedBuff", "Category should be TrackedBuff")
    Harness.AssertEquals(buffs[188370].isBuffTimer, true, "Should be tagged as buff timer")

    local bars = M33K.CooldownViewer.EnumerateFromCDM("TrackedBar")
    Harness.Assert(bars[53385] ~= nil, "TrackedBar 53385 should be found")
    Harness.AssertEquals(bars[53385].category, "TrackedBar", "Category should be TrackedBar")

    -- Clean up
    _G.C_CooldownViewer._categorySets[3] = {}
    _G.C_CooldownViewer._categorySets[4] = {}
    _G.C_CooldownViewer._cooldowns[301] = nil
    _G.C_CooldownViewer._cooldowns[401] = nil
end)

Harness.RunTest("9. EnumerateTrackedBuffsAndBars combines TrackedBuff and TrackedBar entries", function()
    _G.C_CooldownViewer._categorySets[3] = { 301 }
    _G.C_CooldownViewer._categorySets[4] = { 401 }
    _G.C_CooldownViewer._cooldowns[301] = { spellID = 188370 }
    _G.C_CooldownViewer._cooldowns[401] = { spellID = 53385 }

    local combined = M33K.CooldownViewer.EnumerateTrackedBuffsAndBars()
    Harness.Assert(combined[188370] ~= nil, "Should include 188370")
    Harness.Assert(combined[53385] ~= nil, "Should include 53385")

    _G.C_CooldownViewer._categorySets[3] = {}
    _G.C_CooldownViewer._categorySets[4] = {}
    _G.C_CooldownViewer._cooldowns[301] = nil
    _G.C_CooldownViewer._cooldowns[401] = nil
end)

Harness.RunTest("10. EnumerateCooldowns merges Essential and Utility categories into single table", function()
    _G.C_CooldownViewer._categorySets[1] = { 101 }  -- Essential
    _G.C_CooldownViewer._categorySets[2] = { 201 }  -- Utility
    _G.C_CooldownViewer._cooldowns[101] = { spellID = 31884 }  -- Avenging Wrath
    _G.C_CooldownViewer._cooldowns[201] = { spellID = 633 }    -- Lay on Hands

    local cds = M33K.CooldownViewer.EnumerateCooldowns()
    Harness.Assert(cds[31884] ~= nil, "Essential cooldown 31884 should be in merged table")
    Harness.Assert(cds[633] ~= nil, "Utility cooldown 633 should be in merged table")
    Harness.AssertEquals(cds[31884].category, "Essential", "31884 should retain Essential category")
    Harness.AssertEquals(cds[633].category, "Utility", "633 should retain Utility category")

    _G.C_CooldownViewer._categorySets[1] = {}
    _G.C_CooldownViewer._categorySets[2] = {}
    _G.C_CooldownViewer._cooldowns[101] = nil
    _G.C_CooldownViewer._cooldowns[201] = nil
end)

Harness.RunTest("11. GetCDMSpellInfo retrieves charges and cooldown details", function()
    _G.C_Spell._charges[26573] = {
        currentCharges = 2,
        maxCharges = 2,
        cooldownStartTime = 1000.0,
        cooldownDuration = 8.0,
    }
    _G.C_Spell._cooldowns[26573] = {
        startTime = 1000.0,
        duration = 8.0,
        isEnabled = true,
        modRate = 1.0,
    }

    local info = M33K.CooldownViewer.GetCDMSpellInfo(26573)
    Harness.Assert(info ~= nil, "Info should not be nil")
    Harness.AssertEquals(info.charges, 2, "Charges should be 2")
    Harness.AssertEquals(info.maxCharges, 2, "Max charges should be 2")
    Harness.AssertEquals(info.cdDuration, 8.0, "Cooldown duration should be 8.0")

    _G.C_Spell._charges[26573] = nil
    _G.C_Spell._cooldowns[26573] = nil
end)

Harness.RunTest("12. EnumerateAll provides complete union across all 4 CDM categories", function()
    _G.C_CooldownViewer._categorySets[1] = { 101 }
    _G.C_CooldownViewer._categorySets[2] = { 201 }
    _G.C_CooldownViewer._categorySets[3] = { 301 }
    _G.C_CooldownViewer._categorySets[4] = { 401 }
    _G.C_CooldownViewer._cooldowns[101] = { spellID = 111 }
    _G.C_CooldownViewer._cooldowns[201] = { spellID = 222 }
    _G.C_CooldownViewer._cooldowns[301] = { spellID = 333 }
    _G.C_CooldownViewer._cooldowns[401] = { spellID = 444 }

    local all = M33K.CooldownViewer.EnumerateAll()
    Harness.Assert(all[111] ~= nil, "Category 1 present")
    Harness.Assert(all[222] ~= nil, "Category 2 present")
    Harness.Assert(all[333] ~= nil, "Category 3 present")
    Harness.Assert(all[444] ~= nil, "Category 4 present")

    _G.C_CooldownViewer._categorySets[1] = {}
    _G.C_CooldownViewer._categorySets[2] = {}
    _G.C_CooldownViewer._categorySets[3] = {}
    _G.C_CooldownViewer._categorySets[4] = {}
end)
