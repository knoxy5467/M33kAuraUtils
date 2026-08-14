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

-- Viewer name → category label
local VIEWER_CATEGORY = {
    BuffIconCooldownViewer  = "Buff",
    EssentialCooldownViewer = "Essential",
    UtilityCooldownViewer   = "Utility",
}

-- Safe secret check (handles both issecretvalue and canaccessvalue)
local function IsValueSecret(value)
    if type(value) ~= "number" then return false end
    if type(canaccessvalue) == "function" then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok ~= true or accessible ~= true then return true end
    end
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok ~= true or secret == true then return true end
    end
    return false
end

-- Normalize a cooldownID/spellID to a safe number or nil
local function NormPublicSpellID(value)
    if IsValueSecret(value) then return nil end
    local n = tonumber(value)
    if type(n) ~= "number" or n <= 0 then return nil end
    return math.floor(n + 0.5)
end

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

-- Resolve cooldown info from an icon frame
local function ResolveIconInfo(icon)
    local info = icon.cooldownInfo
    local cid = icon.cooldownID

    if not info and cid and not IsValueSecret(cid)
       and C_CooldownViewer and type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function" then
        local ok, cdInfo = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
        if ok and type(cdInfo) == "table" then
            info = cdInfo
        end
    end
    return info
end

-- Resolve spell name and icon texture for a given spellID
local function ResolveSpellDisplay(spellID, iconFrame)
    local spellName, spellIcon

    if M33K.Spells and M33K.Spells.GetSpellInfo then
        local si = M33K.Spells.GetSpellInfo(spellID)
        spellName = si and si.name
        spellIcon = si and si.icon
    end

    -- Fallback: try icon.Icon (capital I, Blizzard CDM convention) then icon.icon
    if not spellIcon and iconFrame then
        local iconTexture = iconFrame.Icon or iconFrame.icon
        if iconTexture and type(iconTexture.GetTexture) == "function" then
            spellIcon = iconTexture:GetTexture()
        end
    end

    return spellName or ("Spell " .. spellID), spellIcon or 136243
end

-- Collect linked/override spell IDs from cooldown info
local function CollectLinkedIDs(info)
    local linkedIDs = {}
    if not info then return linkedIDs end

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
    return linkedIDs
end

----------------------------------------------------------------------
-- Core: IsBuffActive (trigger/untrigger logic)
----------------------------------------------------------------------
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
                    local ic = aura.icon
                    return true, exp, dur, ic
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
                    local info = ResolveIconInfo(icon)

                    local rawID = NormPublicSpellID(icon.spellID)
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
                        local iconTexture = (icon.Icon or icon.icon)
                        if iconTexture and type(iconTexture.GetTexture) == "function" then
                            iconTexture = iconTexture:GetTexture()
                        else
                            iconTexture = nil
                        end
                        return true, exp, dur, iconTexture
                    end
                end
            end
        end
    end

    return false, 0, 0, nil
end

----------------------------------------------------------------------
-- Enumerate: Scan viewer frame pools (live icons on screen)
----------------------------------------------------------------------
-- categoryFilter: nil=all, "Buff", "Essential", "Utility"
-- buffsOnly: if true, only return entries where cooldownUseAuraDisplayTime == true
function CDViewer.EnumerateTracked(categoryFilter, buffsOnly)
    local tracked = {}

    for _, viewerName in ipairs(VIEWERS) do
        local cat = VIEWER_CATEGORY[viewerName]

        -- Skip if a category filter is set and doesn't match
        if not categoryFilter or cat == categoryFilter then
            local viewer = _G[viewerName]
            if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
                for icon in viewer.itemFramePool:EnumerateActive() do
                    if icon and (not icon.IsShown or icon:IsShown()) then
                        local isBuffTimer = (icon.cooldownUseAuraDisplayTime == true)

                        -- If buffsOnly, skip non-buff entries
                        if not buffsOnly or isBuffTimer then
                            local info = ResolveIconInfo(icon)
                            local spellID = NormPublicSpellID(icon.spellID)
                                         or (info and NormPublicSpellID(info.spellID))

                            if spellID then
                                local spellName, spellIcon = ResolveSpellDisplay(spellID, icon)

                                tracked[spellID] = {
                                    name = spellName,
                                    icon = spellIcon,
                                    category = cat,
                                    viewerName = viewerName,
                                    isBuffTimer = isBuffTimer,
                                    linkedSpellIDs = CollectLinkedIDs(info),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return tracked
end

----------------------------------------------------------------------
-- Enumerate via CDM Data API (C_CooldownViewer.GetCooldownViewerCategorySet)
-- This queries the Blizzard data layer directly, not just visible icons.
----------------------------------------------------------------------
-- category: "Essential" or "Utility"
function CDViewer.EnumerateFromCDM(category)
    local tracked = {}

    -- Resolve Enum.CooldownViewerCategory
    local categoryEnum = Enum and Enum.CooldownViewerCategory or nil
    if not categoryEnum then return tracked end

    local catValue
    if category == "Essential" then
        catValue = categoryEnum.Essential
    elseif category == "Utility" then
        catValue = categoryEnum.Utility
    else
        return tracked
    end

    if not catValue then return tracked end

    if not (C_CooldownViewer
        and type(C_CooldownViewer.GetCooldownViewerCategorySet) == "function"
        and type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function") then
        return tracked
    end

    local okIDs, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, catValue, true)
    if not okIDs or type(ids) ~= "table" then return tracked end

    for i = 1, #ids do
        local cid = ids[i]
        if not IsValueSecret(cid) then
            local okInfo, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
            if okInfo and type(info) == "table" then
                local spellID = NormPublicSpellID(info.spellID)
                if spellID then
                    local spellName, spellIcon = ResolveSpellDisplay(spellID, nil)

                    tracked[spellID] = {
                        name = spellName,
                        icon = spellIcon,
                        category = category,
                        viewerName = (category == "Essential" and "EssentialCooldownViewer" or "UtilityCooldownViewer"),
                        isBuffTimer = false,
                        linkedSpellIDs = CollectLinkedIDs(info),
                        cooldownID = cid,
                    }
                end
            end
        end
    end

    return tracked
end

----------------------------------------------------------------------
-- Enumerate ALL: merges viewer frame pool + CDM data layer
----------------------------------------------------------------------
function CDViewer.EnumerateAll()
    local all = {}

    -- 1. Frame pool scan (all categories)
    local fromViewers = CDViewer.EnumerateTracked(nil, false)
    for spellID, entry in pairs(fromViewers) do
        all[spellID] = entry
    end

    -- 2. CDM data layer for Essential and Utility
    for _, cat in ipairs({ "Essential", "Utility" }) do
        local fromCDM = CDViewer.EnumerateFromCDM(cat)
        for spellID, entry in pairs(fromCDM) do
            if not all[spellID] then
                all[spellID] = entry
            end
        end
    end

    return all
end

----------------------------------------------------------------------
-- Global exports
----------------------------------------------------------------------
_G.M33kAuraUtils.IsBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.IsCooldownViewerBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.EnumerateTracked = CDViewer.EnumerateTracked
_G.M33kAuraUtils.EnumerateFromCDM = CDViewer.EnumerateFromCDM
_G.M33kAuraUtils.EnumerateAll = CDViewer.EnumerateAll

----------------------------------------------------------------------
-- Engine wrapper for lifecycle events and callback subscriptions
----------------------------------------------------------------------
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
