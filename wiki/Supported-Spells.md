# Supported Spells & Custom Spells

GroundAuraTracker supports built-in presets for popular ground spells and allows dynamic custom spell registration.

---

## Built-In Spells

| Class | Spell Name | Cast Spell ID | In-Zone Buff ID | Default Duration |
| :--- | :--- | :--- | :--- | :--- |
| **Paladin** | Consecration | `26573` | `188370` | 12s |
| **Death Knight** | Death and Decay | `43265` | `188290` | 10s |
| **Death Knight** | Defile | `152280` | `391459` | 10s |
| **Druid** | Efflorescence | `145205` | `145205` | 30s |
| **Shaman** | Healing Rain | `73920` | `73920` | 10s |
| **Demon Hunter** | Sigil of Flame | `204596` | *(Ground Ticking)* | 6s |

---

## Adding Custom Spells

You can add any custom ground-placed spell via slash command or directly in Lua.

### Via Slash Command
```text
/gat add <castSpellId> <buffSpellId> [durationInSeconds]
```

#### Example: Adding a custom ground buff
```text
/gat add 12345 54321 15
```
- `12345`: The Spell ID in your spellbook that you cast on the ground.
- `54321`: The Spell ID of the buff you get while standing in it.
- `15`: Ground duration in seconds.

### Via Lua API
```lua
-- In any custom script or addon:
local GAT = GroundAuraTracker
if GAT and GAT.Database then
    GAT.Database.AddCustomSpell(12345, 54321, 15, "My Custom Spell")
end
```
