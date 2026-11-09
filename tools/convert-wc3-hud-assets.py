"""Convert extracted Warcraft III DDS files to WoW-compatible RGBA TGA files.

Usage: python convert-wc3-hud-assets.py EXTRACTED_DDS_DIR ADDON_ART_DIR
No resampling or recoloring is applied to the original artwork.
"""
from pathlib import Path
import sys
from PIL import Image

source, output = map(Path, sys.argv[1:3])
manifest = {}
for theme, race in (("human", "Human"), ("orc", "Orc"), ("undead", "Undead"), ("nightelf", "NightElf")):
    manifest[f"{race}UITile05.dds"] = f"{theme}/chrome/rail.tga"
    manifest[f"{race}UITile-TimeIndicatorFrame.dds"] = f"{theme}/chrome/clock.tga"
    manifest[f"{theme}-console-buttonstates2.dds"] = f"{theme}/chrome/upper.tga"
    manifest[f"BTN{race}CaptureFlag.dds"] = f"{theme}/chrome/pvp.tga"
for name, file in {
    "gold": "ResourceGold", "gold-hour": "ResourceUpkeep", "xp": "ResourceManaStone",
    "money": "BTNChestOfGold", "combat": "BTNAttack", "threat": "BTNAttackGround",
    "resting": "BTNSleep", "armor": "infocard-armor-hero", "aggro": "infocard-attack-chaos",
}.items():
    manifest[file + ".dds"] = f"wc3/{name}.tga"
manifest["HumanUITile-TimeIndicator.dds"] = "wc3/day-night.tga"
for file, target in manifest.items():
    image = Image.open(source / file).convert("RGBA")
    destination = output / target
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, format="TGA")
    assert Image.open(destination).size == image.size
print(f"Converted {len(manifest)} original Warcraft III HUD textures.")
