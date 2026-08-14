local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.L = {
    ["ADDON_NAME"] = "M33kAuraUtils",
    ["READY"] = "READY",
    ["ON_COOLDOWN"] = "ON COOLDOWN",
    ["CHARGES"] = "Charges",
    ["COOLDOWN_MANAGER"] = "Blizzard Cooldown Manager",
    ["ENABLE_CM_TRACKING"] = "Enable Cooldown Manager Tracking",
    ["ENABLE_CM_TRACKING_DESC"] = "Synchronizes spell cooldowns, charges, and buffs directly with Blizzard's native Cooldown Manager engine.",
    ["TRACK_CHARGES"] = "Track Spell Charges",
    ["TRACK_CHARGES_DESC"] = "Displays current and maximum spell charges.",
    ["SHOW_WHEN_READY"] = "Show When Ready",
    ["SHOW_WHEN_COOLDOWN"] = "Show On Cooldown",
    ["INCLUDE_GCD"] = "Include Global Cooldown (GCD)",
    ["FRAME_LOCKED"] = "M33kAuraUtils: Frame locked.",
    ["FRAME_UNLOCKED"] = "M33kAuraUtils: Frame unlocked. Drag to reposition.",
    ["FRAME_RESET"] = "M33kAuraUtils: Frame position reset.",
}
