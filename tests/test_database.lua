local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Load modules
local M33K = {}
Harness.LoadFullAddon(M33K)

Harness.BeginSuite("Database & Configuration Tests")

Harness.RunTest("1. Database initializes with default values", function()
    _G.M33kAuraUtilsDB = nil
    local db = M33K.Database.Initialize()

    Harness.Assert(db ~= nil, "DB should not be nil")
    Harness.AssertEquals(db.size, 50, "Default size should be 50")
    Harness.AssertEquals(db.locked, false, "Default locked state should be false")
    Harness.AssertEquals(db.colors.inside.r, 0.2, "Default inside color R should be 0.2")
end)

Harness.RunTest("2. Set and Get settings", function()
    M33K.Database.SetSetting("size", 65)
    Harness.AssertEquals(M33K.Database.GetSetting("size"), 65, "Setting 'size' should be updated to 65")

    M33K.Database.SetSetting("locked", true)
    Harness.AssertEquals(M33K.Database.GetSetting("locked"), true, "Setting 'locked' should be true")
end)

Harness.RunTest("3. Add and remove custom spells", function()
    M33K.Database.AddCustomSpell(99999, 99998, 15, "Custom Zone")
    local customSpell = M33K.Spells.GetSpellByCastId(99999, M33K.db.customSpells)

    Harness.Assert(customSpell ~= nil, "Custom spell should be found by cast ID")
    Harness.AssertEquals(customSpell.buffSpellId, 99998, "Buff spell ID should match")
    Harness.AssertEquals(customSpell.defaultDuration, 15, "Duration should match 15s")

    M33K.Database.RemoveCustomSpell(99999)
    local removed = M33K.Spells.GetSpellByCastId(99999, M33K.db.customSpells)
    Harness.Assert(removed == nil, "Custom spell should be removed")
end)

Harness.RunTest("4. Reset position restores defaults", function()
    M33K.db.posX = 500
    M33K.db.posY = 200
    M33K.Database.ResetPosition()

    Harness.AssertEquals(M33K.db.posX, 0, "Position X should reset to 0")
    Harness.AssertEquals(M33K.db.posY, -150, "Position Y should reset to -150")
end)
