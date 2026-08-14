local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Engine = {}
local Engine = M33K.Engine

Engine.STATE_EXPIRED = 0
Engine.STATE_ACTIVE_INSIDE = 1
Engine.STATE_ACTIVE_OUTSIDE = 2

local callbacks = {}
local activeSpell = nil
local groundExpirationTime = 0
local groundDuration = 0
local isStandingInside = false
local currentState = Engine.STATE_EXPIRED
local playerGUID = nil
local playerClass = nil

function Engine.RegisterCallback(name, func)
    callbacks[name] = func
end

function Engine.UnregisterCallback(name)
    callbacks[name] = nil
end

local function FireCallbacks(state, remaining, duration, spellData)
    for _, func in pairs(callbacks) do
        pcall(func, state, remaining, duration, spellData)
    end
end

function Engine.GetActiveState()
    local now = (GetTime and GetTime()) or 0
    local remaining = math.max(0, groundExpirationTime - now)
    local state = Engine.STATE_EXPIRED

    if remaining > 0 then
        if isStandingInside then
            state = Engine.STATE_ACTIVE_INSIDE
        else
            state = Engine.STATE_ACTIVE_OUTSIDE
        end
    end

    return state, remaining, groundDuration, activeSpell
end

function Engine.EvaluateState()
    local oldState = currentState
    local newState, remaining, duration, spellData = Engine.GetActiveState()

    currentState = newState
    if oldState ~= newState or remaining > 0 then
        FireCallbacks(newState, remaining, duration, spellData)
    end
    return newState
end

function Engine.OnSpellCastSuccess(sourceGUID, spellId)
    if sourceGUID ~= playerGUID then return end

    local customSpells = M33K.db and M33K.db.customSpells
    local spellData = M33K.Spells.GetSpellByCastId(spellId, customSpells)

    if spellData then
        local now = (GetTime and GetTime()) or 0
        activeSpell = spellData
        groundDuration = spellData.defaultDuration or 10
        groundExpirationTime = now + groundDuration

        -- Check immediate aura presence
        if spellData.buffSpellId then
            local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID(spellData.buffSpellId)
            isStandingInside = (aura ~= nil)
        else
            -- If no specific buff spell, player is inside by default when casting
            isStandingInside = true
        end

        Engine.EvaluateState()
    end
end

function Engine.OnUnitAura(unit)
    if unit ~= "player" then return end
    if not activeSpell or not activeSpell.buffSpellId then return end

    local aura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID(activeSpell.buffSpellId)
    local wasInside = isStandingInside
    isStandingInside = (aura ~= nil)

    if wasInside ~= isStandingInside then
        Engine.EvaluateState()
    end
end

function Engine.Reset()
    activeSpell = nil
    groundExpirationTime = 0
    groundDuration = 0
    isStandingInside = false
    currentState = Engine.STATE_EXPIRED
    Engine.EvaluateState()
end

function Engine.Initialize()
    if UnitGUID then
        playerGUID = UnitGUID("player")
    end
    if UnitClass then
        local _, classFilename = UnitClass("player")
        playerClass = classFilename
    end
    Engine.Reset()
end

-- Export internals for test harness
Engine._SetPlayerGUID = function(guid) playerGUID = guid end
Engine._SetPlayerClass = function(cls) playerClass = cls end
Engine._SetStandingInside = function(val) isStandingInside = val end
Engine._SetExpiration = function(exp, dur, spell)
    groundExpirationTime = exp
    groundDuration = dur
    activeSpell = spell
end
