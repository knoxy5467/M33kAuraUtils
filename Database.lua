local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Database = {}
local Database = M33K.Database

local defaultSettings = {
    profile = {
        debug = false,
        version = "1.0.0",
    }
}

function Database.Initialize()
    if not _G.M33kAuraUtilsDB then
        _G.M33kAuraUtilsDB = {}
    end

    for k, v in pairs(defaultSettings.profile) do
        if _G.M33kAuraUtilsDB[k] == nil then
            _G.M33kAuraUtilsDB[k] = v
        end
    end

    M33K.db = _G.M33kAuraUtilsDB
    return M33K.db
end

function Database.GetSetting(key)
    if not M33K.db then Database.Initialize() end
    return M33K.db[key]
end

function Database.SetSetting(key, value)
    if not M33K.db then Database.Initialize() end
    M33K.db[key] = value
end
