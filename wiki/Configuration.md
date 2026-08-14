# Configuration Guide

GroundAuraTracker offers customizable display options, positioning, and color settings stored in `GroundAuraTrackerDB`.

---

## Repositioning & Sizing

### Unlocking the Frame
To move the frame on your screen:
1. Type `/gat lock` in chat to unlock the frame.
2. A highlighted overlay appears. Click and drag the frame to your desired screen position.
3. Type `/gat lock` again to lock the position.

### Resetting Position
If the frame is lost or placed off-screen:
```text
/gat reset
```
This resets the frame anchor back to `CENTER`, `X=0`, `Y=-150`.

---

## SavedVariables Schema (`GroundAuraTrackerDB`)

The addon settings are stored in your `WTF/Account/<AccountName>/SavedVariables/GroundAuraTracker.lua`:

```lua
GroundAuraTrackerDB = {
    profile = {
        enabled = true,
        locked = true,
        size = 50,
        posX = 0,
        posY = -150,
        point = "CENTER",
        showProgressBar = true,
        showText = true,
        colors = {
            inside = { r = 0.2, g = 0.9, b = 0.2, a = 1.0 },   -- Green
            outside = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 },  -- Red warning
            expired = { r = 0.5, g = 0.5, b = 0.5, a = 0.4 },  -- Dimmed
        },
        customSpells = {},
    }
}
```

---

## Customizing Colors

You can adjust RGBA values directly in the configuration file or via the API:

```lua
-- Change inside color to cyan
GAT.db.colors.inside = { r = 0.0, g = 0.8, b = 1.0, a = 1.0 }

-- Change outside warning color to orange
GAT.db.colors.outside = { r = 1.0, g = 0.5, b = 0.0, a = 1.0 }
```
