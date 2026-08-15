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

-- Extract icon texture from Blizzard CDM icon frame.
-- Full cascade: frame widget → iconTexture → cooldown info → spell API.
local function ResolveIconTexture(icon)
    if not icon then return nil end

    -- 1. Frame texture widget (most common CDM layout)
    local iconWidget = icon.Icon or icon.icon
    if iconWidget and type(iconWidget.GetTexture) == "function" then
        local tex = iconWidget:GetTexture()
        if tex and tex ~= 0 then return tex end
    end

    -- 2. Direct texture fields on the frame
    if icon.iconTexture and icon.iconTexture ~= 0 then return icon.iconTexture end
    if icon.texture     and icon.texture     ~= 0 then return icon.texture     end

    -- 3. CDM cooldown info
    local info = ResolveIconInfo(icon)
    if info and info.icon and info.icon ~= 0 then return info.icon end

    -- 4. Spell API fallback
    local spellID = NormPublicSpellID(icon.spellID)
    if spellID then
        if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
            local ok, si = pcall(C_Spell.GetSpellInfo, spellID)
            if ok and si and si.iconID and si.iconID > 0 then return si.iconID end
        end
        if type(GetSpellTexture) == "function" then
            local tex = GetSpellTexture(spellID)
            if tex then return tex end
        end
        if M33K.Spells and M33K.Spells.GetSpellInfo then
            local si = M33K.Spells.GetSpellInfo(spellID)
            if si and si.icon then return si.icon end
        end
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
-- Exclusively queries Blizzard Cooldown Manager (BuffIconCooldownViewer, BuffBarCooldownViewer, etc.)
-- Returns: active, expirationTime, duration, iconTexture, stacks, matchedSpellID, spellName
----------------------------------------------------------------------
function CDViewer.IsBuffActive(targetSpells)
    local TARGET_SPELLS = NormalizeTargetSpells(targetSpells)

    -- Blizzard Cooldown Viewer check ONLY (Strictly CDM data)
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
                        if M33K.Debug then
                            M33K.Debug("ENGINE", "IsBuffActive MATCH", {
                                viewer = viewerName,
                                spellID = icon.spellID,
                                matchedID = matchedID,
                                name = name,
                                exp = exp,
                                dur = dur,
                                stacks = stacks,
                                icon = iconTexture,
                            })
                        end
                        return true, exp, dur, iconTexture, stacks, matchedID, name
                    end
                end
            end
        end
    end

    if M33K.Debug then
        M33K.Debug("ENGINE", "IsBuffActive NO_MATCH", { targetSpells = targetSpells })
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
-- Spell Usability: Evaluates if a spell is usable considering CDM state, cooldowns & resources
-- Returns: isUsable, notEnoughPower, onCooldown, startTime, duration, expirationTime, charges, maxCharges, icon, matchedID, name
----------------------------------------------------------------------
function CDViewer.IsSpellUsable(targetSpells, ignoreGCD)
    local TARGET_SPELLS = NormalizeTargetSpells(targetSpells)

    for spellID in pairs(TARGET_SPELLS) do
        if type(spellID) == "number" then
            local name, icon = ResolveSpellDisplay(spellID, nil)

            -- 1. Check native spell usability (power / resource check)
            local isUsable, notEnoughPower = true, false
            if C_Spell and C_Spell.IsSpellUsable then
                isUsable, notEnoughPower = C_Spell.IsSpellUsable(spellID)
            elseif IsUsableSpell then
                isUsable, notEnoughPower = IsUsableSpell(spellID)
            end

            -- 2. Check charges
            local charges, maxCharges, chargeStart, chargeDur = 0, 0, 0, 0
            if M33K.Spells and M33K.Spells.GetCharges then
                charges, maxCharges, chargeStart, chargeDur = M33K.Spells.GetCharges(spellID)
            end

            -- 3. Check cooldown & GCD
            local cdStart, cdDur, cdEnabled, modRate = 0, 0, true, 1.0
            if M33K.Spells and M33K.Spells.GetCooldown then
                cdStart, cdDur, cdEnabled, modRate = M33K.Spells.GetCooldown(spellID)
            end

            -- 4. Check Blizzard CDM viewer icon state if available
            for _, viewerName in ipairs({ "EssentialCooldownViewer", "UtilityCooldownViewer" }) do
                local viewer = _G[viewerName]
                if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
                    for item in viewer.itemFramePool:EnumerateActive() do
                        if item and (not item.IsShown or item:IsShown()) then
                            local info = ResolveIconInfo(item)
                            local rawID = NormPublicSpellID(item.spellID)
                            local isMatch = (rawID == spellID)
                                         or (info and (info.spellID == spellID or info.overrideSpellID == spellID))

                            if isMatch then
                                if item.ChargeCount and item.ChargeCount.Current then
                                    local c = tonumber(item.ChargeCount.Current)
                                    if c and c > 0 then charges = c end
                                end
                                if item.cooldownDuration and item.cooldownDuration > 0 then
                                    cdDur = item.cooldownDuration
                                    cdStart = (item.cooldownExpirationTime or 0) - cdDur
                                end
                                break
                            end
                        end
                    end
                end
            end

            -- Evaluate ready state
            local now = GetTime and GetTime() or 0
            local exp = (cdStart > 0 and cdDur > 0) and (cdStart + cdDur) or 0
            local rem = (exp > now) and (exp - now) or 0

            local isOnGCD = (cdDur > 0 and cdDur <= 1.5 and rem > 0)
            local onRealCooldown = (rem > 0) and (not isOnGCD or not ignoreGCD)

            local ready = (not onRealCooldown) or (maxCharges > 0 and charges > 0)
            local fullyUsable = isUsable and ready and not notEnoughPower

            return fullyUsable, notEnoughPower, onRealCooldown, cdStart, cdDur, exp, charges, maxCharges, icon, spellID, name
        end
    end

    return false, false, false, 0, 0, 0, 0, 0, nil, nil, nil
