local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Spells = {}
local Spells = M33K.Spells

-- Spell information & cooldown manager utility helpers
function Spells.GetSpellInfo(spellIdentifier)
    if not spellIdentifier then return nil end
    local spellId = tonumber(spellIdentifier)

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId or spellIdentifier)
        if info then
            return {
                id = info.spellID,
                name = info.name,
                icon = info.iconID,
                castTime = info.castTime,
                minRange = info.minRange,
                maxRange = info.maxRange,
            }
        end
    elseif GetSpellInfo then
        local name, _, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellId or spellIdentifier)
        if name then
            return {
                id = id or spellId,
                name = name,
                icon = icon,
                castTime = castTime,
                minRange = minRange,
                maxRange = maxRange,
            }
        end
    end

    return {
        id = tonumber(spellIdentifier) or 0,
        name = tostring(spellIdentifier),
        icon = 136243, -- Default generic icon
    }
end

function Spells.GetCooldown(spellIdentifier)
    local spellId = tonumber(spellIdentifier)
    if not spellId then
        local info = Spells.GetSpellInfo(spellIdentifier)
        spellId = info and info.id
    end
    if not spellId then return 0, 0, false end

    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spellId)
        if cd then
            return cd.startTime or 0, cd.duration or 0, cd.isEnabled or true, cd.modRate or 1.0
        end
    elseif GetSpellCooldown then
        local start, duration, enabled, modRate = GetSpellCooldown(spellId)
        return start or 0, duration or 0, enabled == 1, modRate or 1.0
    end

    return 0, 0, false
end

function Spells.GetCharges(spellIdentifier)
    local spellId = tonumber(spellIdentifier)
    if not spellId then
        local info = Spells.GetSpellInfo(spellIdentifier)
        spellId = info and info.id
    end
    if not spellId then return 0, 0, 0, 0 end

    if C_Spell and C_Spell.GetSpellCharges then
        local charges = C_Spell.GetSpellCharges(spellId)
        if charges then
            return charges.currentCharges or 0, charges.maxCharges or 0, charges.cooldownStartTime or 0, charges.cooldownDuration or 0
        end
    elseif GetSpellCharges then
        local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spellId)
        if currentCharges then
            return currentCharges, maxCharges, cooldownStart, cooldownDuration
        end
    end

    return 0, 0, 0, 0
end

function Spells.IsUsable(spellIdentifier)
    local spellId = tonumber(spellIdentifier)
    if not spellId then
        local info = Spells.GetSpellInfo(spellIdentifier)
        spellId = info and info.id
    end
    if not spellId then return false, false end

    if C_Spell and C_Spell.IsSpellUsable then
        local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellId)
        return isUsable, notEnoughMana
    elseif IsUsableSpell then
        local isUsable, notEnoughMana = IsUsableSpell(spellId)
        return isUsable, notEnoughMana
    end

    return true, false
end
