local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.IntegTest = {}
local IntegTest = M33K.IntegTest

local function PrintMsg(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00B4FF[M33kAuraUtils Integ]|r " .. msg)
    else
        print("|cFF00B4FF[M33kAuraUtils Integ]|r " .. msg)
    end
end

----------------------------------------------------------------------
-- In-Client Integration Test Runner
----------------------------------------------------------------------
function IntegTest.RunInClientTests()
    PrintMsg("========================================")
    PrintMsg("Starting In-Client Live Integration Tests...")
    PrintMsg("========================================")

    local passed = 0
    local failed = 0

    local function RunStep(name, testFunc)
        local ok, err = pcall(testFunc)
        if ok and (err == nil or err == true) then
            passed = passed + 1
            PrintMsg("|cFF00FF00[PASS]|r " .. name)
        else
            failed = failed + 1
            PrintMsg("|cFFFF0000[FAIL]|r " .. name .. ": " .. tostring(err or "Test assertion failed"))
        end
    end

    -- 1. Blizzard CDM API
    RunStep("1. Blizzard CDM API & Categories", function()
        if not C_CooldownViewer then
            error("C_CooldownViewer global table not found in this client", 2)
        end
        if type(C_CooldownViewer.GetCooldownViewerCategorySet) ~= "function" then
            error("C_CooldownViewer.GetCooldownViewerCategorySet is not a function", 2)
        end
        if type(C_CooldownViewer.GetCooldownViewerCooldownInfo) ~= "function" then
            error("C_CooldownViewer.GetCooldownViewerCooldownInfo is not a function", 2)
        end
        if not (Enum and Enum.CooldownViewerCategory) then
            error("Enum.CooldownViewerCategory not found", 2)
        end
        return true
    end)

    -- 2. Blizzard Cooldown Viewers
    RunStep("2. Blizzard Cooldown Viewer Global Frames", function()
        local viewers = {
            "BuffIconCooldownViewer",
            "BuffBarCooldownViewer",
            "EssentialCooldownViewer",
            "UtilityCooldownViewer",
        }
        local found = {}
        for _, vName in ipairs(viewers) do
            local frame = _G[vName]
            if frame then
                table.insert(found, vName)
            end
        end
        if #found == 0 then
            error("No Blizzard Cooldown Viewers found in globals (not loaded yet)", 2)
        end
        return true
    end)

    -- 3. CDM Tracked Buffs & Bars Enumeration
    RunStep("3. CDM Tracked Buffs & Bars Enumeration", function()
        if not (M33K.CooldownViewer and M33K.CooldownViewer.EnumerateTrackedBuffsAndBars) then
            error("M33K.CooldownViewer.EnumerateTrackedBuffsAndBars not available", 2)
        end
        local activeBuffs = M33K.CooldownViewer.EnumerateTrackedBuffsAndBars(false)
        local allBuffs = M33K.CooldownViewer.EnumerateTrackedBuffsAndBars(true)
        local countActive = 0
        for _ in pairs(activeBuffs or {}) do countActive = countActive + 1 end
        local countAll = 0
        for _ in pairs(allBuffs or {}) do countAll = countAll + 1 end
        PrintMsg(string.format("   -> Found %d active tracked buffs/bars (%d in database)", countActive, countAll))
        return true
    end)

    -- 4. CDM Essential & Utility Cooldowns Enumeration
    RunStep("4. CDM Essential & Utility Cooldowns Enumeration", function()
        if not (M33K.CooldownViewer and M33K.CooldownViewer.EnumerateCooldowns) then
            error("M33K.CooldownViewer.EnumerateCooldowns not available", 2)
        end
        local activeCDs = M33K.CooldownViewer.EnumerateCooldowns(false)
        local allCDs = M33K.CooldownViewer.EnumerateCooldowns(true)
        local countActive = 0
        for _ in pairs(activeCDs or {}) do countActive = countActive + 1 end
        local countAll = 0
        for _ in pairs(allCDs or {}) do countAll = countAll + 1 end
        PrintMsg(string.format("   -> Found %d active cooldowns (%d in database)", countActive, countAll))
        return true
    end)

    -- 5. Aura Framework Detection & Options Injection
    RunStep("5. Aura Framework Injection Verification", function()
        local fw = _G.ThisWeeksAuras or _G.M33kAuras or _G.WeakAuras
        if not fw then
            error("No supported Aura Framework (M33kAuras / ThisWeeksAuras / WeakAuras) detected in client", 2)
        end

        if M33K.Injection and M33K.Injection.Initialize then
            M33K.Injection.Initialize()
        end

        local optPrivate = _G.OptionsPrivate or (fw and fw.OptionsPrivate)
        if not optPrivate then
            error("OptionsPrivate not accessible (open WeakAuras GUI with /wa to initialize options)", 2)
        end

        -- Test Buff trigger options injection
        if optPrivate.GetBuffTriggerOptions then
            local testData = {
                id = "IntegTestBuffAura",
                triggers = {
                    [1] = {
                        trigger = { type = "aura2", unit = "player", useCooldownViewer = true }
                    }
                }
            }
            local opts = optPrivate.GetBuffTriggerOptions(testData, 1)
            local auraOpts = opts and opts["trigger.1.aura_options"]
            if not (auraOpts and auraOpts.cvPickerBuffsAndBars and auraOpts.cvShowAllBuffs) then
                error("Injected controls missing from GetBuffTriggerOptions", 2)
            end
        end

        -- Test Spell trigger options injection
        if optPrivate.GetSpellTriggerOptions then
            local testSpellData = {
                id = "IntegTestSpellAura",
                triggers = {
                    [1] = {
                        trigger = { type = "spell", useCooldownViewer = true }
                    }
                }
            }
            local opts = optPrivate.GetSpellTriggerOptions(testSpellData, 1)
            local spellOpts = opts and (opts["trigger.1.spell_options"] or opts["trigger.1.aura_options"])
            if not (spellOpts and spellOpts.cvPickerCooldowns and spellOpts.cvShowAllCooldowns) then
                error("Injected controls missing from GetSpellTriggerOptions", 2)
            end
        end

        return true
    end)

    -- 6. Engine State Evaluation
    RunStep("6. Engine State Evaluation", function()
        local isUsable, notEnoughPower, onCD = M33K.CooldownViewer.IsSpellUsable(633)
        local active, exp, dur = M33K.CooldownViewer.IsBuffActive(188370)
        return true
    end)

    PrintMsg("========================================")
    if failed == 0 then
        PrintMsg(string.format("|cFF00FF00ALL %d IN-CLIENT INTEGRATION TESTS PASSED!|r", passed))
    else
        PrintMsg(string.format("|cFFFF0000INTEGRATION TESTS FINISHED: %d Passed, %d Failed|r", passed, failed))
    end
    PrintMsg("========================================")

    return passed, failed
end

----------------------------------------------------------------------
-- Slash Command Interceptor for /wa integ, /twa integ, /m33k integ
----------------------------------------------------------------------
local function HookSlashHandler(cmdKey, originalFunc)
    if not originalFunc then return end
    SlashCmdList[cmdKey] = function(msg, editBox)
        local subCmd = string.lower(string.match(msg or "", "^%s*(%a+)") or "")
        if subCmd == "integ" or subCmd == "test" or subCmd == "integration" then
            IntegTest.RunInClientTests()
            return
        end
        return originalFunc(msg, editBox)
    end
end

function IntegTest.InitializeSlashHooks()
    -- Hook /wa and /weakauras
    if SlashCmdList then
        if SlashCmdList["WEAKAURAS"] and not SlashCmdList["WEAKAURAS_CVHOOKED"] then
            local orig = SlashCmdList["WEAKAURAS"]
            HookSlashHandler("WEAKAURAS", orig)
            SlashCmdList["WEAKAURAS_CVHOOKED"] = true
        end

        if SlashCmdList["THISWEEKSAURAS"] and not SlashCmdList["THISWEEKSAURAS_CVHOOKED"] then
            local orig = SlashCmdList["THISWEEKSAURAS"]
            HookSlashHandler("THISWEEKSAURAS", orig)
            SlashCmdList["THISWEEKSAURAS_CVHOOKED"] = true
        end

        if SlashCmdList["M33KAURAS"] and not SlashCmdList["M33KAURAS_CVHOOKED"] then
            local orig = SlashCmdList["M33KAURAS"]
            HookSlashHandler("M33KAURAS", orig)
            SlashCmdList["M33KAURAS_CVHOOKED"] = true
        end
    end
end

_G.M33kAuraUtils.RunIntegrationTests = IntegTest.RunInClientTests
