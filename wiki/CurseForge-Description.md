# M33kAuraUtils — CurseForge Listing Content

## 1. Project Summary (For CurseForge "Summary" Field)
> Real-time dual-state ground zone duration and in-zone aura tracker for World of Warcraft retail, with WeakAuras integration and custom spell support.

---

## 2. Full Project Description (For CurseForge "Description" Field)

```markdown
# M33kAuraUtils

**M33kAuraUtils** is a lightweight, zero-dependency combat utility for World of Warcraft (Retail) that tracks ground-placed spells and zone auras with real-time **dual-state awareness**. 

Standard unit aura tracking fails for ground-targeted spells because the player buff only exists while physically standing inside the area of effect. If you step out, traditional auras disappear entirely—even if your zone has 10 seconds remaining. 

**M33kAuraUtils bridges this gap** by monitoring both the ground effect's remaining lifetime and your player presence inside the zone.

---

### ✨ Key Features

* **Dual-State Tracking:** Simultaneously tracks the remaining ground duration (from spell cast) and your active buff state (standing inside vs. outside).
* **Smart Visual Feedback:**
  * 🟢 **Active & Standing Inside:** Full color with real-time countdown timer.
  * 🔴 **Active but Outside (Alert):** Distinct high-contrast warning with countdown to step back in.
  * ⚪ **Expired / Inactive:** Dimmed or hidden display when no active ground zone exists.
* **Movable & Configurable UI:** Clean display frame with custom sizing, positioning, status bar, and timer text.
* **Custom Spell Registration:** Add any custom ground-placed spell or talent proc directly via slash commands without modifying code.
* **Cross-Addon Injection & WeakAuras Support:** Seamlessly integrates with **ThisWeeksAuras** and **WeakAuras**, adding native ground tracking toggles directly to standard aura triggers.
* **Ultra Lightweight & High Performance:** Zero external library dependencies (no LibSharedMedia or heavy framework overhead); pure native WoW API execution.

---

### 🛡️ Supported Spells (Built-in Presets)

M33kAuraUtils includes out-of-the-box support for:

| Class | Ground Spell | Buff Effect | Default Duration |
| :--- | :--- | :--- | :--- |
| **Paladin** | Consecration (*Spell 26573*) | Consecration (*Buff 188370*) | 12.0s |
| **Death Knight** | Death and Decay (*Spell 43265*) | Death and Decay (*Buff 188290*) | 10.0s |
| **Death Knight** | Defile (*Spell 152280*) | Defile (*Buff 391459*) | 10.0s |
| **Druid** | Efflorescence (*Spell 145205*) | Efflorescence (*Buff 145205*) | 30.0s |
| **Shaman** | Healing Rain (*Spell 73920*) | Healing Rain (*Buff 73920*) | 10.0s |
| **Demon Hunter** | Sigil of Flame (*Spell 204596*) | Sigil of Flame (*Buff 204596*) | 6.0s |

---

### ⌨️ Slash Commands

Use `/m33k`, `/m33kaura`, or `/m33kaurautils` in-game to configure:

* `/m33k lock` — Toggle locking/unlocking the UI frame for dragging and repositioning.
* `/m33k reset` — Reset frame position to default center coordinates.
* `/m33k toggle` — Toggle the visual tracker frame visibility on/off.
* `/m33k add <castSpellId> <buffSpellId> [duration]` — Register a custom ground spell.
* `/m33k remove <castSpellId>` — Remove a registered custom ground spell.

---

### ⚙️ Installation

1. Install via the **CurseForge App** (recommended) or manually extract into your `World of Warcraft\_retail_\Interface\AddOns\` directory.
2. Ensure `M33kAuraUtils` is enabled in your AddOn list at character selection.
3. Log in and position the tracker where you prefer using `/m33k lock`.

---

### 🔗 Links & Community

* **Source Code & Issue Tracker:** [GitHub Repository](https://github.com/knoxy5467/M33kAuraUtils)
* **Report Bugs & Suggest Features:** [GitHub Issues](https://github.com/knoxy5467/M33kAuraUtils/issues)
```
