# WIIIUI Forever

Bring a Warcraft III-style command console to World of Warcraft: Forever.

**Alpha: 0.6.13-alpha2.** Built for **Forever 1.60.1 / Interface 16001**. Other WoW clients are not currently supported or tested. Bug reports, ideas, and contributions are welcome.

## Choose your console

Switch between **Human, Orc, Undead, and Night Elf** styles using the cog above chat. Your character's race does not restrict which style you choose.

The console arranges WoW's native action bars, minimap, chat, and menus inside faction artwork. Action buttons retain their normal WoW behavior. Enable additional action bars in WoW's Action Bars settings to populate the upper rows.

## Make it your own

- Animated player portrait with per-character framing, camera lock, reset, and reapply controls.
- Four selectable character stats, including weapon damage, armor, ammo, melee or ranged DPS, crit, spell/healing information, rested XP, combat DPS, and the highest-damage ability.
- Equipment-aware icons for supported stats. Combat statistics use Forever's native damage meter and reset for each fight.
- Health and resource text shown as numbers, percentages, both, or neither.
- XP bar with a rested-XP segment and hover details.
- Optional six-slot item/spell panel between the action bars and chat. Hiding the panel retains your assignments.
- Configurable PvP and combat indicators, with icons, text, styling, and visibility options.
- Session ribbon with selectable XP/hour, gold gained, gold/hour, session time, time-to-level, and other metrics, plus an optional day/night clock.
- Optional Forsaken Kingdom-inspired character window and a separately movable inventory panel. Choose all carried bags, the backpack, an individual bag, or no inventory panel.

No companion addons are required. MoveAnything and the original WIIIUI do not need to be installed.

## Installation and controls

Extract the **WIIIUIForever** folder into:

```text
World of Warcraft/_forever_/Interface/AddOns/
```

The file `WIIIUIForever.toc` must be directly inside the `WIIIUIForever` folder. Restart the game after a first installation and enable **WIIIUI Forever** in the AddOn list.

Open the cog above chat to configure the addon. Human is the default style.

```text
/wiiiui human
/wiiiui orc
/wiiiui undead
/wiiiui nightelf
/wiiiui off
/wiiiui on
```

`/wiiiui off` restores the native layout; `/wiiiui on` returns to the console. Protected layout and quick-slot changes wait until combat ends.

## Alpha feedback

Portrait framing, appearance transitions, resolutions/UI scales, and compatibility with other UI addons are still being refined. Please include your addon/client versions, character race/class, theme, resolution, UI scale, reproduction steps, and the first Lua error when reporting an issue. Let us know whether it happens after login, a reload, leveling, combat, or an equipment change.

Screenshots in the gallery show the actual addon in game. Other addons and client world visuals visible in them are not included.

## A reimagining of Fiur's WIIIUI

Huge thanks to **Fiur / Fiurs-Hearth** for the [original WIIIUI](https://github.com/Fiurs-Hearth/WIIIUI) and its faction console foundation. WIIIUI Forever is a separate Forever-specific fork and reimagining, with its own implementation and configuration. Many original features are not present, while this version adds new character, inventory, stat, and session tools. The original project's dependencies and instructions do not necessarily apply.

There are other forks and reimaginings of the original addon, including **[Warcraft 3 UI: Forever Edition](https://www.curseforge.com/wow/addons/warcraft-3-ui-forever-edition)** by Infinityaddons. WIIIUI Forever is an optional sidegrade for anyone who prefers this version's features and layout. Choose whichever version suits you.

Warcraft artwork and trademarks belong to Blizzard Entertainment. This is an unofficial community project, not affiliated with or endorsed by Blizzard. See the project's [artwork credits](https://github.com/Hmimesh/WIIIUIForever/blob/main/CREDITS.md).

Original code is licensed under the [CC BY 4.0](https://github.com/Hmimesh/WIIIUIForever/blob/main/LICENSE.md). Third-party artwork and upstream material are excluded and retain their existing ownership and terms.

[Source and contribution guide](https://github.com/Hmimesh/WIIIUIForever) · [Bug reports and feature requests](https://github.com/Hmimesh/WIIIUIForever/issues) · [Configuration guide](https://github.com/Hmimesh/WIIIUIForever/blob/main/docs/CONFIGURATION.md)
