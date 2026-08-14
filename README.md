# M33kAuraUtils

[![CI](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/ci.yml/badge.svg)](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/ci.yml)
[![Release](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/release.yml/badge.svg)](https://github.com/knoxy5467/M33kAuraUtils/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WoW: Midnight Ready](https://img.shields.io/badge/WoW-Midnight%20(12.0%2B)-blue.svg)](https://worldofwarcraft.com)

**M33kAuraUtils** is a lightweight combat and aura utility for World of Warcraft (Retail & Midnight) designed to bridge custom auras with the native **Blizzard Cooldown Manager**.

It enables creating and synchronizing **M33kAuras**, **ThisWeeksAuras**, and **WeakAuras** triggers for buffs, player states, and cooldowns tracked directly by Blizzard's modern cooldown architecture.

---

## ✨ Features

* **Blizzard Cooldown Manager Integration:** Directly interfaces with native cooldown and buff management systems for precise, authoritative timer and state data.
* **M33kAuras & WeakAuras Synergy:** Seamlessly injects trigger options for player buffs, charges, and cooldowns directly into your aura editor.
* **Midnight (12.0+) Ready:** Built from the ground up for modern retail WoW and Midnight API specifications.
* **Zero Overhead:** High-performance, pure Lua implementation with zero bloat or third-party framework dependencies.

---

## ⌨️ Slash Commands

* `/m33k` — Show status and available commands.
* `/m33k reset` — Reset configuration settings to default.
* `/m33k toggle` — Toggle debug/diagnostic monitoring mode.

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
