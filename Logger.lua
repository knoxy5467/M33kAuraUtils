local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Logger = {}
local Logger = M33K.Logger

local MAX_LOG_ENTRIES = 1000
local inMemoryLogs = {}
local exportFrame = nil

-- Safe value serialization helper
function Logger.Serialize(val, maxDepth, currentDepth)
    maxDepth = maxDepth or 3
    currentDepth = currentDepth or 0

    local t = type(val)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" or t == "number" then
        return tostring(val)
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "function" or t == "userdata" or t == "thread" then
        return string.format("<%s>", tostring(val))
    elseif t == "table" then
        if currentDepth >= maxDepth then
            return "{...}"
        end
        local parts = {}
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if count > 25 then
                table.insert(parts, "... [truncated]")
                break
            end
            local keyStr = tostring(k)
            if type(k) == "string" and string.match(k, "^[a-zA-Z_][a-zA-Z0-9_]*$") then
                keyStr = k
            else
                keyStr = "[" .. Logger.Serialize(k, maxDepth, currentDepth + 1) .. "]"
            end
            local valStr = Logger.Serialize(v, maxDepth, currentDepth + 1)
            table.insert(parts, keyStr .. "=" .. valStr)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(val)
end

local function GetTimestampStr()
    local now = GetTime and GetTime() or 0
    local dateStr = date and date("%Y-%m-%d %H:%M:%S") or "00:00:00"
    return string.format("[%s (%.3fs)]", dateStr, now)
end

function Logger.Log(category, level, msg, data)
    level = level or "INFO"
    category = category or "GENERAL"
    msg = msg or ""

    local dataStr = data ~= nil and (" | Data: " .. Logger.Serialize(data, 2)) or ""
    local timeStr = GetTimestampStr()
    local entry = {
        time = GetTime and GetTime() or 0,
        date = date and date("%Y-%m-%d %H:%M:%S") or "",
        category = category,
        level = level,
        msg = msg,
        data = data,
        formatted = string.format("%s [%s] [%s] %s%s", timeStr, level, category, msg, dataStr),
    }

    -- 1. In-memory circular buffer
    table.insert(inMemoryLogs, entry)
    if #inMemoryLogs > MAX_LOG_ENTRIES then
        table.remove(inMemoryLogs, 1)
    end

    -- 2. SavedVariables persistence (flushed to WTF on /reload or exit)
    if _G.M33kAuraUtilsDB then
        if not _G.M33kAuraUtilsDB.logs then
            _G.M33kAuraUtilsDB.logs = {}
        end
        table.insert(_G.M33kAuraUtilsDB.logs, entry)
        if #_G.M33kAuraUtilsDB.logs > MAX_LOG_ENTRIES then
            table.remove(_G.M33kAuraUtilsDB.logs, 1)
        end
    end

    -- 3. File logging outside of WoW (for CLI test harness / standalone environments)
    if io and io.open then
        local f = io.open("M33kAuraUtils_debug.log", "a")
        if f then
            f:write(entry.formatted .. "\n")
            f:close()
        end
    end

    -- 4. In-game chat printing if debug mode is active
    local debugActive = false
    if M33K.Database and M33K.Database.GetSetting then
        debugActive = (M33K.Database.GetSetting("debug") == true)
    end

    if debugActive then
        local color = "|cFF00B4FF"
        if level == "ERROR" then
            color = "|cFFFF0000"
        elseif level == "WARN" then
            color = "|cFFFF8800"
        elseif level == "DEBUG" then
            color = "|cFF888888"
        end
        local chatMsg = string.format("%s[M33K-%s]|r %s%s", color, category, msg, dataStr)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(chatMsg)
        elseif print then
            print(chatMsg)
        end
    end
end

function Logger.Debug(category, msg, data)
    Logger.Log(category, "DEBUG", msg, data)
end

function Logger.Info(category, msg, data)
    Logger.Log(category, "INFO", msg, data)
end

function Logger.Warn(category, msg, data)
    Logger.Log(category, "WARN", msg, data)
end

