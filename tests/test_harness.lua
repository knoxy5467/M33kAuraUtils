-- tests/test_harness.lua: Pure-Lua World of Warcraft Retail Mock Environment
local Harness = {}

local currentTime = 1000.0
local activeSuites = {}
local currentSuiteName = ""
local totalPassed = 0
local totalFailed = 0

-- Reset and mock WoW globals
function Harness.SetupEnvironment()
    _G._G = _G
    currentTime = 1000.0

    _G.GetTime = function()
        return currentTime
    end

    -- Mock C_Spell
    _G.C_Spell = {
        _spells = {},
        _charges = {},
        _cooldowns = {},
        GetSpellInfo = function(spellId)
            local id = tonumber(spellId)
            if _G.C_Spell._spells[id] then
                return _G.C_Spell._spells[id]
            end
            if id then
                return { spellID = id, name = "Spell " .. id, iconID = 136243 }
            end
            return nil
        end,
        GetSpellCharges = function(spellId)
            local id = tonumber(spellId)
            if _G.C_Spell._charges[id] then
                return _G.C_Spell._charges[id]
            end
            return nil
        end,
        GetSpellCooldown = function(spellId)
            local id = tonumber(spellId)
            if _G.C_Spell._cooldowns[id] then
                return _G.C_Spell._cooldowns[id]
            end
            return { startTime = 0, duration = 0, isEnabled = true, modRate = 1.0 }
        end,
        IsSpellUsable = function(spellId)
            return true, false
        end,
    }

    -- Mock Enum.CooldownViewerCategory
    _G.Enum = _G.Enum or {}
    _G.Enum.CooldownViewerCategory = {
        Essential = 1,
        Utility = 2,
        TrackedBuff = 3,
        TrackedBar = 4,
        Buff = 3,
        Bar = 4,
    }

    -- Mock C_CooldownViewer (with GetCooldownViewerCategorySet)
    _G.C_CooldownViewer = {
        _cooldowns = {},
        _categorySets = {
            [1] = {},  -- Essential
            [2] = {},  -- Utility
            [3] = {},  -- TrackedBuff
            [4] = {},  -- TrackedBar
        },
        GetCooldownViewerCooldownInfo = function(cid)
            return _G.C_CooldownViewer._cooldowns[cid]
        end,
        GetCooldownViewerCategorySet = function(category, includeAll)
            return _G.C_CooldownViewer._categorySets[category] or {}
        end,
    }

    -- Mock canaccessvalue (all values accessible in test)
    _G.canaccessvalue = function(val)
        return true
    end

    -- Helper to create a viewer with an itemFramePool
    local function CreateMockViewer(name)
        local viewer = {
            _name = name,
            _activeIcons = {},
            itemFramePool = {
                _icons = {},
                EnumerateActive = function(self)
                    local list = self._icons or {}
                    local i = 0
                    return function()
                        i = i + 1
                        return list[i]
                    end
                end,
            }
        }
        return viewer
    end

    _G.BuffIconCooldownViewer = CreateMockViewer("BuffIconCooldownViewer")
    _G.BuffBarCooldownViewer = CreateMockViewer("BuffBarCooldownViewer")
    _G.EssentialCooldownViewer = CreateMockViewer("EssentialCooldownViewer")
    _G.UtilityCooldownViewer = CreateMockViewer("UtilityCooldownViewer")

    -- Mock issecretvalue
    _G.issecretvalue = function(val)
        return false
    end

    -- Mock Frames
    _G.CreateFrame = function(frameType, name, parent)
        local frame = {
            _type = frameType,
            _name = name,
            _parent = parent,
            _shown = true,
            _scripts = {},
            _events = {},
            _points = {},
            _alpha = 1.0,
            _width = 0,
            _height = 0,
            _textures = {},
            _fontStrings = {},
            _statusBars = {},
        }
        function frame:Show() self._shown = true end
        function frame:Hide() self._shown = false end
        function frame:IsShown() return self._shown end
        function frame:SetAlpha(a) self._alpha = a end
        function frame:GetAlpha() return self._alpha end
        function frame:SetSize(w, h) self._width = w; self._height = h end
        function frame:GetSize() return self._width, self._height end
        function frame:SetWidth(w) self._width = w end
        function frame:SetHeight(h) self._height = h end
        function frame:SetPoint(point, relativeTo, relativePoint, x, y)
            table.insert(self._points, { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x or 0, y = y or 0 })
        end
        function frame:ClearAllPoints() self._points = {} end
        function frame:SetScript(handler, fn) self._scripts[handler] = fn end
        function frame:GetScript(handler) return self._scripts[handler] end
        function frame:FireScript(handler, ...)
            if self._scripts[handler] then return self._scripts[handler](self, ...) end
        end
        function frame:RegisterEvent(event) self._events[event] = true end
        function frame:UnregisterEvent(event) self._events[event] = nil end
        function frame:SetMovable(val) self._movable = val end
        function frame:EnableMouse(val) self._mouse = val end
        function frame:RegisterForDrag(...) self._dragButtons = { ... } end
        function frame:StartMoving() self._isMoving = true end
        function frame:StopMovingOrSizing() self._isMoving = false end
        function frame:CreateTexture(texName, layer)
            local tex = {
                _name = texName,
                _layer = layer,
                _texture = "",
                _vertexColor = { 1, 1, 1, 1 },
                SetAllPoints = function(t, p) end,
                SetTexture = function(t, path) t._texture = path end,
                GetTexture = function(t) return t._texture end,
                SetVertexColor = function(t, r, g, b, a) t._vertexColor = { r, g, b, a or 1 } end,
                GetVertexColor = function(t) return unpack(t._vertexColor) end,
                SetTexCoord = function(t, ...) end,
            }
            table.insert(self._textures, tex)
            return tex
        end
        function frame:CreateFontString(fsName, layer)
            local fs = {
                _name = fsName,
                _text = "",
                _color = { 1, 1, 1, 1 },
                SetFont = function() end,
                SetText = function(s, text) s._text = text end,
                GetText = function(s) return s._text end,
                SetTextColor = function(s, r, g, b, a) s._color = { r, g, b, a or 1 } end,
                GetTextColor = function(s) return unpack(s._color) end,
                SetPoint = function() end,
                SetShadowOffset = function() end,
            }
            table.insert(self._fontStrings, fs)
            return fs
        end
        return frame
    end

    _G.UIParent = _G.CreateFrame("Frame", "UIParent")

    -- Helper to create mock Aura Framework (M33kAuras / ThisWeeksAuras / WeakAuras)
    local function CreateMockAuraFramework(name)
        local fw
        fw = {
            _name = name,
            _auras = {},
            _states = {},
            _registeredOptions = {},
            doubleWidth = 2,
            normalWidth = 1,
            Add = function(data)
                fw._auras[data.id] = data
            end,
            GetTriggerStateForTrigger = function(auraId, triggernum)
                fw._states[auraId] = fw._states[auraId] or {}
                fw._states[auraId][triggernum] = fw._states[auraId][triggernum] or {}
                return fw._states[auraId][triggernum]
            end,
            UpdatedTriggerState = function(auraId)
                fw._lastUpdatedAura = auraId
            end,
            ClearAndUpdateOptions = function(auraId)
                fw._optionsCleared = auraId
            end,
            RegisterTriggerSystemOptions = function(systemTypes, func)
                table.insert(fw._registeredOptions, { types = systemTypes, fn = func })
            end,
        }
        return fw
    end

    _G.ThisWeeksAuras = CreateMockAuraFramework("ThisWeeksAuras")
    _G.M33kAuras = CreateMockAuraFramework("M33kAuras")
    _G.WeakAuras = CreateMockAuraFramework("WeakAuras")

    _G.OptionsPrivate = {
        GetBuffTriggerOptions = function(data, triggernum)
            return {
                ["trigger." .. triggernum .. ".aura_options"] = {
                    unit = { type = "select", name = "Unit" },
                }
            }
        end,
        GetSpellTriggerOptions = function(data, triggernum)
            return {
                ["trigger." .. triggernum .. ".spell_options"] = {
                    spellName = { type = "input", name = "Spell" },
                }
            }
        end,
    }
