"""Pack the generated window art into corner/rail atlases and panel backings."""

from pathlib import Path

from PIL import Image


ART = Path(__file__).resolve().parents[1] / "WIIIUIForever" / "art"
SOURCE = ART.parents[1] / "docs" / "art-source"
RAIL_WIDTHS = {"human": 64, "orc": 68, "undead": 64, "nightelf": 56}


def paste_with_border(atlas, tile, x, y):
    """Extrude the neighboring pixels one texel for linear sampling."""
    width, height = tile.size
    atlas.paste(tile, (x, y))
    atlas.paste(tile.crop((0, 0, 1, height)), (x - 1, y))
    atlas.paste(tile.crop((width - 1, 0, width, height)), (x + width, y))
    atlas.paste(atlas.crop((x - 1, y, x + width + 1, y + 1)), (x - 1, y - 1))
    atlas.paste(atlas.crop((x - 1, y + height - 1, x + width + 1, y + height)), (x - 1, y + height))


def build():
    for theme in ("human", "orc", "undead", "nightelf"):
        version = 3 if theme == "human" else 2
        with Image.open(SOURCE / f"window-{theme}-v{version}.png") as image:
            source = image.convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)
        rail_width = RAIL_WIDTHS[theme]
        corner_width = rail_width * 2
        end = 1024 - corner_width
        rails = (
            source.crop((corner_width, 0, end, rail_width)),
            source.crop((1024 - rail_width, corner_width, 1024, end)).transpose(Image.Transpose.ROTATE_90),
            source.crop((corner_width, 1024 - rail_width, end, 1024)).transpose(Image.Transpose.ROTATE_180),
            source.crop((0, corner_width, rail_width, end)).transpose(Image.Transpose.ROTATE_270),
        )
        corners = (
            source.crop((0, 0, corner_width, corner_width)),
            source.crop((end, 0, 1024, corner_width)),
            source.crop((end, end, 1024, 1024)),
            source.crop((0, end, corner_width, 1024)),
        )
        atlas = Image.new("RGBA", (1024, 512))
        for index, rail in enumerate(rails):
            paste_with_border(atlas, rail.resize((768, 48), Image.Resampling.LANCZOS), 1, 1 + index * 50)
        for index, corner in enumerate(corners):
            paste_with_border(atlas, corner.resize((96, 96), Image.Resampling.LANCZOS), 1 + index * 98, 204)
        output = ART / theme / "chrome"
        atlas.save(output / "window-border-v2.tga", format="TGA")
        panel = source.crop((256, 256, 768, 768)).resize((256, 256), Image.Resampling.LANCZOS)
        panel.save(output / "window-panel-v2.tga", format="TGA")


if __name__ == "__main__":
    build()
