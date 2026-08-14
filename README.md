# GroundAuraTracker (GAT)

[![CI & Secret Testing](https://github.com/example/GroundAuraTracker/actions/workflows/ci.yml/badge.svg)](https://github.com/example/GroundAuraTracker/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Interface: 12.x / 11.x](https://img.shields.io/badge/WoW_Retail-12.01.00-blue.svg)](https://worldofwarcraft.blizzard.com/)

**GroundAuraTracker** is a standalone, lightweight World of Warcraft retail addon designed to solve the **ground-placed aura problem**.

Standard aura trackers fail for ground-targeted spells like *Consecration*, *Death and Decay*, and *Efflorescence* because the buff only appears while standing inside the zone—causing the tracker to disappear if you step out even while the zone is still active on the ground.

GroundAuraTracker implements a **Dual-State Engine**:
1. **Ground Zone Duration:** Tracks total remaining ground lifetime via `COMBAT_LOG_EVENT_UNFILTERED` (`SPELL_CAST_SUCCESS`).
2. **In-Zone Buff Detection:** Tracks whether the player is currently standing inside or outside the effect via `UNIT_AURA`.

---

## Features

- 🌟 **Zero Dependencies:** Pure standalone addon; does not require WeakAuras, Ace3, or any external libraries.
- 🎯 **Dual-State Visual Feedback:**
  - **INSIDE (Green):** Normal color, progress countdown, optimal mastery/DR benefits active.
  - **OUTSIDE (Red Alert):** Warning tint & text notifying you to step back into your active zone.
  - **EXPIRED:** Dimmed / reset state.
- 🧙‍♂️ **Multi-Class Support:** Pre-configured out of the box for:
  - **Paladin:** Consecration (26573)
  - **Death Knight:** Death and Decay (43265) & Defile (152280)
  - **Druid:** Efflorescence (145205)
  - **Shaman:** Healing Rain (73920)
  - **Demon Hunter:** Sigil of Flame (204596)
  - **Custom Spells:** Add any custom ground spell via slash command or settings.
- 🎛️ **Customizable & Movable:** Drag-and-drop frame positioning, resizable icon, toggleable progress bar, and configurable colors.
- 🧪 **Complete Test Suite & CI:** Comprehensive pure-Lua unit tests, local test runner, and GitHub Actions CI workflow.

---

## Installation

### Manual Installation
1. Download or clone this repository.
2. Place the `GroundAuraTracker` folder into your WoW AddOns directory:
   ```text
   World of Warcraft\_retail_\Interface\AddOns\GroundAuraTracker
   ```
3. Restart or reload World of Warcraft (`/reload`).

---

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/gat` or `/groundaura` | Shows help menu and available commands |
| `/gat lock` | Toggles locking/unlocking the frame for dragging |
| `/gat reset` | Resets the frame position to screen center |
| `/gat toggle` | Shows or hides the display frame |
| `/gat add <castId> <buffId> [sec]` | Registers a new custom ground spell |

---

## Local Development & Testing

You can run the full test suite and validation scripts locally before pushing:

### Windows Batch / PowerShell
```powershell
# Using the Lua runner directly
lua scripts/run_tests.lua

# Or using the convenience scripts
.\scripts\test.bat
# or
.\scripts\test.ps1
```

### GitHub Actions CI
On every push and pull request, GitHub Actions executes:
- TOC file structure verification
- Lua syntax validation across all source files
- Dual-state engine unit test suite (`tests/test_engine.lua`)
- Database and profile unit test suite (`tests/test_database.lua`)
- Secret access and log redaction security verification (`tests/test_secret_access.lua`)

---

## Documentation & Wiki

For detailed documentation, visit the [Wiki](wiki/Home.md):
- [Architecture & State Machine](wiki/Architecture.md)
- [Configuration Guide](wiki/Configuration.md)
- [Supported Spells & Custom Spells](wiki/Supported-Spells.md)
- [Developer API Reference](wiki/API-Reference.md)

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on code style, test requirements, and pull request procedures.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
