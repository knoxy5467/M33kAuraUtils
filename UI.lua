local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.UI = {}
local UI = M33K.UI

local mainFrame = nil

function UI.CreateMainFrame()
    if mainFrame then return mainFrame end
    if not CreateFrame then return nil end

    mainFrame = CreateFrame("Frame", "M33kAuraUtilsFrame", UIParent)
    mainFrame:SetSize(40, 40)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:Hide() -- Hidden by default, functions as background utility provider
    return mainFrame
end

function UI.GetMainFrame()
    return mainFrame
end