end

function Harness.SetTime(t)
    currentTime = t
end

function Harness.AdvanceTime(dt)
    currentTime = currentTime + dt
end

-- Test execution & assertions
function Harness.BeginSuite(name)
    currentSuiteName = name
    print(string.format("\n=== Running Suite: %s ===", name))
end

function Harness.RunTest(testName, testFunc)
    local ok, err = pcall(testFunc)
    if ok then
        totalPassed = totalPassed + 1
        print(string.format("  [PASS] %s", testName))
    else
        totalFailed = totalFailed + 1
        print(string.format("  [FAIL] %s: %s", testName, tostring(err)))
    end
end

function Harness.Assert(condition, message)
    if not condition then
        error(message or "Assertion failed!", 2)
    end
end

function Harness.AssertEquals(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (Expected %s, got %s)", message or "Values not equal", tostring(expected), tostring(actual)), 2)
    end
end

function Harness.GetSummary()
    return totalPassed, totalFailed
end

function Harness.LoadFullAddon(M33K)
    M33K = M33K or {}
    _G.M33kAuraUtils = M33K
    dofile("Locales/Locales.lua")
    dofile("Spells.lua")
    dofile("Database.lua")
    dofile("Engine.lua")
    dofile("UI.lua")
    dofile("Options.lua")
    dofile("Injection.lua")
    dofile("IntegTest.lua")
    dofile("Core.lua")
    return M33K
end

return Harness
