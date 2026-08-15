local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Options = {}
local Options = M33K.Options

function Options.HandleSlashCommand(msg)
    local cmd, arg = string.match(msg or "", "^(%a+)%s*(.*)$")
    cmd = string.lower(cmd or "")

    if cmd == "debug" or cmd == "toggle" then
        local current = M33K.Database.GetSetting("debug")
        M33K.Database.SetSetting("debug", not current)
        print("|cFF00B4FFM33kAuraUtils|r: Debug mode is now " .. (not current and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        if M33K.Logger and M33K.Logger.Info then
            M33K.Logger.Info("OPTIONS", "Debug mode toggled " .. (not current and "ON" or "OFF"))
        end
    elseif cmd == "dump" or cmd == "logs" or cmd == "export" then
        if M33K.Logger and M33K.Logger.ShowExportWindow then
            M33K.Logger.ShowExportWindow()
        else
            print("|cFF00B4FFM33kAuraUtils|r: Logger export window not available.")
        end
    elseif cmd == "snapshot" then
        if M33K.Logger and M33K.Logger.CaptureSnapshot then
            local snap = M33K.Logger.CaptureSnapshot("User Slash Command")
            print("|cFF00B4FFM33kAuraUtils|r: Captured system snapshot into SavedVariables (M33kAuraUtilsDB.snapshots). Saved to WTF on /reload.")
        end
    elseif cmd == "clearlogs" or cmd == "clear" then
        if M33K.Logger and M33K.Logger.ClearLogs then
            M33K.Logger.ClearLogs()
            print("|cFF00B4FFM33kAuraUtils|r: All debug logs cleared.")
        end
    elseif cmd == "integ" or cmd == "test" or cmd == "integration" then
        if M33K.IntegTest and M33K.IntegTest.RunInClientTests then
            M33K.IntegTest.RunInClientTests()
        elseif M33K.RunIntegrationTests then
            M33K.RunIntegrationTests()
        else
            print("|cFF00B4FFM33kAuraUtils|r: Integration test module not loaded.")
        end
    elseif cmd == "status" or cmd == "info" then
        local logCount = M33K.Logger and #M33K.Logger.GetLogs() or 0
        local debugOn = M33K.Database and M33K.Database.GetSetting("debug") or false
        print(string.format("|cFF00B4FFM33kAuraUtils|r: Active. Debug: %s | Buffered Logs: %d entries. Type |cFF00FF00/m33k logs|r to view.", debugOn and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r", logCount))
    else
        print("|cFF00B4FFM33kAuraUtils Commands:|r")
        print("  |cFF00FF00/m33k debug|r - Toggle verbose chat debug logging")
        print("  |cFF00FF00/m33k logs|r - Open copyable diagnostics and state logs window")
        print("  |cFF00FF00/m33k snapshot|r - Capture instant state snapshot into SavedVariables")
        print("  |cFF00FF00/m33k clearlogs|r - Clear buffered debug logs")
        print("  |cFF00FF00/m33k integ|r - Run in-client integration test suite")
    end
end

if SlashCmdList then
    SLASH_M33KAURAUTILS1 = "/m33k"
    SLASH_M33KAURAUTILS2 = "/m33kaura"
    SLASH_M33KAURAUTILS3 = "/m33kaurautils"

    SlashCmdList["M33KAURAUTILS"] = function(msg)
        Options.HandleSlashCommand(msg)
    end
end
