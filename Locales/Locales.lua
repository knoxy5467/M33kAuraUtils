local AddonName, GAT = ...
GAT = GAT or _G.GroundAuraTracker or {}
_G.GroundAuraTracker = GAT

GAT.L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
})

local L = GAT.L

-- English localization (default)
L["ADDON_TITLE"] = "Ground Aura Tracker"
L["SLASH_HELP_HEADER"] = "GroundAuraTracker Commands:"
L["SLASH_HELP_TOGGLE"] = "  /gat toggle - Toggle frame display"
L["SLASH_HELP_LOCK"] = "  /gat lock - Lock or unlock the frame for dragging"
L["SLASH_HELP_RESET"] = "  /gat reset - Reset frame position to center"
L["SLASH_HELP_CONFIG"] = "  /gat config - Open settings panel"
L["FRAME_UNLOCKED"] = "GroundAuraTracker: Frame unlocked. Drag to reposition."
L["FRAME_LOCKED"] = "GroundAuraTracker: Frame locked."
L["FRAME_RESET"] = "GroundAuraTracker: Frame position reset."
L["INSIDE_ZONE"] = "INSIDE"
L["OUTSIDE_ZONE"] = "OUTSIDE"
L["EXPIRED_ZONE"] = "EXPIRED"
