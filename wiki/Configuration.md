# Configuration Guide

M33kAuraUtils offers customizable display options, positioning, and color settings stored in `M33kAuraUtilsDB`.

---

## Repositioning & Sizing

### Unlocking the Frame
To move the frame on your screen:
1. Type `/m33k lock` in chat to unlock the frame.
2. A highlighted overlay appears. Click and drag the frame to your desired screen position.
3. Type `/m33k lock` again to lock the position.

### Resetting Position
If the frame is lost or placed off-screen:
```text
/m33k reset
```
This resets the frame anchor back to `CENTER`, `X=0`, `Y=-150`.

### Toggling Visibility
To quickly show or hide the visual frame:
```text
/m33k toggle
```

---

## SavedVariables Schema (`M33kAuraUtilsDB`)

The addon settings are stored in your `WTF/Account/<AccountName>/SavedVariables/M33kAuraUtils.lua`:

```lua
M33kAuraUtilsDB = {
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
            inside = { r = 0.2, g = 0.9, b = 0.2, a = 1.0 },   -- Green (Optimal)
            outside = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 },  -- Red (Warning)
            expired = { r = 0.5, g = 0.5, b = 0.5, a = 0.4 },  -- Dimmed
        },
        customSpells = {},
    }
}
```

---

## Customizing Colors via Lua

You can adjust RGBA values directly in the configuration file or programmatically via the API:

```lua
local M33K = _G.M33kAuraUtils or _G.M33K

-- Change inside color to cyan
M33K.db.colors.inside = { r = 0.0, g = 0.8, b = 1.0, a = 1.0 }

-- Change outside warning color to orange
M33K.db.colors.outside = { r = 1.0, g = 0.5, b = 0.0, a = 1.0 }
```
