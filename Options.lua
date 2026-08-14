local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Options = {}
local Options = M33K.Options

function Options.HandleSlashCommand(msg)
    local args = {}
    for word in string.gmatch(msg or "", "%S+") do
        table.insert(args, string.lower(word))
    end

    local cmd = args[1] or "help"

    if cmd == "lock" then
        local isLocked = M33K.db and M33K.db.locked
        M33K.UI.SetLocked(not isLocked)

    elseif cmd == "reset" then
        M33K.UI.ResetPosition()

    elseif cmd == "toggle" then
        if M33kAuraUtilsMainFrame then
            if M33kAuraUtilsMainFrame:IsShown() then
                M33kAuraUtilsMainFrame:Hide()
            else
                M33kAuraUtilsMainFrame:Show()
            end
        end

    elseif cmd == "add" and args[2] and args[3] then
        local castId = tonumber(args[2])
        local buffId = tonumber(args[3])
        local duration = tonumber(args[4]) or 10
        if castId and buffId then
            M33K.Database.AddCustomSpell(castId, buffId, duration)
            print(string.format("M33kAuraUtils: Added custom spell CastID=%d, BuffID=%d, Duration=%ds", castId, buffId, duration))
        end

    else
        print("|cFF00FF00" .. M33K.L["SLASH_HELP_HEADER"] .. "|r")
        print(M33K.L["SLASH_HELP_LOCK"])
        print(M33K.L["SLASH_HELP_RESET"])
        print(M33K.L["SLASH_HELP_TOGGLE"])
        print("  /m33k add <castSpellId> <buffSpellId> [duration] - Add custom ground spell")
    end
end

function Options.Initialize()
    SLASH_M33KAURAUTILS1 = "/m33k"
    SLASH_M33KAURAUTILS2 = "/m33kaura"
    SLASH_M33KAURAUTILS3 = "/m33kaurautils"
    SlashCmdList["M33KAURAUTILS"] = function(msg)
        Options.HandleSlashCommand(msg)
    end
end

