# M33kAuraUtils (M33K)

[![CI & Secret Testing](https://github.com/example/M33kAuraUtils/actions/workflows/ci.yml/badge.svg)](https://github.com/example/M33kAuraUtils/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Interface: 12.x / 11.x](https://img.shields.io/badge/WoW_Retail-12.01.00-blue.svg)](https://worldofwarcraft.blizzard.com/)

**M33kAuraUtils** is a standalone, lightweight World of Warcraft retail addon designed to solve the **ground-placed aura problem**.

Standard aura trackers fail for ground-targeted spells like *Consecration*, *Death and Decay*, and *Efflorescence* because the buff only appears while standing inside the zone—causing the tracker to disappear if you step out even while the zone is still active on the ground.

M33kAuraUtils implements a **Dual-State Engine**:
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
1. Download or clone this repository:
   ```bash
   git clone https://github.com/example/M33kAuraUtils.git
   cd M33kAuraUtils
   ```
2. Place or copy the `M33kAuraUtils` folder into your WoW AddOns directory:
   ```text
   World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils
   ```
3. SavedVariables are stored at:
   ```text
   WTF/Account/<AccountName>/SavedVariables/M33kAuraUtils.lua
   ```
4. Restart or reload World of Warcraft (`/reload`).

---

## Slash Commands

| Command | Description |
| :--- | :--- |
| `/m33k`, `/m33kaura`, or `/m33kaurautils` | Shows help menu and available commands |
| `/m33k lock` | Toggles locking/unlocking the frame for dragging |
| `/m33k reset` | Resets the frame position to screen center |
| `/m33k toggle` | Shows or hides the display frame |
| `/m33k add <castId> <buffId> [sec]` | Registers a new custom ground spell |

---

## Local Development & Testing

You can run the full test suite and validation scripts locally before pushing:

### Windows Batch / PowerShell / Lua
```powershell
# Using the build & test runner
lua build.lua

# Or using the Lua runner directly
lua scripts/run_tests.lua

# Or using the convenience scripts
.\scripts\test.bat
# or
.\scripts\test.ps1
```

### GitHub Actions CI
On every push and pull request, GitHub Actions executes:
- TOC file structure verification (`M33kAuraUtils.toc`)
- Lua syntax validation across all source files
- Dual-state engine unit test suite (`tests/test_engine.lua`)
- Database and profile unit test suite (`tests/test_database.lua`)
- UI and visual frame unit test suite (`tests/test_ui.lua`)
- Cross-addon injection unit test suite (`tests/test_injection.lua`)
- Secret access and log redaction security verification (`tests/test_secret_access.lua`)

---

## Documentation & Wiki

For detailed documentation, visit the [Wiki](wiki/Home.md):
- [Architecture & State Machine](wiki/Architecture.md)
- [Configuration Guide](wiki/Configuration.md)
- [Supported Spells & Custom Spells](wiki/Supported-Spells.md)
- [Developer API Reference](wiki/API-Reference.md)
- [CurseForge & Wago Publishing Guide](wiki/Publishing.md)

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on code style, test requirements, and pull request procedures.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
