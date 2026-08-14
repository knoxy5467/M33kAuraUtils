local AddonName, GAT = ...

GAT.Options = {}
local Options = GAT.Options

function Options.HandleSlashCommand(msg)
    local args = {}
    for word in string.gmatch(msg or "", "%S+") do
        table.insert(args, string.lower(word))
    end

    local cmd = args[1] or "help"

    if cmd == "lock" then
        local isLocked = GAT.db and GAT.db.locked
        GAT.UI.SetLocked(not isLocked)

    elseif cmd == "reset" then
        GAT.UI.ResetPosition()

    elseif cmd == "toggle" then
        if GroundAuraTrackerMainFrame then
            if GroundAuraTrackerMainFrame:IsShown() then
                GroundAuraTrackerMainFrame:Hide()
            else
                GroundAuraTrackerMainFrame:Show()
            end
        end

    elseif cmd == "add" and args[2] and args[3] then
        local castId = tonumber(args[2])
        local buffId = tonumber(args[3])
        local duration = tonumber(args[4]) or 10
        if castId and buffId then
            GAT.Database.AddCustomSpell(castId, buffId, duration)
            print(string.format("GroundAuraTracker: Added custom spell CastID=%d, BuffID=%d, Duration=%ds", castId, buffId, duration))
        end

    else
        print("|cFF00FF00" .. GAT.L["SLASH_HELP_HEADER"] .. "|r")
        print(GAT.L["SLASH_HELP_LOCK"])
        print(GAT.L["SLASH_HELP_RESET"])
        print(GAT.L["SLASH_HELP_TOGGLE"])
        print("  /gat add <castSpellId> <buffSpellId> [duration] - Add custom ground spell")
    end
end

function Options.Initialize()
    SLASH_GROUNDAURATRACKER1 = "/gat"
    SLASH_GROUNDAURATRACKER2 = "/groundaura"
    SlashCmdList["GROUNDAURATRACKER"] = function(msg)
        Options.HandleSlashCommand(msg)
    end
end
