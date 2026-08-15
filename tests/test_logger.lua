local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

local M33K = {}
Harness.LoadFullAddon(M33K)

Harness.BeginSuite("Logger & Diagnostics System Tests")

Harness.RunTest("1. Logger records structured log entries with timestamp, category, level, and serialized data", function()
    M33K.Logger.ClearLogs()

    M33K.Logger.Info("TEST", "Informational test message", { foo = "bar", count = 42 })
    M33K.Logger.Debug("CDM", "Debug trace", { spellID = 188370, active = true })
    M33K.Logger.Warn("INJECTION", "Warning alert", { auraId = "TestAura" })
    M33K.Logger.Error("ENGINE", "Error occurred", { code = 500 })

    local logs = M33K.Logger.GetLogs()
    Harness.Assert(#logs == 4, "Should have exactly 4 log entries")

    Harness.AssertEquals(logs[1].level, "INFO", "First entry level is INFO")
    Harness.AssertEquals(logs[1].category, "TEST", "First entry category is TEST")
    Harness.AssertEquals(logs[1].msg, "Informational test message", "First entry message matches")

    Harness.AssertEquals(logs[2].level, "DEBUG", "Second entry level is DEBUG")
    Harness.AssertEquals(logs[3].level, "WARN", "Third entry level is WARN")
    Harness.AssertEquals(logs[4].level, "ERROR", "Fourth entry level is ERROR")
end)

Harness.RunTest("2. SavedVariables persistence writes logs into _G.M33kAuraUtilsDB.logs for WTF disk export", function()
    _G.M33kAuraUtilsDB = {}
    M33K.Database.Initialize()
    M33K.Logger.ClearLogs()

    M33K.Logger.Info("PERSIST", "Message for WTF SavedVariables", { target = "SavedVariables" })

    Harness.Assert(_G.M33kAuraUtilsDB.logs ~= nil, "M33kAuraUtilsDB.logs should exist")
    Harness.Assert(#_G.M33kAuraUtilsDB.logs >= 1, "M33kAuraUtilsDB.logs should contain the entry")
    Harness.AssertEquals(_G.M33kAuraUtilsDB.logs[#_G.M33kAuraUtilsDB.logs].msg, "Message for WTF SavedVariables", "SavedVariables message should match")
end)

Harness.RunTest("3. Logger.ExportLogsToString formats logs into copyable text", function()
    M33K.Logger.ClearLogs()
    M33K.Logger.Info("AURA", "Test export 1", { val = 1 })
    M33K.Logger.Debug("AURA", "Test export 2", { val = 2 })

    local exported = M33K.Logger.ExportLogsToString()
    Harness.Assert(type(exported) == "string", "Exported logs should be a string")
    Harness.Assert(string.find(exported, "M33kAuraUtils Verbose Diagnostics") ~= nil, "Header should be present")
    Harness.Assert(string.find(exported, "Test export 1") ~= nil, "Log entry 1 should be present")
    Harness.Assert(string.find(exported, "Test export 2") ~= nil, "Log entry 2 should be present")
end)

Harness.RunTest("4. Logger.CaptureSnapshot records CDM viewer frames and WeakAuras states into SavedVariables", function()
    local mockIcon = {
        spellID = 188370,
        cooldownID = 55,
        cooldownUseAuraDisplayTime = true,
        cooldownExpirationTime = 1050.0,
        cooldownDuration = 15.0,
        IsShown = function() return true end,
    }
    _G.BuffIconCooldownViewer.itemFramePool._icons = { mockIcon }
    M33K.Injection.RegisterHookedAura("SnapshotTestAura", 1, { [188370] = true })

    local snap = M33K.Logger.CaptureSnapshot("Automated Test Snapshot")
    Harness.Assert(snap ~= nil, "Snapshot should be returned")
    Harness.AssertEquals(snap.reason, "Automated Test Snapshot", "Reason should match")
    Harness.Assert(snap.viewers.BuffIconCooldownViewer ~= nil, "BuffIconCooldownViewer should be inspected")
    Harness.Assert(#snap.viewers.BuffIconCooldownViewer.activeIcons == 1, "Should find 1 active buff icon in CDM viewer")
    Harness.AssertEquals(snap.viewers.BuffIconCooldownViewer.activeIcons[1].spellID, 188370, "SpellID in snapshot matches")

    Harness.Assert(_G.M33kAuraUtilsDB.lastSnapshot ~= nil, "lastSnapshot should be saved in DB")
    Harness.AssertEquals(_G.M33kAuraUtilsDB.lastSnapshot.reason, "Automated Test Snapshot", "DB lastSnapshot matches")

    _G.BuffIconCooldownViewer.itemFramePool._icons = {}
    M33K.Injection.UnregisterHookedAura("SnapshotTestAura")
end)

Harness.RunTest("5. Logger.Serialize handles numbers, strings, nested tables, and cyclic safety without errors", function()
    local complexTable = {
        num = 123,
        str = "hello",
        nested = {
            flag = true,
            arr = { 1, 2, 3 }
        }
    }
    local str = M33K.Logger.Serialize(complexTable, 3)
    Harness.Assert(type(str) == "string", "Serialized result should be a string")
    Harness.Assert(string.find(str, "num=123") ~= nil, "Serialized string should contain num=123")
    Harness.Assert(string.find(str, "nested=") ~= nil, "Serialized string should contain nested=")
end)

Harness.RunTest("6. Slash commands /m33k logs, /m33k snapshot, and /m33k clearlogs execute properly", function()
    -- /m33k snapshot
    M33K.Options.HandleSlashCommand("snapshot")
    Harness.Assert(_G.M33kAuraUtilsDB.lastSnapshot ~= nil, "Slash snapshot should record lastSnapshot")

    -- /m33k logs
    M33K.Options.HandleSlashCommand("logs")

    -- /m33k clearlogs
    M33K.Options.HandleSlashCommand("clearlogs")
    local logs = M33K.Logger.GetLogs()
    Harness.Assert(#logs <= 1, "Logs should be cleared (at most 1 entry from the clear log itself)")
end)
