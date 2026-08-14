local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Initialize fresh addon state
_G.M33kAuraUtilsDB = nil
local M33K = {}
Harness.LoadFullAddon(M33K)

Harness.BeginSuite("Database & Configuration Profile Tests")

Harness.RunTest("1. Database initializes with default values", function()
    local db = M33K.Database.Initialize()
    Harness.Assert(db ~= nil, "Database table should exist")
    Harness.AssertEquals(db.debug, false, "Default debug should be false")
    Harness.AssertEquals(db.version, "1.0.0", "Default version should be 1.0.0")
end)

Harness.RunTest("2. Set and Get settings propagate properly", function()
    M33K.Database.SetSetting("debug", true)
    Harness.AssertEquals(M33K.Database.GetSetting("debug"), true, "GetSetting debug should return true")

    M33K.Database.SetSetting("customKey", "helloWorld")
    Harness.AssertEquals(M33K.Database.GetSetting("customKey"), "helloWorld", "Custom setting should return helloWorld")
end)
