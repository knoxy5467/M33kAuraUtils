# GroundAuraTracker Wiki

Welcome to the **GroundAuraTracker** documentation wiki!

GroundAuraTracker is a standalone World of Warcraft addon designed to solve the "ground-placed aura problem" (e.g., Consecration, Death and Decay, Efflorescence, Healing Rain). It tracks both the ground zone lifetime and whether the player is standing inside or outside the effect, providing visual and audio feedback with zero dependencies.

---

## Wiki Contents

- **[Architecture & State Machine](Architecture.md)**: Deep dive into how the dual-state engine calculates ground lifetimes and player in-zone aura states.
- **[Supported Spells & Custom Spells](Supported-Spells.md)**: Complete table of preconfigured class spells and instructions for adding custom spells.
- **[Configuration Guide](Configuration.md)**: Customizing colors, sizes, frame positioning, progress bars, and alerts.
- **[Developer API Reference](API-Reference.md)**: How third-party addons (or WeakAuras) can query GroundAuraTracker or register state change callbacks.
