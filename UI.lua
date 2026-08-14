local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.UI = {}
local UI = M33K.UI

local mainFrame = nil
local iconTexture = nil
local timerText = nil
local statusBar = nil
local statusText = nil
local dragOverlay = nil

function UI.CreateMainFrame()
    if mainFrame then return mainFrame end

    local db = M33K.db or M33K.Database.DefaultSettings.profile
    local size = db.size or 50

    -- Main Container
    mainFrame = CreateFrame("Frame", "M33kAuraUtilsMainFrame", UIParent)
    mainFrame:SetSize(size, size)
    mainFrame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.posX or 0, db.posY or -150)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(not db.locked)
    mainFrame:RegisterForDrag("LeftButton")

    -- Drag Handlers
    mainFrame:SetScript("OnDragStart", function(self)
        if not (M33K.db and M33K.db.locked) then
            self:StartMoving()
        end
    end)

    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, posX, posY = self:GetPoint()
        if M33K.db then
            M33K.db.point = point
            M33K.db.posX = posX
            M33K.db.posY = posY
        end
    end)

    -- Icon Texture
    iconTexture = mainFrame:CreateTexture(nil, "BACKGROUND")
    iconTexture:SetAllPoints(mainFrame)
    iconTexture:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")

    -- Progress Bar
    statusBar = CreateFrame("StatusBar", nil, mainFrame)
    statusBar:SetSize(size, 6)
    statusBar:SetPoint("TOP", mainFrame, "BOTTOM", 0, -2)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(1)
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    -- Timer Text
    timerText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    timerText:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)

    -- In/Out Status Text
    statusText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", statusBar, "BOTTOM", 0, -12)

    -- Drag Overlay (visible when unlocked)
    dragOverlay = mainFrame:CreateTexture(nil, "HIGHLIGHT")
    dragOverlay:SetAllPoints(mainFrame)
    dragOverlay:SetColorTexture(0, 0.8, 1, 0.3)

    -- OnUpdate ticker for timer countdown
    mainFrame:SetScript("OnUpdate", function(self, elapsed)
        UI.OnUpdate()
    end)

    -- Subscribe to Engine callbacks
    M33K.Engine.RegisterCallback("UI_Update", function(state, remaining, duration, spellData)
        UI.UpdateVisuals(state, remaining, duration, spellData)
    end)

    UI.UpdateVisuals(M33K.Engine.STATE_EXPIRED, 0, 0, nil)
    return mainFrame
end

function UI.UpdateVisuals(state, remaining, duration, spellData)
    if not mainFrame then return end
    local db = M33K.db or M33K.Database.DefaultSettings.profile
    local colors = db.colors or M33K.Database.DefaultSettings.profile.colors
    if spellData and spellData.icon then
        iconTexture:SetTexture(spellData.icon)
    end

    if state == M33K.Engine.STATE_ACTIVE_INSIDE then
        mainFrame:SetAlpha(1.0)
        local c = colors.inside
        iconTexture:SetVertexColor(c.r, c.g, c.b, c.a)
        statusBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        timerText:SetTextColor(c.r, c.g, c.b, 1)
        statusText:SetText(M33K.L["INSIDE_ZONE"])
        statusText:SetTextColor(c.r, c.g, c.b, 1)

    elseif state == M33K.Engine.STATE_ACTIVE_OUTSIDE then
        mainFrame:SetAlpha(1.0)
        local c = colors.outside
        iconTexture:SetVertexColor(c.r, c.g, c.b, c.a)
        statusBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        timerText:SetTextColor(c.r, c.g, c.b, 1)
        statusText:SetText(M33K.L["OUTSIDE_ZONE"])
        statusText:SetTextColor(c.r, c.g, c.b, 1)

    else
        -- EXPIRED
        local c = colors.expired
        iconTexture:SetVertexColor(c.r, c.g, c.b, c.a)
        statusBar:SetValue(0)
        timerText:SetText("")
        statusText:SetText("")
        if not (db and not db.locked) then
            mainFrame:SetAlpha(0.2)
        else
            mainFrame:SetAlpha(0.7)
        end
    end
end

function UI.OnUpdate()
    local state, remaining, duration, spellData = M33K.Engine.GetActiveState()
    if remaining > 0 and duration > 0 then
        timerText:SetText(string.format("%.1f", remaining))
        statusBar:SetValue(remaining / duration)
    elseif state == M33K.Engine.STATE_EXPIRED then
        timerText:SetText("")
        statusBar:SetValue(0)
    end
end

function UI.SetLocked(locked)
    if M33K.db then
        M33K.db.locked = locked
    end
    if mainFrame then
        mainFrame:EnableMouse(not locked)
        if locked then
            print(M33K.L["FRAME_LOCKED"])
        else
            print(M33K.L["FRAME_UNLOCKED"])
        end
    end
end

function UI.ResetPosition()
    M33K.Database.ResetPosition()
    if mainFrame and M33K.db then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(M33K.db.point, UIParent, M33K.db.point, M33K.db.posX, M33K.db.posY)
        print(M33K.L["FRAME_RESET"])
    end
end

