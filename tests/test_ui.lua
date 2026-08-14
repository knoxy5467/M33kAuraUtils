local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Initialize fresh addon state
_G.M33kAuraUtilsDB = nil
local M33K = {}
Harness.LoadFullAddon(M33K)
M33K.Database.Initialize()
M33K.Engine.Initialize()

Harness.BeginSuite("UI & Utility Frame Tests")

Harness.RunTest("1. UI.CreateMainFrame constructs utility frame properly", function()
    local frame = M33K.UI.CreateMainFrame()
    Harness.Assert(frame ~= nil, "Main frame should be created")
    local w, h = frame:GetSize()
    Harness.AssertEquals(w, 40, "Frame width should be 40")
    Harness.AssertEquals(h, 40, "Frame height should be 40")
end)

Harness.RunTest("2. Slash commands report status and toggle debug mode", function()
    M33K.Database.SetSetting("debug", false)
    M33K.Options.HandleSlashCommand("debug")
    Harness.AssertEquals(M33K.Database.GetSetting("debug"), true, "Debug setting should toggle to true")

    M33K.Options.HandleSlashCommand("toggle")
    Harness.AssertEquals(M33K.Database.GetSetting("debug"), false, "Debug setting should toggle to false")
end)
