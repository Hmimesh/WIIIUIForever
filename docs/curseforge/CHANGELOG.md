# WIIIUI Forever 1.1.0 — Talents and healing feedback

**2026-11-27 · WoW Forever 1.60.1.71139 · Interface 16001**

- Allocate talent points in Character > Talents, with native tree rows, prerequisite links, rank counts, and availability colours. Click available talents, then Apply to learn; Undo all discards pending changes while preserving learned talents. Editing follows native restrictions and is unavailable in combat.
- Correct Hunter talent coordinates and row offsets, clamp scrolling after refreshes, and check point costs before marking talents available.
- Preview incoming healing as a cyan segment after current HP, clamped to missing health and adjusted for heal absorbs. HP text stays above the bar, with the predicted amount above the portrait.
- Show floating green healing-received numbers for self-heals and heals from other players, with larger critical heals.
- Toggle the healing displays independently under Cog > Health and resource text > Healing feedback. Both default to enabled and save per character.
- Reviewed compatibility with build 71139; Interface remains 16001. Existing HUD layouts, movable windows, class/pet controls, Soul Shard tracking, and quick-slot fixes are included.

Lua regression checks passed. Gameplay testing after this game update remains pending.

# WIIIUI Forever V1.0 (1.0.0) — First stable release

**2026-11-25 · WoW Forever 1.60.1 · Interface 16001**

## Changes since Beta V3

- First stable release for World of Warcraft: Forever 1.60.1 (Interface 16001).
- Fixed the six-slot quick inventory: item/spell icons now fit each faction's painted slot interiors, with corrected row spacing and matching click areas, highlights, and cooldowns.
- Corrected minimap sun/moon alignment in all four themes, including the Orc artwork's round recess.
- Includes movable Character windows on every tab, shared saved positions across tabs, independently movable inventory, combat-stat retention, Soul Shard tracking, and custom Edit Mode placement for class/pet controls, pet portraits, and the cast bar.

## Included in V1.0

- Four Warcraft III-inspired themes: Human, Orc, Forsaken/Undead, and Night Elf, with matching Character and inventory artwork.
- Reorder or hide whole HUD sections: minimap, character panel, action bars, six quick slots, and chat. Faction borders follow their positions, with layouts saved per character.
- Four-panel Character window for talents, statistics, model/equipment, and inventory, with title-bar dragging on every tab and a left-side default.
- Inventory views for all carried bags, backpack only, individual bags, or a hidden inventory panel.
- Animated character portrait with per-character framing, camera lock, reset, and reapply controls.
- Optional full character names, including surnames, on the HUD and Character window.
- Four configurable HUD stats with equipment-aware icons, Soul Shards, and Forever's native combat-meter statistics. Cached combat values are identified in their tooltips.
- Separate health/resource text options, XP hover details, and rested-XP progress.
- Six quick slots for dragged items and spells, with saved assignments, counts, and cooldowns.
- Movable class and pet controls through Edit Mode, plus configurable PvP/combat indicators.
- Optional session ribbon with selectable session statistics and a Warcraft III-style day/night clock.
- Square minimap with coordinates, zone/time information, and supported addon buttons arranged above it.
- Shared WIIIUI Forever Bars Edit Mode layout and /wiiiui off to restore the previous native layout.
- Integrated bug-report link in Settings > AddOns > WIIIUI Forever.


# WIIIUI Forever - Beta V3 (0.7.0-beta3)

For **World of Warcraft: Forever 1.60.1 / Interface 16001**.

- The Character window opens on the left by default.
- Drag the Character window by its title bar on any tab, including Reputation, Skills, PvP, Currency, and Statistics. Its saved position stays consistent when switching tabs or reopening the window.
- The inventory can still be moved independently, with its own saved position.
- HUD stats retain their last readable value and matching icon when combat data is temporarily unavailable. The tooltip identifies cached values, and live values return when available.
- Added **Soul Shards** to every HUD stat-slot menu. The counter tracks shards carried in your bags, updates when gained or spent, and excludes bank storage.
- Pet action bars and class controls, including Hunter pet controls/aspects, Warrior stances, Rogue stealth, and Paladin auras, respect custom Edit Mode positions and sizes.
- The pet portrait and cast bar also retain custom Edit Mode positions. Controls without a custom position keep the addon defaults; resetting their position in Edit Mode returns to those defaults.

Move pet/class controls through **Esc > Edit Mode > WIIIUI Forever Bars**, then **Save**. Select **Soul Shards** through **Cog > Character panel > a stat slot**. Move windows and adjust protected layouts outside combat.

# WIIIUI Forever 0.7.0-beta1 — First public beta

For World of Warcraft: Forever 1.60.1 (Interface 16001).

- Four Warcraft III-inspired console themes: Human, Orc, Forsaken/Undead, and Night Elf, with matching Character and inventory artwork.
- Customizable console layout: reorder or hide the minimap, character panel, action bars, quick slots, and chat as whole boxes. Borders follow each box, and layouts save per character.
- A four-panel Character window for talents, statistics, model/equipment, and inventory. Browse talent ranks and open the native talent tree to make changes. The same themed window remains available in combat.
- Movable Character and inventory windows with saved positions. View all carried bags, the backpack, an individual bag, or hide the inventory panel.
- Animated character portrait with per-character X/Y/Z framing, camera lock, reset, and reapply controls.
- Optional full character names, including surnames, on the HUD and Character window through Settings > AddOns > WIIIUI Forever.
- Four selectable HUD statistics with equipment-aware icons, including damage, armor, ammo, weapon DPS, crit, spell/healing information, rested XP, combat DPS, and highest-damage ability. Combat statistics use Forever's native damage meter.
- Separate health and resource display options: numbers, percentages, both, or hidden.
- Level and class display with XP hover details and a rested-XP segment.
- Six optional quick slots for dragged items and spells; assignments remain saved when the panel is hidden.
- Pet controls, class quick bars, and round summon/minion trackers above the HUD, with space for the cast bar.
- Configurable PvP and combat indicators with icon/text modes, frame styles, and visibility options.
- Optional session ribbon with XP/hour, gold gained, gold/hour, session duration, time-to-level, and other selectable metrics, plus a Warcraft III day/night clock.
- Square minimap with coordinates, zone/time display, day/night indicator, and supported addon buttons arranged above it.
- Shared WIIIUI Forever Bars Edit Mode layout, protected layout changes deferred until combat ends, and /wiiiui off to restore the previous native layout.
- Integrated bug-report link in Settings > AddOns > WIIIUI Forever.

No companion addons are required. Configure console layout and full names in
Settings > AddOns > WIIIUI Forever; use the cog above chat for gameplay display
and theme options. Other WoW clients are not currently tested.