end

----------------------------------------------------------------------
-- Spell Cooldown State: Evaluates cooldown progress for spell triggers
-- Returns: onCooldown, startTime, duration, expirationTime, charges, maxCharges, isEnabled, icon, matchedID, name
----------------------------------------------------------------------
function CDViewer.GetSpellCooldownState(targetSpells, ignoreGCD)
    local usable, notEnoughPower, onCooldown, start, dur, exp, charges, maxCharges, icon, spellID, name = CDViewer.IsSpellUsable(targetSpells, ignoreGCD)
    return onCooldown, start, dur, exp, charges, maxCharges, true, icon, spellID, name
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
-- Resolve icon for a set of target spells from CDM data + spell API.
-- Does NOT require a live viewer frame — safe to call when inactive.
-- Returns a valid texture FileID/path, or 136243 (generic spell icon).
----------------------------------------------------------------------
function CDViewer.ResolveIconForSpells(targetSpells)
    local TARGET_SPELLS = NormalizeTargetSpells(targetSpells)

    -- 1. Try live CDM viewer frames first (most accurate)
    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
            for icon in viewer.itemFramePool:EnumerateActive() do
                if icon then
                    local rawID = NormPublicSpellID(icon.spellID)
                    if rawID and TARGET_SPELLS[rawID] then
                        local tex = ResolveIconTexture(icon)
                        if tex then return tex end
                    end
                end
            end
        end
    end

    -- 2. Try CDM data layer
    if C_CooldownViewer and type(C_CooldownViewer.GetCooldownViewerCooldownIDs) == "function" then
        local allIDs = {}
        for _, cat in ipairs({ 1, 2, 3, 4 }) do
            local ids = {}
            if type(C_CooldownViewer.GetCooldownViewerCooldownIDsInCategory) == "function" then
                ids = C_CooldownViewer.GetCooldownViewerCooldownIDsInCategory(cat) or {}
            end
            for _, cid in ipairs(ids) do
                table.insert(allIDs, cid)
            end
        end
        for _, cid in ipairs(allIDs) do
            if type(C_CooldownViewer.GetCooldownViewerCooldownInfo) == "function" then
                local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cid)
                if ok and info then
                    local sid = NormPublicSpellID(info.spellID)
                    if sid and TARGET_SPELLS[sid] and info.icon then
                        if M33K.Debug then
                            M33K.Debug("ICON", "ResolveIconForSpells MATCH_CDM_DATA", { spellID = sid, icon = info.icon })
                        end
                        return info.icon
                    end
                end
            end
        end
    end

    -- 3. Spell API fallback for each target spell ID
    for spellID in pairs(TARGET_SPELLS) do
        if type(spellID) == "number" and spellID > 0 then
            -- C_Spell.GetSpellInfo (retail)
            if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
                local ok, si = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and si and si.iconID and si.iconID > 0 then
                    if M33K.Debug then
                        M33K.Debug("ICON", "ResolveIconForSpells MATCH_C_SPELL", { spellID = spellID, icon = si.iconID })
                    end
                    return si.iconID
                end
            end
            -- GetSpellTexture global (classic/compat)
            if type(GetSpellTexture) == "function" then
                local tex = GetSpellTexture(spellID)
                if tex then
                    if M33K.Debug then
                        M33K.Debug("ICON", "ResolveIconForSpells MATCH_GET_SPELL_TEXTURE", { spellID = spellID, icon = tex })
                    end
                    return tex
                end
            end
            -- M33K.Spells lookup
            if M33K.Spells and M33K.Spells.GetSpellInfo then
                local si = M33K.Spells.GetSpellInfo(spellID)
                if si and si.icon then
                    if M33K.Debug then
                        M33K.Debug("ICON", "ResolveIconForSpells MATCH_M33K_SPELLS", { spellID = spellID, icon = si.icon })
                    end
                    return si.icon
                end
            end
        end
    end

    if M33K.Debug then
        M33K.Debug("ICON", "ResolveIconForSpells FALLBACK_DEFAULT", { targetSpells = targetSpells, icon = 136243 })
    end
    return 136243  -- generic fallback
end

----------------------------------------------------------------------
-- Global exports
----------------------------------------------------------------------
_G.M33kAuraUtils.IsBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.IsCooldownViewerBuffActive = CDViewer.IsBuffActive
_G.M33kAuraUtils.IsSpellUsable = CDViewer.IsSpellUsable
_G.M33kAuraUtils.GetSpellCooldownState = CDViewer.GetSpellCooldownState
_G.M33kAuraUtils.EnumerateTracked = CDViewer.EnumerateTracked
_G.M33kAuraUtils.EnumerateFromCDM = CDViewer.EnumerateFromCDM
_G.M33kAuraUtils.EnumerateTrackedBuffsAndBars = CDViewer.EnumerateTrackedBuffsAndBars
_G.M33kAuraUtils.EnumerateCooldowns = CDViewer.EnumerateCooldowns
_G.M33kAuraUtils.EnumerateAll = CDViewer.EnumerateAll
_G.M33kAuraUtils.GetCDMSpellInfo = CDViewer.GetCDMSpellInfo
_G.M33kAuraUtils.ResolveIconForSpells = CDViewer.ResolveIconForSpells

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

function Engine.CheckSpellUsable(targetSpells, ignoreGCD)
    return CDViewer.IsSpellUsable(targetSpells, ignoreGCD)
end
