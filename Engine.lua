local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.CooldownViewer = {}
local CDViewer = M33K.CooldownViewer

-- Standard Blizzard Cooldown Viewers
local VIEWERS = {
    "BuffIconCooldownViewer",
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

-- Normalize spell input into a lookup table { [spellID] = true }
local function NormalizeTargetSpells(targetSpells)
    local lookup = {}
    if type(targetSpells) == "number" then
        lookup[targetSpells] = true
    elseif type(targetSpells) == "string" then
        local num = tonumber(targetSpells)
        if num then
            lookup[num] = true
        else
            lookup[targetSpells] = true
        end
    elseif type(targetSpells) == "table" then
        for k, v in pairs(targetSpells) do
            if type(k) == "number" and type(v) == "number" then
                lookup[v] = true
            elseif type(k) == "number" and type(v) == "boolean" and v == true then
                lookup[k] = true
            elseif type(v) == "number" then
                lookup[v] = true
            end
        end
    end
    return lookup
end

-- Core Cooldown Viewer & Aura check logic
function CDViewer.IsBuffActive(targetSpells)
    local TARGET_SPELLS = NormalizeTargetSpells(targetSpells)

    -- A. Direct check for unit aura via C_UnitAuras
    if C_UnitAuras and type(C_UnitAuras.GetUnitAuraBySpellID) == "function" then
        for spellID in pairs(TARGET_SPELLS) do
            if type(spellID) == "number" then
                local aura = C_UnitAuras.GetUnitAuraBySpellID("player", spellID)
                if aura then
                    local dur = aura.duration or 0
                    local exp = aura.expirationTime or 0
                    local icon = aura.icon
                    return true, exp, dur, icon
                end
            end
        end
    end

    -- B. Blizzard Cooldown Viewer check
    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
            for icon in viewer.itemFramePool:EnumerateActive() do
                -- CRITICAL: Must be actively displaying an active AURA/BUFF timer (not spell CD)
                if icon and (not icon.IsShown or icon:IsShown()) and icon.cooldownUseAuraDisplayTime == true then
                    local info = icon.cooldownInfo
                    local cid = icon.cooldownID

                    if not info and cid and not (issecretvalue and issecretvalue(cid))
                       and C_CooldownViewer and type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function" then
                        local ok, cdInfo = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
                        if ok and type(cdInfo) == "table" then
                            info = cdInfo
                        end
                    end

                    local rawID = type(icon.spellID) == "number" and icon.spellID or nil
                    local isMatch = (rawID and TARGET_SPELLS[rawID])
                                 or (info and (TARGET_SPELLS[info.spellID] or TARGET_SPELLS[info.overrideSpellID] or TARGET_SPELLS[info.overrideTooltipSpellID]))

                    if not isMatch and info and type(info.linkedSpellIDs) == "table" then
                        for _, id in ipairs(info.linkedSpellIDs) do
                            if TARGET_SPELLS[id] then
                                isMatch = true
                                break
                            end
                        end
                    end

                    if isMatch then
                        local exp = icon.cooldownExpirationTime or (info and info.cooldownExpirationTime) or 0
                        local dur = icon.cooldownDuration or (info and info.cooldownDuration) or 0
                        local iconTexture = icon.icon and icon.icon:GetTexture() or nil
                        return true, exp, dur, iconTexture
                    end
                end
            end
        end
    end

    return false, 0, 0, nil
end

-- Enumerate all spells currently tracked by Blizzard Cooldown Viewers
-- Returns: { [spellID] = { name, icon, viewerName, isBuffTimer, linkedSpellIDs } }
function CDViewer.EnumerateTracked()
    local tracked = {}

    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
            for icon in viewer.itemFramePool:EnumerateActive() do
                if icon and (not icon.IsShown or icon:IsShown()) then
                    local info = icon.cooldownInfo
                    local cid = icon.cooldownID

                    if not info and cid and not (issecretvalue and issecretvalue(cid))
                       and C_CooldownViewer and type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function" then
                        local ok, cdInfo = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
                        if ok and type(cdInfo) == "table" then
                            info = cdInfo
                        end
                    end

                    local spellID = type(icon.spellID) == "number" and icon.spellID
                                 or (info and info.spellID)
                    local isBuffTimer = (icon.cooldownUseAuraDisplayTime == true)

                    if spellID then
                        -- Resolve spell name and icon texture
                        local spellName, spellIcon
                        if M33K.Spells and M33K.Spells.GetSpellInfo then
                            local si = M33K.Spells.GetSpellInfo(spellID)
                            spellName = si and si.name
                            spellIcon = si and si.icon
                        end
                        if not spellIcon and icon.icon and icon.icon.GetTexture then
                            spellIcon = icon.icon:GetTexture()
                        end

                        local linkedIDs = {}
                        if info then
                            if info.overrideSpellID then
                                linkedIDs[#linkedIDs + 1] = info.overrideSpellID
                            end
                            if info.overrideTooltipSpellID then
                                linkedIDs[#linkedIDs + 1] = info.overrideTooltipSpellID
                            end
                            if type(info.linkedSpellIDs) == "table" then
                                for _, lid in ipairs(info.linkedSpellIDs) do
                                    linkedIDs[#linkedIDs + 1] = lid
                                end
                            end
                        end

                        tracked[spellID] = {
                            name = spellName or ("Spell " .. spellID),
                            icon = spellIcon or 136243,
                            viewerName = viewerName,
                            isBuffTimer = isBuffTimer,
                            linkedSpellIDs = linkedIDs,
                        }
                    end
                end
            end
        end
    end

    return tracked
end

-- Global helper export for WeakAuras / Custom triggers
_G.M33kAuraUtils.IsBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.IsCooldownViewerBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.EnumerateTracked = CDViewer.EnumerateTracked

-- Engine wrapper for lifecycle events and callback subscriptions
M33K.Engine = {}
local Engine = M33K.Engine

local callbacks = {}

function Engine.Initialize()
    callbacks = {}
end

function Engine.RegisterCallback(id, fn)
    callbacks[id] = fn
end

function Engine.UnregisterCallback(id)
    callbacks[id] = nil
end

function Engine.CheckAura(targetSpells)
    return CDViewer.IsBuffActive(targetSpells)
end
