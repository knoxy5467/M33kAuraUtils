local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

local M33K = {}
Harness.LoadFullAddon(M33K)

Harness.BeginSuite("In-Client Integration Test Runner & /wa integ Slash Hooks")

Harness.RunTest("1. IntegTest module is properly exposed in M33K namespace", function()
    Harness.Assert(M33K.IntegTest ~= nil, "IntegTest table should exist")
    Harness.Assert(type(M33K.IntegTest.RunInClientTests) == "function", "RunInClientTests should be a function")
    Harness.Assert(type(_G.M33kAuraUtils.RunIntegrationTests) == "function", "RunIntegrationTests global alias should exist")
end)

Harness.RunTest("2. RunInClientTests executes all 6 test steps successfully in mock environment", function()
    -- Set up necessary mocks
    _G.C_CooldownViewer._categorySets[1] = { 101 }
    _G.C_CooldownViewer._categorySets[3] = { 301 }
    _G.C_CooldownViewer._cooldowns[101] = { spellID = 31884 }
    _G.C_CooldownViewer._cooldowns[301] = { spellID = 188370 }

    local passed, failed = M33K.IntegTest.RunInClientTests()
    Harness.AssertEquals(failed, 0, "No integration test steps should fail")
    Harness.AssertEquals(passed, 6, "All 6 integration test steps should pass")

    -- Clean up
    _G.C_CooldownViewer._categorySets[1] = {}
    _G.C_CooldownViewer._categorySets[3] = {}
    _G.C_CooldownViewer._cooldowns[101] = nil
    _G.C_CooldownViewer._cooldowns[301] = nil
end)

Harness.RunTest("3. /m33k integ triggers in-client integration tests", function()
    local ran = false
    local orig_Run = M33K.IntegTest.RunInClientTests
    M33K.IntegTest.RunInClientTests = function()
        ran = true
        return 6, 0
    end

    M33K.Options.HandleSlashCommand("integ")
    Harness.AssertEquals(ran, true, "Options.HandleSlashCommand('integ') should run integration tests")

    M33K.IntegTest.RunInClientTests = orig_Run
end)

Harness.RunTest("4. /wa integ slash command hook intercepts and executes integration tests", function()
    local ranInteg = false
    local orig_Run = M33K.IntegTest.RunInClientTests
    M33K.IntegTest.RunInClientTests = function()
        ranInteg = true
        return 6, 0
    end

    -- Setup a dummy WeakAuras slash command
    local normalWARan = false
    _G.SlashCmdList = _G.SlashCmdList or {}
    _G.SlashCmdList["WEAKAURAS"] = function(msg)
        normalWARan = true
    end

    M33K.IntegTest.InitializeSlashHooks()

    -- Call /wa integ
    _G.SlashCmdList["WEAKAURAS"]("integ")
    Harness.AssertEquals(ranInteg, true, "/wa integ should trigger integration tests")
    Harness.AssertEquals(normalWARan, false, "Normal /wa logic should be bypassed on 'integ'")

    -- Call normal /wa
    _G.SlashCmdList["WEAKAURAS"]("")
    Harness.AssertEquals(normalWARan, true, "Normal /wa should execute when subcmd is not 'integ'")

    M33K.IntegTest.RunInClientTests = orig_Run
end)

Harness.RunTest("5. /twa integ slash command hook intercepts and executes integration tests", function()
    local ranInteg = false
    local orig_Run = M33K.IntegTest.RunInClientTests
    M33K.IntegTest.RunInClientTests = function()
        ranInteg = true
        return 6, 0
    end

    -- Setup a dummy ThisWeeksAuras slash command
    local normalTWARan = false
    _G.SlashCmdList["THISWEEKSAURAS"] = function(msg)
        normalTWARan = true
    end

    M33K.IntegTest.InitializeSlashHooks()

    -- Call /twa integ
    _G.SlashCmdList["THISWEEKSAURAS"]("integ")
    Harness.AssertEquals(ranInteg, true, "/twa integ should trigger integration tests")
    Harness.AssertEquals(normalTWARan, false, "Normal /twa logic should be bypassed on 'integ'")

    -- Call normal /twa
    _G.SlashCmdList["THISWEEKSAURAS"]("")
    Harness.AssertEquals(normalTWARan, true, "Normal /twa should execute when subcmd is not 'integ'")

    M33K.IntegTest.RunInClientTests = orig_Run
end)
