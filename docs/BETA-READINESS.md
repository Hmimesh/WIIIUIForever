# WIIIUI Forever beta readiness

Updated 2026-11-22 for the local `0.7.0-beta3` candidate on Forever 1.60.1 (Interface 16001).

This is a proposed acceptance checklist, not a statement that every test below has passed. The current feature set is sufficient for a beta. Prioritize predictable installation, gameplay, saved settings, and recovery before adding features.

## What we already have

- Four faction console themes, with recent border fixes and theme-specific chat artwork.
- Animated portrait, framing controls, camera lock, and reset/reapply controls.
- Configurable character stats, health/resource text, XP/rested XP, and status indicators.
- Optional six quick slots, character/inventory windows, and session ribbon/clock.
- Native action bars and a separate Edit Mode layout, with an off switch to restore the native layout.
- Verified standalone ZIP builder and a CurseForge submission-kit builder.
- Maintainer screenshots and local mocked Lua regression checks from development.

These are implemented capabilities. Screenshots and mocked checks do not establish reliability on every supported character or display setup.

## Required before the first beta

### 1. Installation and saved settings

- [ ] Install the ZIP into a clean test setup with no prior WIIIUI SavedVariables. Preserve the normal player's settings separately.
- [ ] Create a new character: map, portrait, action bars, menus, and chat initialize correctly without manual positioning.
- [ ] Upgrade an existing alpha character without losing portrait offsets, quick-slot assignments, or window positions.
- [ ] Verify account-wide and per-character choices stay in their intended scope when switching characters.
- [ ] Test a cold game restart, logout/login, `/reload`, zoning, and a level-up.
- [ ] Confirm optional features remain hidden when disabled and assignments survive being hidden.

Pass condition: normal installation and upgrading need no manual repair and do not discard unrelated player settings.

### 2. Combat and native controls

- [ ] Action buttons, keybinds, action paging, pet controls, and stance/form controls work before, during, and after combat.
- [ ] No reproducible addon-blocked-action messages or Lua errors during normal gameplay.
- [ ] Protected layout changes requested during combat wait until combat ends, then apply once.
- [ ] With an assigned item and spell, `/reload` during combat. Verify that native actions and keybinds work immediately, no Lua errors or blocked actions appear, and the console docks with both assignments after combat without a second reload. Repeat with quick slots disabled and with `/wiiiui off` saved.
- [ ] Repeat an out-of-combat reload to confirm that the console docks immediately and both saved actions work.
- [ ] Test portrait health/resource text for mana, rage, and energy, including zero/max values, death, and resurrection.
- [ ] Check PvP flag and combat/threat indicators independently; do not equate PvP enabled with currently fighting.
- [ ] Compare combat DPS and highest-damage ability with the native meter over several fights. Document whether pets are included and whether some results are unavailable until combat ends.
- [ ] If the client withholds a value, show a clearly unavailable state or use a documented supported display; do not invent a result or perform forbidden arithmetic on secret values.

Pass condition: enabling the addon does not prevent ordinary combat, targeting, casting, or item use.

### 3. Portrait stability

- [ ] Recheck previously troublesome Tauren, Undead, and Troll models; include available male/female models and different equipment.
- [ ] Test attacks, casts, equipment changes, level-ups, reloads, and a fresh login with camera lock enabled.
- [ ] Test supported appearance/form changes and return to the normal model.
- [ ] Keep the animated model inside the viewport and behind its foreground trim.
- [ ] Reset clears framing as documented; reapply restores the saved framing.
- [ ] The static fallback remains usable if the animated model or camera is not ready.

Pass condition: repeated ordinary events do not progressively change framing or require constant slider repair. Any unsupported appearance needs a usable fallback and a documented limitation.

### 4. Display and theme matrix

| Coverage | Minimum cases |
| --- | --- |
| Themes | Human, Orc, Undead, Night Elf; switch in both directions and return after reload |
| Displays | 1920x1080 and 2560x1440; add an ultrawide setup if it will be advertised as supported |
| UI scale | Automatic scale and at least two manually selected scales |
| Window state | Normal play, Alt-Tab back to the game, maximize/window-mode transitions |
| Bars | One, two, and three horizontal rows; quick slots on/off |
| Character systems | Pet class, form/stance class, mana class, rage class, energy class |

- [ ] Bottom action row, health/resource bars, map, and chat input remain fully visible.
- [ ] Chat borders retain correct joins and do not change another theme's textures after switching.
- [ ] No invisible overlay intercepts clicks intended for map, chat, slots, portrait, or the game world.
- [ ] Resizing and UI-scale changes recover without a restart or manual frame repair.

Pass condition: the supported matrix is recorded with actual results. Document narrower support if a configuration has not been verified.

### 5. Character window, bags, and recovery

- [ ] Character-sheet opening/closing, equipment clicks, dragging, and saved positions work.
- [ ] Combined inventory, backpack-only, individual bags, and hidden inventory show the correct slots, icons, counts, and item interactions.
- [ ] Loot, bag replacement, and item changes refresh the inventory correctly.
- [ ] `/wiiiui off` restores the native controls and prior Edit Mode layout; `/wiiiui on` returns to the console.
- [ ] A full Edit Mode layout list gives an actionable message without breaking the UI.
- [ ] Reset-window-position and reset-portrait controls are discoverable and work.

