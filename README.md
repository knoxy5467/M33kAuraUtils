# M33kAuraUtils

[![CI](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/ci.yml/badge.svg)](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/ci.yml)
[![Release](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/release.yml/badge.svg)](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WoW: Midnight Ready](https://img.shields.io/badge/WoW-Midnight%20(12.0%2B)-blue.svg)](https://worldofwarcraft.com)

**M33kAuraUtils** is a seamless combat and trigger extension for World of Warcraft (Retail & Midnight) that bridges custom auras directly with the native **Blizzard Cooldown Manager**.

**Zero Chat Commands. 100% Native GUI Integration.**

Instead of relying on chat slash commands, **M33kAuraUtils** hooks directly into the **M33kAuras**, **ThisWeeksAuras**, and **WeakAuras** configuration panels. When creating or editing a trigger for player buffs or cooldowns, new Blizzard Cooldown Manager options appear natively inside the aura editor interface.

---

## ✨ Features

* **100% In-GUI Trigger Integration:** Injects options directly into the **M33kAuras** and **WeakAuras** Trigger Options panel. Configure everything with intuitive dropdowns and toggles right where you build your auras.
* **Blizzard Cooldown Manager Synchronization:** Interfaces with Blizzard's native cooldown and buff management engine in *Midnight* (12.0+) and modern Retail.
* **No Slash Commands Required:** Fully graphical workflow. Set it up visually in the aura options window just like any built-in trigger type.
* **Dual-State Cooldown & Aura Awareness:** Accurately tracks active durations, charges, and state changes even when standard unit auras fail to register.
* **Zero Overhead:** High-performance, pure Lua implementation with zero bloat or third-party framework dependencies.

---

## 🖥️ How It Works in the UI

1. Open your aura editor (`/wa` or `/m33kauras`).
2. Select your Aura $\rightarrow$ Navigate to the **Trigger** tab.
3. Under your Player Buff or Cooldown trigger, configure the injected **Blizzard Cooldown Manager** options directly in the GUI.

---

## 🧪 Development & Testing

Run all unit test suites locally with 100% native Lua:

```bash
lua build.lua
```

Or via PowerShell:
```powershell
.\scripts\test.ps1
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
