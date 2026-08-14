# Developer API Reference

GroundAuraTracker exposes a public Lua API allowing other addons, UI suites, or WeakAuras/ThisWeeksAuras to hook into the dual-state ground tracking engine.

---

## Accessing the Namespace

The addon namespace is accessible via the global `GroundAuraTracker` or through addon initialization:

```lua
local GAT = GroundAuraTracker
```

---

## State Constants

```lua
GAT.Engine.STATE_EXPIRED        -- 0: No active ground effect
GAT.Engine.STATE_ACTIVE_INSIDE   -- 1: Ground effect active, player is standing inside
GAT.Engine.STATE_ACTIVE_OUTSIDE  -- 2: Ground effect active, player is standing outside
```

---

## Querying State

### `GAT.Engine.GetActiveState()`
Returns current tracker status.

```lua
local state, remaining, duration, spellData = GAT.Engine.GetActiveState()
```

#### Returns:
- `state` *(number)*: One of `STATE_EXPIRED`, `STATE_ACTIVE_INSIDE`, or `STATE_ACTIVE_OUTSIDE`.
- `remaining` *(number)*: Seconds remaining on the ground effect (e.g. `8.4`).
- `duration` *(number)*: Total lifetime duration in seconds (e.g. `12`).
- `spellData` *(table or nil)*: Table containing `name`, `castSpellId`, `buffSpellId`, `icon`, etc.

---

## Callbacks & Event Subscription

### `GAT.Engine.RegisterCallback(name, callbackFunction)`
Registers a listener invoked whenever ground state or duration changes.

```lua
GAT.Engine.RegisterCallback("MyAddonListener", function(state, remaining, duration, spellData)
    if state == GAT.Engine.STATE_ACTIVE_OUTSIDE then
        print("[Warning] You stepped outside your " .. (spellData and spellData.name or "ground zone") .. "!")
    end
end)
```

### `GAT.Engine.UnregisterCallback(name)`
Unregisters a previously registered callback listener.

```lua
GAT.Engine.UnregisterCallback("MyAddonListener")
```

---

## Integrating with WeakAuras / ThisWeeksAuras

You can use GroundAuraTracker directly inside a WeakAura Trigger State Updater (TSU):

```lua
-- Trigger State Updater (TSU)
function(allstates, event, ...)
    if not GroundAuraTracker then return false end

    local state, remaining, duration, spellData = GroundAuraTracker.Engine.GetActiveState()

    allstates[""] = {
        show = remaining > 0,
        changed = true,
        progressType = "timed",
        duration = duration or 12,
        expirationTime = GetTime() + remaining,
        inside = (state == GroundAuraTracker.Engine.STATE_ACTIVE_INSIDE),
        name = spellData and spellData.name or "",
        icon = spellData and spellData.icon or 135926,
    }

    return true
end
```