Pass condition: a player can recover a usable interface without deleting SavedVariables or losing their original layout.

### 6. Performance and compatibility

- [ ] Test the addon alone, then with the maintainer's normal addon set.
- [ ] Check at least one common bag replacement if compatibility will be advertised.
- [ ] Document conflicts with addons that move or replace the same action bars, minimap, chat, or unit frames.
- [ ] Observe a 30-60 minute session covering travel, combat, bags, and theme changes for frame-time spikes and steadily growing retained memory.
- [ ] Confirm portrait maintenance and layout hooks do not repeatedly rebuild or allocate work unnecessarily.

Pass condition: no obvious addon-caused stutter, runaway work, or known gameplay-blocking conflict in the stated supported setup. Report measured results rather than claiming compatibility with all addons.

### 7. Release consistency

- [x] Apply **CC BY 4.0** to the original implementation and document the third-party exclusions in the repository and packaged license.
- [ ] Match the license in the repository, packaged notice, listing description, and CurseForge project field.
- [ ] Confirm redistribution permission or an applicable license for the upstream material and artwork included in a CurseForge upload. See [the submission notes](curseforge/SUBMISSION.md) and [CurseForge's moderation policy](https://support.curseforge.com/support/solutions/articles/9000197279-project-and-modpack-moderation-policies).
- [x] Match the public README, release notes, and listing to the `0.7.0-beta3` TOC version and ZIP filename.
- [x] Adapt the submission-kit builder for Beta and validate release type against the version.
- [x] Update the contribution guide and release notes, keeping precise known limitations.
- [ ] Build and verify a ZIP containing only the installable addon folder and matching TOC, assets, and license files.
- [ ] Test the actual extracted upload ZIP rather than only the development folder.
- [ ] Select Forever / 1.60.1 and Beta on CurseForge; do not add untested clients.
- [ ] Preserve Fiur's credit, the optional-sidegrade wording, and the link to the other Forever Edition.
- [ ] Ask the maintainer before each Git push. Uploading or promoting the beta is a separate action from preparing it.

## Changes that would help most

These are recommended improvements, not prerequisites for calling a working build beta:

1. Extend the existing Settings bug-report button with a copyable diagnostic summary. Include addon/client version, race/class, theme, resolution, UI scale, enabled optional features, and whether layout was deferred for combat. Leave account identifiers out.
2. A GitHub bug-report form requesting reproduction steps, the first Lua error, and a screenshot.
3. Portable regression checks in the repository, especially for saved-data upgrades, theme switching, native-layout restoration, portrait transitions, and combat deferral. Current development checks live outside the tracked project.
4. A documented recovery path accessible from both the cog and slash commands. Existing off/reset controls should be explained before adding more reset actions.
5. A small tester results table with build, setup, tested scenarios, and open bugs. This provides evidence for promotion and prevents repeated untracked fixes.
6. A predictable changelog and issue labels for gameplay blockers, portrait/layout bugs, and cosmetic issues.

## Feature priorities during beta

1. **HUD presets and compact sizing.** Try a Console preset with the full artwork and a Compact preset with more space for the world on small displays. Keep each character's custom settings when switching presets.
2. **Independent styling toggles.** Let players keep the faction HUD while leaving their current minimap, chat, or bags to WoW or another addon. Start with the conflicts that testers report most often.
3. **Copy settings from another character.** Copy presentation choices between alts while keeping their own quick-slot actions and original Edit Mode layout references.

Use tester feedback to choose the first feature. Keep new faction art, cursor replacement, voice lines, and more ribbon metrics for later.

## Suggested beta gate

- No known reproducible bug that prevents combat, normal controls, loading the UI, or restoring the native layout.
- No known settings-loss or progressive portrait/layout corruption.
- The main installation, reload, combat, and display checks above pass on the exact upload ZIP.
- Known remaining cosmetic issues are documented and have a usable workaround where needed.
- As an initial confidence target, collect results from 3-5 testers with more than one display setup and several character types, then run a short real-play test round. This is a recommendation, not a CurseForge requirement.

## Suggested 1.0 gate

- Test an upgrade from the public beta and a fresh install of the exact release ZIP. Verify the in-game recovery path and retain a downloadable last known good build.
- Run two consecutive beta builds through real play on the supported display and character matrix, including a pet class, a stance/form class, and at least one normal addon stack. Log results against the build tested.
- Close reproducible blockers involving login, reload, combat, native controls, settings loss, and native-layout recovery. Document supported displays, known addon conflicts, and any remaining visual issues with their workarounds.
- Confirm that an ordinary play session with combat, zoning, and bags shows no recurring Lua errors, frame-time spikes attributable to the addon, or steadily growing addon memory.

## CurseForge distribution note

CurseForge documents that Beta updates are opt-in. Its two guides give different rules for when a new project starts syncing to the app, so verify app visibility separately from testing the downloadable ZIP. [File and project types](https://support.curseforge.com/support/solutions/articles/9000197242-file-project-types-and-additional-fields) · [Project submission guide](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project)
