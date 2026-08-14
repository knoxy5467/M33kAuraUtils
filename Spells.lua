local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Spells = {}
local Spells = M33K.Spells

-- Built-in ground / in-zone spell definitions
Spells.DefaultDatabase = {
    -- Paladin: Consecration
    [26573] = {
        name = "Consecration",
        castSpellId = 26573,
        buffSpellId = 188370,
        defaultDuration = 12,
        class = "PALADIN",
        icon = 135926,
    },
    -- Death Knight: Death and Decay
    [43265] = {
        name = "Death and Decay",
        castSpellId = 43265,
        buffSpellId = 188290,
        defaultDuration = 10,
        class = "DEATHKNIGHT",
        icon = 136140,
    },
    -- Death Knight: Defile (Talent replacement for D&D)
    [152280] = {
        name = "Defile",
        castSpellId = 152280,
        buffSpellId = 391459,
        defaultDuration = 10,
        class = "DEATHKNIGHT",
        icon = 136145,
    },
    -- Druid: Efflorescence
    [145205] = {
        name = "Efflorescence",
        castSpellId = 145205,
        buffSpellId = 145205,
        defaultDuration = 30,
        class = "DRUID",
        icon = 134405,
    },
    -- Shaman: Healing Rain
    [73920] = {
        name = "Healing Rain",
        castSpellId = 73920,
        buffSpellId = 73920,
        defaultDuration = 10,
        class = "SHAMAN",
        icon = 136037,
    },
    -- Demon Hunter: Sigil of Flame
    [204596] = {
        name = "Sigil of Flame",
        castSpellId = 204596,
        buffSpellId = nil, -- ground ticking zone
        defaultDuration = 6,
        class = "DEMONHUNTER",
        icon = 1033479,
    },
}

function Spells.GetSpellForClass(playerClass)
    local results = {}
    for spellId, data in pairs(Spells.DefaultDatabase) do
        if not data.class or data.class == playerClass then
            results[spellId] = data
        end
    end
    return results
end

function Spells.GetSpellByCastId(castSpellId, customSpells)
    if customSpells and customSpells[castSpellId] then
        return customSpells[castSpellId]
    end
    return Spells.DefaultDatabase[castSpellId]
end

function Spells.GetSpellByBuffId(buffSpellId, customSpells)
    if customSpells then
        for _, data in pairs(customSpells) do
            if data.buffSpellId == buffSpellId then
                return data
            end
        end
    end
    for _, data in pairs(Spells.DefaultDatabase) do
        if data.buffSpellId == buffSpellId then
            return data
        end
    end
    return nil
end
