# CurseForge preparation

Prepared on 2026-11-09 for **0.6.13-alpha2**. The border-fix baseline, **2b68a61** (`fixed borders`), is published on `origin/main`. The alpha2 packaging and submission materials are prepared locally. The build records the exact package source commit in the kit's `project.json` and `manifest.json`.

Run `python tools/prepare-curseforge.py` from a commit containing the installable changes to build and verify the portable review kit at `dist/curseforge-0.6.13-alpha2/`. It includes the addon ZIP, pasteable listing files, gallery images/captions, avatar candidate, and SHA-256 manifest. It never uploads anything or chooses a license.

## Files ready for review

- Addon upload: `../../dist/WIIIUIForever-0.6.13-alpha2.zip`
- SHA-256: generated alongside the archive as `WIIIUIForever-0.6.13-alpha2.zip.sha256`, also included in the review kit
- Fields: [project.json](project.json)
- Pasteable description: [DESCRIPTION.md](DESCRIPTION.md)
- File changelog: [CHANGELOG.md](CHANGELOG.md)
- Gallery order and captions: [gallery.json](gallery.json)
- Proposed 400 x 400 project avatar: [avatar-candidate.png](avatar-candidate.png), editable [SVG](avatar-candidate.svg)

The ZIP contains only the installable `WIIIUIForever/` directory, including `WIIIUIForever/WIIIUIForever.toc`, Lua, artwork, installation notes, and changelog. It excludes this submission kit, screenshots, Git metadata, account state, and unrelated workspace projects. The upload artifact was verified against source bytes and its TOC references.

## Decisions before submission

1. **Project license selected:** MIT for original code, as requested by the maintainer. Scope and exclusions are in `../../LICENSE.md` and the packaged `LICENSE.txt`. Third-party assets are not relicensed. The upstream [CurseForge listing](https://www.curseforge.com/wow/addons/wiiiui) displays All Rights Reserved; the upstream repository does not contain an explicit blanket license. Keep any rights evidence for submission review separately; the public description makes no personal-permission claims.
2. **Artwork:** the package contains upstream console artwork and converted Warcraft III artwork. Do not apply a new open-source license to third-party assets by assumption. Their ownership is already described in `CREDITS.md`.
3. **Positioning:** public copy links both Fiur's original and Infinityaddons' Forever Edition, and describes this project as an optional sidegrade. It makes no claims about the other fork's relative quality or licensing.
4. **Avatar:** review the original geometric UI monogram candidate. It uses no game texture or official Warcraft emblem. The existing in-game W/III/UI icon is unchanged. This candidate avoids reusing the official-style W as the project avatar; moderator acceptance is not guaranteed.
5. **Name and slug:** proposed name is WIIIUI Forever; check availability in the author portal. No project has been created or submitted.

## Submission fields and sequence

1. Open the [CurseForge author portal](https://authors.curseforge.com/#/projects/create/choose-game).
2. Select World of Warcraft, class Addons, main category HUDs. Suggested additional categories are Artwork, Action Bars, Unit Frames, and Bags & Inventory.
3. Use the summary in `project.json`, the reviewed avatar, and `DESCRIPTION.md`. Do not copy the original WIIIUI description. Source and issue links point to this fork.
4. Select MIT for original code, retaining the explicit third-party exclusions in the description and packaged license.
5. Upload gallery images in `gallery.json`; they are actual maintainer-supplied screenshots. Retain the caveat about other addons/world visuals.
6. Upload **only** `WIIIUIForever-0.6.13-alpha2.zip` as the addon file. Do not upload the entire repository or the submission kit.
7. File display name: WIIIUI Forever 0.6.13-alpha2. Choose **Forever / 1.60.1** and **Alpha**. Do not tag untested clients. No required dependencies are declared.
8. Paste `CHANGELOG.md`. Keep the build labeled Alpha. CurseForge documents that a project needs a Release file before normal app syncing; do not mislabel this alpha to obtain that behavior.
9. Review the concrete listing and file fields before the final upload. Any account agreement requires the account owner's acceptance.

## Verification already performed

- Lua 5.1 loading and mocked native-frame integration.
- Theme asset references, theme switching, immutable cached chat geometry/UVs/visibility, and chat beam coverage.
- Combat deferral, quick-slot restore/hiding, Edit Mode/gamepad fallback, portrait and ribbon regressions, XP/rested sizing.
- Maintainer screenshots of all four themes and confirmation that the viewport clipping cleared.
- Standalone ZIP integrity, all installable file checksums, and TOC/icon/license references.
- README links, version, credits, and screenshot integrity.

Mock checks and current live screenshots do not establish compatibility with every race, resolution, UI scale, or other addon. The project remains alpha.

## Policy references

Checked 2026-11-09:

- [Moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279): fork/content permissions and credit, distinct functional description, 400 x 400 avatar, changelog, and accurate showcase images.
- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project): fields, categories, license, release type, game-version selection, and submission workflow.
- [WoW file processor](https://support.curseforge.com/support/solutions/articles/9000210425-elerium-file-processor-errors-per-game): ZIP root folders and matching folder/TOC name.
- [Current Forever file listing](https://www.curseforge.com/wow/addons/naowhforever/files/all): Forever flavor and 1.60.1 version are available.

The preparation tool does not create a CurseForge project, upload files, send messages, commit, or push. Publish the reviewed alpha2 documentation before using the repository links in a live listing.
