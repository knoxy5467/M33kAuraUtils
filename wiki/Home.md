# M33kAuraUtils Wiki

Welcome to the **M33kAuraUtils** documentation wiki!

M33kAuraUtils is a standalone World of Warcraft addon designed to solve the "ground-placed aura problem" (e.g., Consecration, Death and Decay, Defile, Efflorescence, Healing Rain, Sigil of Flame). It tracks both the ground zone lifetime and whether the player is standing inside or outside the effect, providing visual and audio feedback with zero dependencies.

---

## Wiki Contents

- **[Architecture & State Machine](Architecture.md)**: Deep dive into how the dual-state engine calculates ground lifetimes and player in-zone aura states.
- **[Supported Spells & Custom Spells](Supported-Spells.md)**: Complete table of preconfigured class spells and instructions for adding custom spells via `/m33k add` or Lua API.
- **[Configuration Guide](Configuration.md)**: Customizing colors, sizes, frame positioning, progress bars, slash commands, and SavedVariables (`M33kAuraUtilsDB`).
- **[Developer API Reference](API-Reference.md)**: How third-party addons (or WeakAuras) can query M33kAuraUtils (`_G.M33kAuraUtils`, `_G.M33K`, `M33K.Engine`) or register state change callbacks.
- **[Publishing to CurseForge & Wago](Publishing.md)**: Guide for configuring TOC metadata, API tokens, and automated packaging workflows.
