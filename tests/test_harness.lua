-- test_harness.lua: Complete pure-Lua WoW API Simulator
local Harness = {}

-- Virtual Clock
local mockTime = 1000.0
function Harness.SetTime(t) mockTime = t end
function Harness.AdvanceTime(delta) mockTime = mockTime + delta end
function Harness.GetTime() return mockTime end

-- Mock Player State
local mockPlayerGUID = "Player-1234-00ABCD"
local mockPlayerClass = "PALADIN"
local mockPlayerAuras = {}
local lastCombatLogEvent = nil

function Harness.SetPlayerGUID(guid) mockPlayerGUID = guid end
function Harness.SetPlayerClass(cls) mockPlayerClass = cls end

function Harness.ApplyPlayerAura(spellId, name)
    mockPlayerAuras[spellId] = {
        name = name or "Aura-" .. spellId,
        spellId = spellId,
        icon = 135926,
    }
end

function Harness.RemovePlayerAura(spellId)
    mockPlayerAuras[spellId] = nil
end

function Harness.ClearPlayerAuras()
    mockPlayerAuras = {}
end

function Harness.TriggerCombatLog(subEvent, sourceGUID, spellId)
    lastCombatLogEvent = {
        timestamp = mockTime,
        subEvent = subEvent,
        hideCaster = false,
        sourceGUID = sourceGUID,
        sourceName = "TestPlayer",
        sourceFlags = 0x511,
        sourceRaidFlags = 0,
        destGUID = "",
        destName = "",
        destFlags = 0,
        destRaidFlags = 0,
        spellId = spellId,
        spellName = "Spell-" .. spellId,
        spellSchool = 1,
    }
end

-- Global WoW Environment Setup
function Harness.SetupEnvironment()
    _G.GetTime = Harness.GetTime
    _G.UnitGUID = function(unit) if unit == "player" then return mockPlayerGUID end return nil end
    _G.UnitClass = function(unit) if unit == "player" then return "Paladin", mockPlayerClass end return nil end
    
    _G.C_UnitAuras = {
        GetPlayerAuraBySpellID = function(spellId)
            return mockPlayerAuras[spellId]
        end
    }

    _G.C_Spell = {
        GetSpellInfo = function(spellId)
            return {
                name = "Spell-" .. spellId,
                iconID = 135926,
                castTime = 0,
                minRange = 0,
                maxRange = 0,
                spellID = spellId,
            }
        end
    }

    _G.CombatLogGetCurrentEventInfo = function()
        if not lastCombatLogEvent then return nil end
        local e = lastCombatLogEvent
        return e.timestamp, e.subEvent, e.hideCaster, e.sourceGUID, e.sourceName,
               e.sourceFlags, e.sourceRaidFlags, e.destGUID, e.destName, e.destFlags,
               e.destRaidFlags, e.spellId, e.spellName, e.spellSchool
    end

    _G.UIParent = {}

    -- Mock Frame creation
    _G.CreateFrame = function(frameType, name, parent)
        local frame = {
            _type = frameType,
            _name = name,
            _parent = parent,
            _shown = true,
            _alpha = 1.0,
            _scripts = {},
            _events = {},
            _points = {},
            _width = 50,
            _height = 50,
            _mouse = true,
        }

        function frame:SetSize(w, h) self._width = w; self._height = h end
        function frame:SetPoint(p, parent, relPoint, x, y)
            self._points = { point = p, relParent = parent, relPoint = relPoint, x = x, y = y }
        end
        function frame:GetPoint()
            local p = self._points
            return p.point or "CENTER", p.relParent or UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0
        end
        function frame:ClearAllPoints() self._points = {} end
        function frame:SetMovable(val) self._movable = val end
        function frame:EnableMouse(val) self._mouse = val end
        function frame:RegisterForDrag(...) end
        function frame:StartMoving() end
        function frame:StopMovingOrSizing() end
        function frame:SetAlpha(a) self._alpha = a end
        function frame:Show() self._shown = true end
        function frame:Hide() self._shown = false end
        function frame:IsShown() return self._shown end
        function frame:SetScript(handler, func) self._scripts[handler] = func end
        function frame:GetScript(handler) return self._scripts[handler] end
        function frame:RegisterEvent(event) self._events[event] = true end
        function frame:UnregisterEvent(event) self._events[event] = nil end

        function frame:CreateTexture(name, layer)
            local tex = { _texture = "", _color = {1,1,1,1} }
            function tex:SetAllPoints(parent) end
            function tex:SetTexture(t) self._texture = t end
            function tex:SetColorTexture(r, g, b, a) self._color = {r, g, b, a} end
            function tex:SetVertexColor(r, g, b, a) self._vertexColor = {r, g, b, a} end
            return tex
        end

        function frame:CreateFontString(name, layer, font)
            local fs = { _text = "", _color = {1,1,1,1} }
            function fs:SetPoint(...) end
            function fs:SetText(t) self._text = t end
            function fs:GetText() return self._text end
            function fs:SetTextColor(r, g, b, a) self._color = {r, g, b, a} end
            return fs
        end

        if frameType == "StatusBar" then
            frame._min = 0
            frame._max = 1
            frame._val = 1
            function frame:SetMinMaxValues(min, max) self._min = min; self._max = max end
            function frame:SetValue(v) self._val = v end
            function frame:SetStatusBarTexture(t) end
            function frame:SetStatusBarColor(r, g, b, a) self._statusBarColor = {r, g, b, a} end
        end

        return frame
    end
end

-- Test Assertions & Runner
local passedTests = 0
local failedTests = 0
local suiteName = "Default"

function Harness.BeginSuite(name)
    suiteName = name
    print(string.format("\n=== Running Suite: %s ===", name))
end

function Harness.Assert(condition, message)
    if condition then
        passedTests = passedTests + 1
    else
        failedTests = failedTests + 1
        print(string.format("  [FAIL] %s: %s", suiteName, message or "Assertion failed"))
        error(message or "Assertion failed", 2)
    end
end

function Harness.AssertEquals(actual, expected, message)
    if actual == expected then
        passedTests = passedTests + 1
    else
        failedTests = failedTests + 1
        local msg = string.format("%s (Expected %s, got %s)", message or "Values not equal", tostring(expected), tostring(actual))
        print(string.format("  [FAIL] %s: %s", suiteName, msg))
        error(msg, 2)
    end
end

function Harness.RunTest(testName, testFunc)
    local ok, err = pcall(testFunc)
    if ok then
        print(string.format("  [PASS] %s", testName))
    else
        print(string.format("  [FAIL] %s: %s", testName, tostring(err)))
    end
end

function Harness.GetSummary()
    return passedTests, failedTests
end

return Harness
