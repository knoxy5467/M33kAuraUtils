local Harness = require("tests.test_harness")
Harness.SetupEnvironment()

-- Initialize fresh addon state
_G.GroundAuraTrackerDB = nil
local GAT = {}
Harness.LoadFullAddon(GAT)
GAT.Database.Initialize()
GAT.Engine.Initialize()
local mainFrame = GAT.UI.CreateMainFrame()

Harness.BeginSuite("UI Components & Visual Handlers Tests")

Harness.RunTest("1. UI.CreateMainFrame constructs frame hierarchy properly", function()
    Harness.Assert(mainFrame ~= nil, "Main frame should be created")
    local w, h = mainFrame:GetSize()
    Harness.AssertEquals(w, 50, "Frame width should be default size 50")
    Harness.AssertEquals(h, 50, "Frame height should be default size 50")
    Harness.Assert(mainFrame:IsShown(), "Main frame should be shown initially")
end)

Harness.RunTest("2. UI.UpdateVisuals applies INSIDE (Green) styling", function()
    local spellData = { name = "Consecration", icon = 135926 }
    GAT.UI.UpdateVisuals(GAT.Engine.STATE_ACTIVE_INSIDE, 10.0, 12.0, spellData)

    Harness.AssertEquals(mainFrame:GetAlpha(), 1.0, "Active frame alpha should be 1.0")

    -- Inspect font strings and textures
    local statusFS = mainFrame._fontStrings[2]
    Harness.Assert(statusFS ~= nil, "Status font string should exist")
    Harness.AssertEquals(statusFS:GetText(), GAT.L["INSIDE_ZONE"], "Status text should be INSIDE")

    local r, g, b, a = statusFS:GetTextColor()
    Harness.AssertEquals(r, 0.2, "Inside text color R should be 0.2")
    Harness.AssertEquals(g, 0.9, "Inside text color G should be 0.9")
end)

Harness.RunTest("3. UI.UpdateVisuals applies OUTSIDE (Red Alert) styling", function()
    local spellData = { name = "Consecration", icon = 135926 }
    GAT.UI.UpdateVisuals(GAT.Engine.STATE_ACTIVE_OUTSIDE, 7.5, 12.0, spellData)

    Harness.AssertEquals(mainFrame:GetAlpha(), 1.0, "Active frame alpha should be 1.0")

    local statusFS = mainFrame._fontStrings[2]
    Harness.AssertEquals(statusFS:GetText(), GAT.L["OUTSIDE_ZONE"], "Status text should be OUTSIDE")

    local r, g, b, a = statusFS:GetTextColor()
    Harness.AssertEquals(r, 1.0, "Outside text color R should be 1.0")
    Harness.AssertEquals(g, 0.2, "Outside text color G should be 0.2")
end)

Harness.RunTest("4. UI.UpdateVisuals applies EXPIRED (Dimmed) styling", function()
    GAT.UI.UpdateVisuals(GAT.Engine.STATE_EXPIRED, 0, 0, nil)

    local statusFS = mainFrame._fontStrings[2]
    Harness.AssertEquals(statusFS:GetText(), "", "Status text should be empty on expire")

    local timerFS = mainFrame._fontStrings[1]
    Harness.AssertEquals(timerFS:GetText(), "", "Timer text should be empty on expire")
end)

Harness.RunTest("5. UI.OnUpdate updates countdown timer text and status bar fraction", function()
    -- Set active engine state
    Harness.SetTime(1000.0)
    GAT.Engine._SetExpiration(1008.5, 12.0, { name = "Consecration", icon = 135926 })
    GAT.Engine._SetStandingInside(true)

    GAT.UI.OnUpdate()

    local timerFS = mainFrame._fontStrings[1]
    Harness.AssertEquals(timerFS:GetText(), "8.5", "Timer string should format to '8.5'")
end)

Harness.RunTest("6. Drag handlers and Lock/Unlock toggling", function()
    -- Unlock frame
    GAT.UI.SetLocked(false)
    Harness.AssertEquals(GAT.db.locked, false, "DB locked should be false")

    -- Simulate drag start
    mainFrame:FireScript("OnDragStart")
    Harness.AssertEquals(mainFrame._isMoving, true, "Frame should be moving during drag")

    -- Simulate drag stop at new coordinates
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 120, -250)
    mainFrame:FireScript("OnDragStop")
    Harness.AssertEquals(mainFrame._isMoving, false, "Frame should stop moving on drag stop")
    Harness.AssertEquals(GAT.db.posX, 120, "DB posX should update to 120")
    Harness.AssertEquals(GAT.db.posY, -250, "DB posY should update to -250")

    -- Lock frame
    GAT.UI.SetLocked(true)
    Harness.AssertEquals(GAT.db.locked, true, "DB locked should be true")
    mainFrame:FireScript("OnDragStart")
    Harness.AssertEquals(mainFrame._isMoving, false, "Locked frame should not start moving")
end)

Harness.RunTest("7. Slash commands handle lock, reset, and toggle", function()
    -- Reset command
    GAT.Options.HandleSlashCommand("reset")
    Harness.AssertEquals(GAT.db.posX, 0, "Position X should be reset to 0")
    Harness.AssertEquals(GAT.db.posY, -150, "Position Y should be reset to -150")

    -- Lock toggle command
    GAT.db.locked = false
    GAT.Options.HandleSlashCommand("lock")
    Harness.AssertEquals(GAT.db.locked, true, "Slash lock should toggle locked state")

    -- Add custom spell command
    GAT.Options.HandleSlashCommand("add 7777 8888 14")
    local custom = GAT.Spells.GetSpellByCastId(7777, GAT.db.customSpells)
    Harness.Assert(custom ~= nil, "Custom spell 7777 should be added")
    Harness.AssertEquals(custom.buffSpellId, 8888, "Custom buff ID should be 8888")
    Harness.AssertEquals(custom.defaultDuration, 14, "Custom duration should be 14s")
end)
