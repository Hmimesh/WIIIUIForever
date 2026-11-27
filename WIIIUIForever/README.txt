WIIIUI Forever 1.1.0 - Talents and healing feedback

A Warcraft III-inspired interface reimagined for WoW Forever.
Target: Forever 1.60.1.71139, Interface 16001. Other clients are not currently tested.

INSTALL
Extract the WIIIUIForever folder into:
World of Warcraft/_forever_/Interface/AddOns/
The WIIIUIForever.toc file must be directly inside that folder.
Restart the client if installing for the first time. Enable WIIIUI Forever.

CONFIGURE
Incoming healing previews and floating healing-received numbers are on by
default. Toggle them separately in Cog > Health and resource text > Healing
feedback. The choices save per character.
Use the cog above chat, or /wiiiui human, orc, undead, or nightelf.
/wiiiui off restores the native layout; /wiiiui on enables the console.
Additional action bars are enabled in WoW's own Action Bars settings.
Move pet controls, stance/aura/stealth bars, the pet portrait, and the cast bar
in Esc > Edit Mode > WIIIUI Forever Bars, then Save. Custom positions are kept.
Drag the Character window title bar on any tab outside combat. Its saved
position is shared across tabs; the default position is on the left.
In the Character window's Talents panel, choose a tree and click available
talents to allocate points. Apply learns the pending talents; Undo all discards
all pending changes, including changes in the full talent tree. Learned talents
are kept. Rows, gaps, and prerequisite links follow the native talent trees.
Talent editing is unavailable in combat. Open talent tree remains available
for the full view and choice talents.
Choose Soul Shards in Cog > Character panel > a stat slot to show the count
carried in your bags. Combat stats retain their last readable value if
combat data is unavailable; the tooltip identifies those cached values.
The optional six-slot panel accepts dragged spells and items outside combat,
with icon sizes, click areas and cooldowns fitted to each faction theme.
Open Settings > AddOns > WIIIUI Forever > Console layout to reorder or remove
whole boxes. The faction borders follow the boxes. Layouts save per character.
Enable Show full character name in the same AddOns settings for first names
and surnames on the HUD and Character window. Pet and round minion trackers
sit above the HUD. The themed Character window includes talents, statistics,
model/equipment, and inventory panels. Protected layout changes wait until
combat ends.

FEEDBACK
Use the bug icon under Settings > AddOns > WIIIUI Forever to get the GitHub
issue link. Contributions and bug reports are welcome:
https://github.com/Hmimesh/WIIIUIForever/issues
Include addon/client versions, race/class, theme, resolution, UI scale,
steps to reproduce, screenshots, and the first Lua error if there is one.

CREDITS
Huge thanks to Fiur for the original WIIIUI and its faction console artwork:
https://github.com/Fiurs-Hearth/WIIIUI
This Forever reimagining has its own implementation and feature set.
Not all original WIIIUI features are included; this version also adds new ones.
Additional panel, clock, ribbon and indicator artwork comes from Warcraft III.
The custom addon icon was generated from a maintainer-supplied reference.
Warcraft artwork and trademarks belong to Blizzard Entertainment.
This is an unofficial community project. Attribution does not relicense assets.