function Logger.Error(category, msg, data)
    Logger.Log(category, "ERROR", msg, data)
end

function Logger.ClearLogs()
    inMemoryLogs = {}
    if _G.M33kAuraUtilsDB then
        _G.M33kAuraUtilsDB.logs = {}
    end
end

function Logger.GetLogs()
    if _G.M33kAuraUtilsDB and _G.M33kAuraUtilsDB.logs then
        return _G.M33kAuraUtilsDB.logs
    end
    return inMemoryLogs
end

function Logger.ExportLogsToString()
    local logs = Logger.GetLogs()
    local lines = {
        "==================================================",
        " M33kAuraUtils Verbose Diagnostics & State Log",
        " Time: " .. (date and date("%Y-%m-%d %H:%M:%S") or "Unknown"),
        " Total Entries: " .. tostring(#logs),
        "==================================================",
        "",
    }

    for _, entry in ipairs(logs) do
        table.insert(lines, entry.formatted or string.format("[%s] [%s] %s", entry.level or "INFO", entry.category or "GEN", entry.msg or ""))
    end

    return table.concat(lines, "\n")
end

-- Capture an instant snapshot of all CDM viewers and WeakAuras states into SavedVariables
function Logger.CaptureSnapshot(reason)
    reason = reason or "Manual Snapshot"
    local snapshot = {
        timestamp = date and date("%Y-%m-%d %H:%M:%S") or "",
        uptime = GetTime and GetTime() or 0,
        reason = reason,
        viewers = {},
        hookedAuras = {},
        waStates = {},
    }

    -- 1. Inspect live CDM viewers
    local viewers = { "BuffIconCooldownViewer", "BuffBarCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer" }
    for _, vName in ipairs(viewers) do
        local viewer = _G[vName]
        snapshot.viewers[vName] = {
            exists = (viewer ~= nil),
            activeIcons = {},
        }
        if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
            for icon in viewer.itemFramePool:EnumerateActive() do
                if icon then
                    local iconData = {
                        spellID = icon.spellID,
                        cooldownID = icon.cooldownID,
                        cooldownUseAuraDisplayTime = icon.cooldownUseAuraDisplayTime,
                        cooldownExpirationTime = icon.cooldownExpirationTime,
                        cooldownDuration = icon.cooldownDuration,
                        shown = icon.IsShown and icon:IsShown() or false,
                    }
                    if icon.Applications and icon.Applications.Applications then
                        iconData.applications = icon.Applications.Applications
                    end
                    if icon.Icon and icon.Icon.GetTexture then
                        iconData.texture = icon.Icon:GetTexture()
                    end
                    table.insert(snapshot.viewers[vName].activeIcons, iconData)
                end
            end
        end
    end

    -- 2. Inspect hooked auras and their WA state tables
    if M33K.Injection and M33K.Injection.GetHookedAuras then
        snapshot.hookedAuras = M33K.Injection.GetHookedAuras()
    end

    local frameworks = { _G.ThisWeeksAuras, _G.M33kAuras, _G.WeakAuras }
    for _, WA in ipairs(frameworks) do
        if WA and WA.GetTriggerStateForTrigger and snapshot.hookedAuras then
            for auraId, hookInfo in pairs(snapshot.hookedAuras) do
                local stateTable = WA.GetTriggerStateForTrigger(auraId, hookInfo.triggernum)
                if stateTable then
                    snapshot.waStates[auraId] = {
                        triggernum = hookInfo.triggernum,
                        targetSpells = hookInfo.targetSpells,
                        state = stateTable[""] or stateTable,
                    }
                end
            end
        end
    end

    if _G.M33kAuraUtilsDB then
        _G.M33kAuraUtilsDB.lastSnapshot = snapshot
        if not _G.M33kAuraUtilsDB.snapshots then
            _G.M33kAuraUtilsDB.snapshots = {}
        end
        table.insert(_G.M33kAuraUtilsDB.snapshots, snapshot)
        if #_G.M33kAuraUtilsDB.snapshots > 10 then
            table.remove(_G.M33kAuraUtilsDB.snapshots, 1)
        end
    end

    Logger.Info("SNAPSHOT", "Captured system state snapshot: " .. reason, {
        activeBuffIcons = snapshot.viewers.BuffIconCooldownViewer and #snapshot.viewers.BuffIconCooldownViewer.activeIcons or 0,
        hookedAuraCount = snapshot.hookedAuras and (function() local c = 0 for _ in pairs(snapshot.hookedAuras) do c = c + 1 end return c end)() or 0,
    })

    return snapshot
end

-- Show in-game popup editbox frame for copying logs/snapshots
function Logger.ShowExportWindow(textToDisplay)
    textToDisplay = textToDisplay or Logger.ExportLogsToString()

    if not CreateFrame or not UIParent then
        if print then print(textToDisplay) end
        return
    end

    if not exportFrame then
        local f = CreateFrame("Frame", "M33kAuraUtilsExportFrame", UIParent, "DialogBoxFrame")
        if f.SetSize then f:SetSize(650, 450) end
        if f.SetPoint then f:SetPoint("CENTER") end
        if f.SetMovable then f:SetMovable(true) end
        if f.EnableMouse then f:EnableMouse(true) end
        if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
        if f.SetScript then
            f:SetScript("OnDragStart", function(self) if self.StartMoving then self:StartMoving() end end)
            f:SetScript("OnDragStop", function(self) if self.StopMovingOrSizing then self:StopMovingOrSizing() end end)
        end
        if f.SetFrameStrata then f:SetFrameStrata("DIALOG") end

        local title = f.CreateFontString and f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        if title then
            title:SetPoint("TOP", f, "TOP", 0, -10)
            title:SetText("|cFF00B4FFM33kAuraUtils Diagnostics & State Log|r")
        end

        local scroll = CreateFrame("ScrollFrame", "M33kAuraUtilsExportScroll", f, "UIPanelScrollFrameTemplate")
        if scroll and scroll.SetPoint then
            scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -40)
            scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 50)
        end

        local editBox = CreateFrame("EditBox", "M33kAuraUtilsExportEditBox", scroll)
        if editBox then
            if editBox.SetMultiLine then editBox:SetMultiLine(true) end
            if editBox.SetMaxLetters then editBox:SetMaxLetters(999999) end
            if editBox.EnableMouse then editBox:EnableMouse(true) end
            if editBox.SetFontObject and _G.ChatFontNormal then editBox:SetFontObject(_G.ChatFontNormal) end
            if editBox.SetWidth then editBox:SetWidth(595) end
            if editBox.SetScript then editBox:SetScript("OnEscapePressed", function(self) f:Hide() end) end
            if scroll and scroll.SetScrollChild then scroll:SetScrollChild(editBox) end
        end
        f.editBox = editBox

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        if closeBtn then
            if closeBtn.SetSize then closeBtn:SetSize(100, 24) end
            if closeBtn.SetPoint then closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 15) end
            if closeBtn.SetText then closeBtn:SetText("Close") end
            if closeBtn.SetScript then closeBtn:SetScript("OnClick", function() f:Hide() end) end
        end

        local copyHint = f.CreateFontString and f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if copyHint then
            copyHint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 20)
            copyHint:SetText("Press |cFF00FF00CTRL+A|r then |cFF00FF00CTRL+C|r to copy all logs.")
        end

        exportFrame = f
    end

    if exportFrame.editBox and exportFrame.editBox.SetText then
        exportFrame.editBox:SetText(textToDisplay)
        if exportFrame.editBox.HighlightText then exportFrame.editBox:HighlightText() end
        if exportFrame.editBox.SetFocus then exportFrame.editBox:SetFocus() end
    end
    if exportFrame.Show then
        exportFrame:Show()
    end
end

-- Export convenience shortcuts to M33K
M33K.Log = Logger.Log
M33K.Debug = Logger.Debug
M33K.Info = Logger.Info
M33K.Warn = Logger.Warn
M33K.Error = Logger.Error
