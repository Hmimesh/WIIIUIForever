# WIIIUI Forever 1.1.0 — Talents and healing feedback

**2026-11-27 · WoW Forever 1.60.1.71139 · Interface 16001**

Includes all changes since 1.0.0. [Download WIIIUI Forever 1.1.0](https://github.com/Hmimesh/WIIIUIForever/releases/download/v1.1.0/WIIIUIForever-1.1.0.zip).

## Changes

- Allocate talent points in Character → Talents. Trees preserve native rows, empty columns, prerequisite links, rank counts, and availability colours. Click available talents and choose **Apply** to learn them; **Undo all** discards pending changes, including those made in the full talent tree, while preserving learned talents. Native restrictions and combat locks apply.
- Correct Hunter talent coordinates and row offsets, clamp scrolling after refreshes, and check point costs before marking talents available.
- Preview incoming healing as a cyan segment after current HP, clamped to missing health and adjusted for heal absorbs, with the HP text above the bar and the predicted amount above the portrait.
- Show floating green healing-received numbers for self-heals and heals from other players; critical heals use larger text.
- Toggle the two healing displays separately under **Cog → Health and resource text → Healing feedback**. Both default to enabled and save per character.
- Preserve the previous HUD layouts, movable Character/inventory windows, themes, quick slots, Soul Shard tracking, combat statistics, minimap alignment, and Edit Mode positions for class and pet controls.

## Game update review

The installed game executable and build manifest identify **1.60.1.71139**. The matching [native UI source revision](https://github.com/Gethe/wow-ui-source/commit/d9c22e32cb240afb82bb2ecefbb78ef935333f59) changes the shop and gamepad world-map controls. WIIIUI and Record Player do not replace those consumers. Interface remains **16001**, so no TOC interface bump is needed.

The exact-build talent and healing API declarations match the source used for the recent features. WIIIUI's Lua 5.1 parsing and regression checks pass, including all 3,840 HUD layouts, combat deferral, saved positions, talents, healing, quick slots, and combat statistics. Record Player's 36 Python/Lua tests and 13 companion tests also pass. Its installed addon files already match the workspace, so Record Player remains version 0.3.0.

These are source and mocked runtime checks. Gameplay testing on the newly updated client remains pending.

## Install

Extract **WIIIUIForever-1.1.0.zip** and copy its **WIIIUIForever** folder into `World of Warcraft/_forever_/Interface/AddOns/`, replacing the previous addon files. Saved settings remain in the game's separate WTF directory. Start the game, or use `/reload` if it is already running.

Check the talent trees and Apply/Undo controls, cast or receive a heal, and confirm the saved HUD layout and class/pet control positions. Record Player and its companion remain separate from the WIIIUI ZIP.
