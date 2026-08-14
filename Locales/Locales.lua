local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
})

local L = M33K.L

-- English localization (default)
L["ADDON_TITLE"] = "M33k Aura Utils"
L["SLASH_HELP_HEADER"] = "M33kAuraUtils Commands:"
L["SLASH_HELP_TOGGLE"] = "  /m33k toggle - Toggle frame display"
L["SLASH_HELP_LOCK"] = "  /m33k lock - Lock or unlock the frame for dragging"
L["SLASH_HELP_RESET"] = "  /m33k reset - Reset frame position to center"
L["SLASH_HELP_CONFIG"] = "  /m33k config - Open settings panel"
L["FRAME_UNLOCKED"] = "M33kAuraUtils: Frame unlocked. Drag to reposition."
L["FRAME_LOCKED"] = "M33kAuraUtils: Frame locked."
L["FRAME_RESET"] = "M33kAuraUtils: Frame position reset."
L["INSIDE_ZONE"] = "INSIDE"
L["OUTSIDE_ZONE"] = "OUTSIDE"
L["EXPIRED_ZONE"] = "EXPIRED"

