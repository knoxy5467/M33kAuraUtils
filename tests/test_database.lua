local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Load modules
local GAT = {}
local AddonName = "GroundAuraTracker"

dofile("Locales/Locales.lua")
dofile("Spells.lua")
dofile("Database.lua")

Harness.BeginSuite("Database & Configuration Tests")

Harness.RunTest("1. Database initializes with default values", function()
    _G.GroundAuraTrackerDB = nil
    local db = GAT.Database.Initialize()

    Harness.AssertNotNil = function(val, msg) Harness.Assert(val ~= nil, msg) end
    Harness.AssertNotNil(db, "DB should not be nil")
    Harness.AssertEquals(db.size, 50, "Default size should be 50")
    Harness.AssertEquals(db.locked, false, "Default locked state should be false")
    Harness.AssertEquals(db.colors.inside.r, 0.2, "Default inside color R should be 0.2")
end)

Harness.RunTest("2. Set and Get settings", function()
    GAT.Database.SetSetting("size", 65)
    Harness.AssertEquals(GAT.Database.GetSetting("size"), 65, "Setting 'size' should be updated to 65")

    GAT.Database.SetSetting("locked", true)
    Harness.AssertEquals(GAT.Database.GetSetting("locked"), true, "Setting 'locked' should be true")
end)

Harness.RunTest("3. Add and remove custom spells", function()
    GAT.Database.AddCustomSpell(99999, 99998, 15, "Custom Zone")
    local customSpell = GAT.Spells.GetSpellByCastId(99999, GAT.db.customSpells)

    Harness.Assert(customSpell ~= nil, "Custom spell should be found by cast ID")
    Harness.AssertEquals(customSpell.buffSpellId, 99998, "Buff spell ID should match")
    Harness.AssertEquals(customSpell.defaultDuration, 15, "Duration should match 15s")

    GAT.Database.RemoveCustomSpell(99999)
    local removed = GAT.Spells.GetSpellByCastId(99999, GAT.db.customSpells)
    Harness.Assert(removed == nil, "Custom spell should be removed")
end)

Harness.RunTest("4. Reset position restores defaults", function()
    GAT.db.posX = 500
    GAT.db.posY = 200
    GAT.Database.ResetPosition()

    Harness.AssertEquals(GAT.db.posX, 0, "Position X should reset to 0")
    Harness.AssertEquals(GAT.db.posY, -150, "Position Y should reset to -150")
end)
