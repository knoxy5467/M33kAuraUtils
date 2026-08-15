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
    elseif cmd == "integ" or cmd == "test" or cmd == "integration" then
        if M33K.IntegTest and M33K.IntegTest.RunInClientTests then
            M33K.IntegTest.RunInClientTests()
        elseif M33K.RunIntegrationTests then
            M33K.RunIntegrationTests()
        else
            print("|cFF00B4FFM33kAuraUtils|r: Integration test module not loaded.")
        end
    elseif cmd == "status" or cmd == "info" then
        print("|cFF00B4FFM33kAuraUtils|r: Active and integrated with Blizzard Cooldown Viewer.")
    else
        print("|cFF00B4FFM33kAuraUtils|r: Blizzard Cooldown Viewer & Aura integration active. Type |cFF00FF00/wa integ|r or |cFF00FF00/m33k integ|r to run in-client integration tests.")
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
