# Contributing to WIIIUI Forever

WIIIUI Forever is in alpha. Bug reports, fixes, feature ideas, and testing on different races, classes, resolutions, and UI scales are welcome.

## Report a bug

Open an issue in this repository. Include the addon/client versions, race/class, theme, screen resolution, UI scale, steps to reproduce, and expected/actual behavior. Screenshots and the first Lua error are especially helpful. Mention other UI addons and whether the problem follows login, reload, leveling, combat, or equipment changes.

## Make a change

1. Fork this repository and create a branch for a focused change.
2. Work in `WIIIUIForever/`. It is the complete installable addon; the repository root is not an addon folder.
3. Copy that folder into your Forever client's `Interface/AddOns` directory and test in game.
4. Check the affected themes and settings, saved settings after `/reload`, and combat transitions where relevant.
5. Open a pull request explaining the problem, the change, and what you tested. Include before/after screenshots for visual changes.

The addon is Lua and targets Forever Interface 16001. It relies on native frames and protected action buttons; defer protected layout changes until outside combat. Forever can mark combat values as secret: avoid arithmetic, comparisons, or string conversion on secret values.

Keep contributions focused on this reimagining. Original WIIIUI features are not automatically supported or required here. Preserve upstream credits and document the source of any added artwork. Do not commit game archives, account data, SavedVariables, credentials, or unrelated addons.

The optional `tools/convert-wc3-hud-assets.py` script uses Pillow to convert already-extracted local DDS assets into TGA textures. It does not download or bundle a game archive.
