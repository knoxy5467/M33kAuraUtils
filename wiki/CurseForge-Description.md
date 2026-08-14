# M33kAuraUtils — CurseForge Listing Content

## 1. Project Summary (For CurseForge "Summary" Field)
> Seamlessly creates WeakAuras and M33kAuras triggers for buffs and cooldowns tracked by the Blizzard Cooldown Manager in World of Warcraft: Midnight.

---

## 2. Full Project Description (For CurseForge "Description" Field)

```markdown
# M33kAuraUtils

**M33kAuraUtils** is a lightweight combat and aura utility for World of Warcraft (Retail & Midnight) designed to bridge custom auras with the native **Blizzard Cooldown Manager**.

With the evolving API and cooldown architecture in *Midnight*, tracking player abilities, buffs, and rotational cooldowns directly through standard triggers can often result in desynchronization or missing aura states. **M33kAuraUtils** solves this by hooking into the Blizzard Cooldown Manager pipeline, providing enhanced aura trigger options and synchronization for **M33kAuras**, **ThisWeeksAuras**, and **WeakAuras**.

---

### ✨ Key Features

* **Blizzard Cooldown Manager Integration:** Directly interfaces with Blizzard's native cooldown and buff management systems to ensure precise, authoritative timer and state data.
* **M33kAuras & WeakAuras Synergy:** Seamlessly integrates into your existing aura framework, injecting optimized trigger options for player buffs, charges, and cooldowns.
* **Midnight Ready:** Built from the ground up for *World of Warcraft: Midnight* (12.0+) and modern retail API standards.
* **Accurate Buff & State Tracking:** Solves complex aura tracking edge cases where standard unit auras fail to reflect active combat states or cooldown resets.
* **Zero Dependency Overhead:** High-performance, pure Lua implementation with zero bloat or third-party framework overhead.

---

### ⚙️ How It Works

1. **Automatic Cooldown Hooking:** M33kAuraUtils monitors the Blizzard Cooldown Manager events and synchronizes state updates in real time.
2. **Enhanced Trigger Options:** When configuring auras in M33kAuras or WeakAuras, M33kAuraUtils provides direct selector options to track buffs and cooldowns through the Blizzard Cooldown Manager pipeline.
3. **Instant Visual Feedback:** Custom auras reflect exact expiration times, charges, and active states with zero desync.

---

### ⌨️ Slash Commands & Configuration

* `/m33k` — Display addon status and available utility commands.
* `/m33k reset` — Reset configuration settings to default.
* `/m33k toggle` — Toggle debug and diagnostic monitoring mode.

---

### 📦 Installation

1. Install via the **CurseForge App** (recommended) or extract into your `World of Warcraft\_retail_\Interface\AddOns\` directory.
2. Ensure both **`M33kAuraUtils`** and your aura framework (**`M33kAuras`** or **`WeakAuras`**) are enabled in your AddOn list.
3. Log into the game—M33kAuraUtils will automatically hook into the Cooldown Manager.

---

### 🔗 Links & Community

* **Source Code:** [GitHub Repository](https://github.com/knoxy5467/M33kAuraUtils)
* **Bug Reports & Feedback:** [GitHub Issues](https://github.com/knoxy5467/M33kAuraUtils/issues)
```
