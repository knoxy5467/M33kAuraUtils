# Developer API Reference

M33kAuraUtils exposes a public Lua API allowing other addons, UI suites, or WeakAuras/ThisWeeksAuras to hook into the dual-state ground tracking engine.

---

## Accessing the Namespace

The addon namespace is accessible via the global table `_G.M33kAuraUtils` or the shorthand alias `_G.M33K`:

```lua
local M33K = _G.M33kAuraUtils or _G.M33K
```

---

## State Constants

```lua
M33K.Engine.STATE_EXPIRED        -- 0: No active ground effect
M33K.Engine.STATE_ACTIVE_INSIDE   -- 1: Ground effect active, player is standing inside
M33K.Engine.STATE_ACTIVE_OUTSIDE  -- 2: Ground effect active, player is standing outside
```

---

## Querying State

### `M33K.Engine.GetActiveState()`
Returns current tracker status.

```lua
local state, remaining, duration, spellData = M33K.Engine.GetActiveState()
```

#### Returns:
- `state` *(number)*: One of `STATE_EXPIRED` (0), `STATE_ACTIVE_INSIDE` (1), or `STATE_ACTIVE_OUTSIDE` (2).
- `remaining` *(number)*: Seconds remaining on the ground effect (e.g. `8.4`).
- `duration` *(number)*: Total lifetime duration in seconds (e.g. `12`).
- `spellData` *(table or nil)*: Table containing `name`, `castSpellId`, `buffSpellId`, `icon`, etc.

---

## Callbacks & Event Subscription

### `M33K.Engine.RegisterCallback(name, callbackFunction)`
Registers a listener invoked whenever ground state or duration changes.

```lua
M33K.Engine.RegisterCallback("MyAddonListener", function(state, remaining, duration, spellData)
    if state == M33K.Engine.STATE_ACTIVE_OUTSIDE then
        print("[Warning] You stepped outside your " .. (spellData and spellData.name or "ground zone") .. "!")
    end
end)
```

### `M33K.Engine.UnregisterCallback(name)`
Unregisters a previously registered callback listener.

```lua
M33K.Engine.UnregisterCallback("MyAddonListener")
```

---

## Database API

### `M33K.Database.AddCustomSpell(castId, buffId, duration, name)`
Registers a custom ground spell to the user's active profile (`M33kAuraUtilsDB`).

```lua
M33K.Database.AddCustomSpell(12345, 54321, 15, "My Custom Ground Spell")
```

### `M33K.Database.RemoveCustomSpell(castId)`
Removes a registered custom spell by cast ID.

```lua
M33K.Database.RemoveCustomSpell(12345)
```

### `M33K.Database.GetSetting(key)` / `M33K.Database.SetSetting(key, value)`
Gets or sets persistent configuration settings in `M33kAuraUtilsDB`.

```lua
local isLocked = M33K.Database.GetSetting("locked")
M33K.Database.SetSetting("locked", true)
```

---

## Integrating with WeakAuras / ThisWeeksAuras

You can use M33kAuraUtils directly inside a WeakAura Trigger State Updater (TSU):

```lua
-- Trigger State Updater (TSU)
function(allstates, event, ...)
    local M33K = _G.M33kAuraUtils or _G.M33K
    if not M33K or not M33K.Engine then return false end

    local state, remaining, duration, spellData = M33K.Engine.GetActiveState()

    allstates[""] = {
        show = remaining > 0,
        changed = true,
        progressType = "timed",
        duration = duration or 10,
        expirationTime = GetTime() + remaining,
        inside = (state == M33K.Engine.STATE_ACTIVE_INSIDE),
        name = spellData and spellData.name or "",
        icon = spellData and spellData.icon or 135926,
    }

    return true
end
```
