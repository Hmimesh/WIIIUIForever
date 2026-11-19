# Window artwork

These four source frames were created with built-in ImageGen for WIIIUI Forever. Each source PNG has its exact generation prompt in the adjacent text file. The Orc prompt records its final edit, which removed an oversized cloth accent.

The Human v3 source corrects the rail lighting and flattens the interior shading. Its v2 source is retained as the earlier design reference.

The direction uses quiet long rails, corner ornament, and subdued panel backings. Human uses steel and slate, Orc uses timber and iron, Forsaken uses gunmetal and bone, and Night Elf uses carved violet wood with silver crescents.

Run `python tools/build-window-borders.py` to normalize the sources and pack four directional rails, four individual corners, and a backing texture per theme. The Lua renderer keeps the corners at a fixed size and crops the last rail segment to the available space.

The source images are design masters. The addon loads the derived TGA assets under each theme's `chrome` directory.
