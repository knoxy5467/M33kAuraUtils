local AddonName, M33K = ...
M33K = M33K or _G.M33kAuraUtils or {}
_G.M33kAuraUtils = M33K

M33K.Database = {}
local Database = M33K.Database

Database.DefaultSettings = {
    profile = {
        enabled = true,
        locked = false,
        size = 50,
        posX = 0,
        posY = -150,
        point = "CENTER",
        showProgressBar = true,
        showText = true,
        soundOnStepOut = true,
        soundOnExpire = false,
        colors = {
            inside = { r = 0.2, g = 0.9, b = 0.2, a = 1.0 },       -- Green (Optimal)
            outside = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 },      -- Red (Warning: Out of zone)
            expired = { r = 0.5, g = 0.5, b = 0.5, a = 0.4 },      -- Dimmed
        },
        customSpells = {},
    }
}

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then return src end
    if type(dst) ~= "table" then dst = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function Database.Initialize()
    if not M33kAuraUtilsDB then
        M33kAuraUtilsDB = {}
    end
    M33kAuraUtilsDB = CopyDefaults(Database.DefaultSettings, M33kAuraUtilsDB)
    M33K.db = M33kAuraUtilsDB.profile
    return M33K.db
end

function Database.GetSetting(key)
    if M33K.db and M33K.db[key] ~= nil then
        return M33K.db[key]
    end
    return Database.DefaultSettings.profile[key]
end

function Database.SetSetting(key, value)
    if not M33K.db then
        Database.Initialize()
    end
    M33K.db[key] = value
end

function Database.ResetPosition()
    if M33K.db then
        M33K.db.posX = Database.DefaultSettings.profile.posX
        M33K.db.posY = Database.DefaultSettings.profile.posY
        M33K.db.point = Database.DefaultSettings.profile.point
    end
end

function Database.AddCustomSpell(castId, buffId, duration, name)
    if not M33K.db then Database.Initialize() end
    M33K.db.customSpells[castId] = {
        name = name or ("Custom Spell (" .. castId .. ")"),
        castSpellId = castId,
        buffSpellId = buffId,
        defaultDuration = duration or 10,
        class = nil,
    }
end

function Database.RemoveCustomSpell(castId)
    if M33K.db and M33K.db.customSpells then
        M33K.db.customSpells[castId] = nil
    end
end

