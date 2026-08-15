local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.CooldownViewer = {}
local CDViewer = M33K.CooldownViewer

-- Standard Blizzard Cooldown Viewers
local VIEWERS = {
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

-- Viewer name → category label
local VIEWER_CATEGORY = {
    BuffIconCooldownViewer  = "TrackedBuff",
    BuffBarCooldownViewer   = "TrackedBar",
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

-- Extract stacks/charges from a Blizzard CDM icon frame
local function ResolveIconStacks(icon)
    local stacks = 0
    if icon then
        if icon.Applications and icon.Applications.Applications then
            local val = tonumber(icon.Applications.Applications)
            if val and val > 0 then stacks = val end
        end
        if stacks == 0 and icon.ChargeCount and icon.ChargeCount.Current then
            local val = tonumber(icon.ChargeCount.Current)
            if val and val > 0 then stacks = val end
        end
        if stacks == 0 then
            local info = icon.cooldownInfo
            if info then
                if type(info.charges) == "number" and info.charges > 0 then
                    stacks = info.charges
                elseif type(info.applications) == "number" and info.applications > 0 then
                    stacks = info.applications
                end
            end
        end
    end
    return stacks
end

-- Extract icon texture from Blizzard CDM icon
local function ResolveIconTexture(icon)
    if not icon then return nil end
    local iconTexture = icon.Icon or icon.icon
    if iconTexture and type(iconTexture.GetTexture) == "function" then
        return iconTexture:GetTexture()
    end
    return nil
end

-- Resolve spell name and icon texture for a given spellID
local function ResolveSpellDisplay(spellID, iconFrame)
    local spellName, spellIcon

    if M33K.Spells and M33K.Spells.GetSpellInfo then
        local si = M33K.Spells.GetSpellInfo(spellID)
        spellName = si and si.name
        spellIcon = si and si.icon
    end

    if not spellIcon and iconFrame then
        spellIcon = ResolveIconTexture(iconFrame)
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

-- Check if cooldown flags hide the aura
local function IsAuraHiddenByFlags(info)
    if not info or type(info.flags) ~= "number" then return false end
    local flagsEnum = Enum and Enum.CooldownSetSpellFlags
    if flagsEnum and flagsEnum.HideAura and bit and bit.band then
        return bit.band(info.flags, flagsEnum.HideAura) ~= 0
    end
    return false
end

----------------------------------------------------------------------
-- Core: IsBuffActive (trigger/untrigger logic)
-- Returns: active, expirationTime, duration, iconTexture, stacks, matchedSpellID, spellName
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
                    local stacks = aura.applications or aura.charges or 0
                    local name = aura.name or (M33K.Spells and M33K.Spells.GetSpellInfo(spellID) and M33K.Spells.GetSpellInfo(spellID).name) or "Buff"
                    return true, exp, dur, ic, stacks, spellID, name
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
                    local matchedID = nil
                    if rawID and TARGET_SPELLS[rawID] then
                        matchedID = rawID
                    elseif info then
                        if TARGET_SPELLS[info.spellID] then matchedID = info.spellID
                        elseif TARGET_SPELLS[info.overrideSpellID] then matchedID = info.overrideSpellID
                        elseif TARGET_SPELLS[info.overrideTooltipSpellID] then matchedID = info.overrideTooltipSpellID
                        end
                    end

                    if not matchedID and info and type(info.linkedSpellIDs) == "table" then
                        for _, id in ipairs(info.linkedSpellIDs) do
                            if TARGET_SPELLS[id] then
                                matchedID = id
                                break
                            end
                        end
                    end

                    if matchedID then
                        local exp = icon.cooldownExpirationTime or (info and info.cooldownExpirationTime) or 0
                        local dur = icon.cooldownDuration or (info and info.cooldownDuration) or 0
                        local iconTexture = ResolveIconTexture(icon)
                        local stacks = ResolveIconStacks(icon)
                        local name = (M33K.Spells and M33K.Spells.GetSpellInfo(matchedID) and M33K.Spells.GetSpellInfo(matchedID).name) or ("Spell " .. matchedID)
                        return true, exp, dur, iconTexture, stacks, matchedID, name
                    end
                end
            end
        end
    end

    return false, 0, 0, nil, 0, nil, nil
end

----------------------------------------------------------------------
-- Enumerate: Scan viewer frame pools (live icons on screen)
----------------------------------------------------------------------
function CDViewer.EnumerateTracked(categoryFilter, buffsOnly)
    local tracked = {}

    for _, viewerName in ipairs(VIEWERS) do
        local cat = VIEWER_CATEGORY[viewerName]

        if not categoryFilter or cat == categoryFilter then
            local viewer = _G[viewerName]
            if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
                for icon in viewer.itemFramePool:EnumerateActive() do
                    if icon and (not icon.IsShown or icon:IsShown()) then
                        local isBuffTimer = (icon.cooldownUseAuraDisplayTime == true)

                        if not buffsOnly or isBuffTimer then
                            local info = ResolveIconInfo(icon)
                            local spellID = NormPublicSpellID(icon.spellID)
                                         or (info and NormPublicSpellID(info.spellID))

                            if spellID and (not info or info.isKnown ~= false) then
                                local spellName, spellIcon = ResolveSpellDisplay(spellID, icon)
                                local exp = icon.cooldownExpirationTime or (info and info.cooldownExpirationTime) or 0
                                local dur = icon.cooldownDuration or (info and info.cooldownDuration) or 0
                                local stacks = ResolveIconStacks(icon)

                                tracked[spellID] = {
                                    name = spellName,
                                    icon = spellIcon,
                                    category = cat,
                                    viewerName = viewerName,
                                    isBuffTimer = isBuffTimer,
                                    linkedSpellIDs = CollectLinkedIDs(info),
                                    duration = dur,
                                    expirationTime = exp,
                                    stacks = stacks,
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
-- includeAll: boolean (false = only actively tracked/displayed, true = all known spells)
----------------------------------------------------------------------
function CDViewer.EnumerateFromCDM(category, includeAll)
    local tracked = {}
    local fetchAll = (includeAll == true)

    local categoryEnum = Enum and Enum.CooldownViewerCategory or nil
    if not categoryEnum then return tracked end

    local catValue
    if category == "Essential" then
        catValue = categoryEnum.Essential
    elseif category == "Utility" then
        catValue = categoryEnum.Utility
    elseif category == "TrackedBuff" or category == "Buff" then
        catValue = categoryEnum.TrackedBuff or categoryEnum.Buff or categoryEnum.TrackedBuffs
    elseif category == "TrackedBar" or category == "Bar" then
        catValue = categoryEnum.TrackedBar or categoryEnum.Bar or categoryEnum.TrackedBars
    end

    if not catValue then return tracked end

    -- Check CooldownViewerSettings DataProvider first if available
    local settings = _G.CooldownViewerSettings
    local dataProvider = settings and settings.GetDataProvider and settings:GetDataProvider()
    if dataProvider and dataProvider.GetOrderedCooldownIDsForCategory and dataProvider.GetCooldownInfoForID then
        local ids = dataProvider:GetOrderedCooldownIDsForCategory(catValue, fetchAll)
        if type(ids) == "table" then
            for _, cid in ipairs(ids) do
                if not IsValueSecret(cid) then
                    local info = dataProvider:GetCooldownInfoForID(cid)
                    if type(info) == "table" and (fetchAll or (info.isKnown ~= false and not IsAuraHiddenByFlags(info))) then
                        local spellID = NormPublicSpellID(info.spellID) or NormPublicSpellID(info.overrideSpellID)
                        if spellID then
                            local spellName, spellIcon = ResolveSpellDisplay(spellID, nil)
                            tracked[spellID] = {
                                name = spellName,
                                icon = spellIcon,
                                category = category,
                                viewerName = (category == "TrackedBuff" and "BuffIconCooldownViewer") or (category == "TrackedBar" and "BuffBarCooldownViewer") or (category == "Essential" and "EssentialCooldownViewer") or "UtilityCooldownViewer",
                                isBuffTimer = (category == "TrackedBuff" or category == "TrackedBar"),
                                linkedSpellIDs = CollectLinkedIDs(info),
                                cooldownID = cid,
                                duration = info.cooldownDuration or 0,
                                expirationTime = info.cooldownExpirationTime or 0,
                                stacks = info.charges or info.applications or 0,
                            }
                        end
                    end
                end
            end
            return tracked
        end
    end

    -- Standard C_CooldownViewer fallback
    if not (C_CooldownViewer
        and type(C_CooldownViewer.GetCooldownViewerCategorySet) == "function"
        and type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function") then
        return tracked
    end

    local okIDs, ids = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, catValue, fetchAll)
    if not okIDs or type(ids) ~= "table" then return tracked end

    local defaultViewer = "EssentialCooldownViewer"
    if category == "Utility" then defaultViewer = "UtilityCooldownViewer"
    elseif category == "TrackedBuff" or category == "Buff" then defaultViewer = "BuffIconCooldownViewer"
    elseif category == "TrackedBar" or category == "Bar" then defaultViewer = "BuffBarCooldownViewer"
    end

    for i = 1, #ids do
        local cid = ids[i]
        if not IsValueSecret(cid) then
            local okInfo, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
            if okInfo and type(info) == "table" and (fetchAll or (info.isKnown ~= false and not IsAuraHiddenByFlags(info))) then
                local spellID = NormPublicSpellID(info.spellID)
                             or NormPublicSpellID(info.overrideSpellID)

                if spellID then
                    local spellName, spellIcon = ResolveSpellDisplay(spellID, nil)
                    local dur = info.cooldownDuration or 0
                    local exp = info.cooldownExpirationTime or 0
                    local stacks = info.charges or info.applications or 0

                    tracked[spellID] = {
                        name = spellName,
                        icon = spellIcon,
                        category = category,
                        viewerName = defaultViewer,
                        isBuffTimer = (category == "TrackedBuff" or category == "Buff" or category == "TrackedBar" or category == "Bar"),
                        linkedSpellIDs = CollectLinkedIDs(info),
                        cooldownID = cid,
                        duration = dur,
                        expirationTime = exp,
                        stacks = stacks,
                    }
                end
            end
        end
    end

    return tracked
end

----------------------------------------------------------------------
-- Enumerate Tracked Buffs & Bars from CDM
-- includeAll: boolean (false = only actively tracked, true = all known buffs)
----------------------------------------------------------------------
function CDViewer.EnumerateTrackedBuffsAndBars(includeAll)
    local buffsAndBars = {}

    -- 1. CDM Data Layer for TrackedBuff and TrackedBar
    for _, cat in ipairs({ "TrackedBuff", "TrackedBar" }) do
        local fromCDM = CDViewer.EnumerateFromCDM(cat, includeAll)
        for spellID, entry in pairs(fromCDM) do
            buffsAndBars[spellID] = entry
        end
    end

    -- 2. Live viewer frames for BuffIconCooldownViewer & BuffBarCooldownViewer
    for _, cat in ipairs({ "TrackedBuff", "TrackedBar" }) do
        local fromViewer = CDViewer.EnumerateTracked(cat, false)
        for spellID, entry in pairs(fromViewer) do
            if not buffsAndBars[spellID] then
                buffsAndBars[spellID] = entry
            end
        end
    end

    return buffsAndBars
end

----------------------------------------------------------------------
-- Enumerate Cooldowns: merges Essential + Utility from CDM
-- includeAll: boolean (false = only actively tracked, true = all known cooldowns)
----------------------------------------------------------------------
function CDViewer.EnumerateCooldowns(includeAll)
    local cds = {}

    -- 1. CDM Data Layer for Essential and Utility
    for _, cat in ipairs({ "Essential", "Utility" }) do
        local fromCDM = CDViewer.EnumerateFromCDM(cat, includeAll)
        for spellID, entry in pairs(fromCDM) do
            cds[spellID] = entry
        end
    end

    -- 2. Live viewer frames for EssentialCooldownViewer & UtilityCooldownViewer
    for _, cat in ipairs({ "Essential", "Utility" }) do
        local fromViewer = CDViewer.EnumerateTracked(cat, false)
        for spellID, entry in pairs(fromViewer) do
            if not cds[spellID] then
                cds[spellID] = entry
            end
        end
    end

    return cds
end

----------------------------------------------------------------------
-- Enumerate ALL CDM entries (Buffs, Bars, Essential, Utility)
----------------------------------------------------------------------
function CDViewer.EnumerateAll()
    local all = {}

    local buffs = CDViewer.EnumerateTrackedBuffsAndBars()
    for spellID, entry in pairs(buffs) do
        all[spellID] = entry
    end

    local cds = CDViewer.EnumerateCooldowns()
    for spellID, entry in pairs(cds) do
        if not all[spellID] then
            all[spellID] = entry
        end
    end

    return all
end

----------------------------------------------------------------------
-- Query detailed spell information from CDM & C_Spell
----------------------------------------------------------------------
function CDViewer.GetCDMSpellInfo(spellIdentifier)
    local spellID = tonumber(spellIdentifier)
    if not spellID then return nil end

    local name, icon = ResolveSpellDisplay(spellID, nil)
    local charges, maxCharges, chargeStart, chargeDuration = 0, 0, 0, 0
    local cdStart, cdDuration, isEnabled = 0, 0, true

    if M33K.Spells then
        charges, maxCharges, chargeStart, chargeDuration = M33K.Spells.GetCharges(spellID)
        cdStart, cdDuration, isEnabled = M33K.Spells.GetCooldown(spellID)
    end

    return {
        spellID = spellID,
        name = name,
        icon = icon,
        charges = charges,
        maxCharges = maxCharges,
        chargeStart = chargeStart,
        chargeDuration = chargeDuration,
        cdStart = cdStart,
        cdDuration = cdDuration,
        isEnabled = isEnabled,
    }
end

----------------------------------------------------------------------
-- Global exports
----------------------------------------------------------------------
_G.M33kAuraUtils.IsBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.IsCooldownViewerBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.EnumerateTracked = CDViewer.EnumerateTracked
_G.M33kAuraUtils.EnumerateFromCDM = CDViewer.EnumerateFromCDM
_G.M33kAuraUtils.EnumerateTrackedBuffsAndBars = CDViewer.EnumerateTrackedBuffsAndBars
_G.M33kAuraUtils.EnumerateCooldowns = CDViewer.EnumerateCooldowns
_G.M33kAuraUtils.EnumerateAll = CDViewer.EnumerateAll
_G.M33kAuraUtils.GetCDMSpellInfo = CDViewer.GetCDMSpellInfo

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
