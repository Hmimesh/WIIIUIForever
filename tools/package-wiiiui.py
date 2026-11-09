"""Build and verify a standalone WIIIUI Forever upload ZIP.

Run from any directory: python tools/package-wiiiui.py
Only the installable WIIIUIForever folder is included.
"""
from pathlib import Path
import hashlib
import re
import stat
import zipfile


def build():
    root = Path(__file__).resolve().parents[1]
    addon = root / "WIIIUIForever"
    toc = (addon / "WIIIUIForever.toc").read_text(encoding="utf-8-sig")
    version_match = re.search(r"^## Version:\s*([A-Za-z0-9._-]+)\s*$", toc, re.M)
    if not version_match:
        raise ValueError("TOC has no valid Version metadata")
    version = version_match[1]
    for line in toc.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            if not (addon / line.replace("\\", "/")).is_file():
                raise ValueError(f"TOC references a missing file: {line}")
    icon_match = re.search(r"^## IconTexture:\s*Interface\\AddOns\\WIIIUIForever\\(.+)$", toc, re.M)
    if not icon_match or not (addon / icon_match[1].strip().replace("\\", "/")).is_file():
        raise ValueError("TOC addon icon is missing")

    files = sorted(path for path in addon.rglob("*") if path.is_file())
    allowed = {".lua", ".toc", ".tga", ".blp", ".txt"}
    for path in files:
        if path.is_symlink() or path.suffix.lower() not in allowed:
            raise ValueError(f"Unexpected package file: {path.relative_to(addon)}")
    output = root / "dist"
    output.mkdir(exist_ok=True)
    archive = output / f"WIIIUIForever-{version}.zip"
    expected = {}
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for path in files:
            name = f"WIIIUIForever/{path.relative_to(addon).as_posix()}"
            data = path.read_bytes()
            expected[name] = hashlib.sha256(data).hexdigest()
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            package.writestr(info, data, compresslevel=9)
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None or set(package.namelist()) != set(expected):
            raise ValueError("ZIP integrity or file list validation failed")
        for name, checksum in expected.items():
            if hashlib.sha256(package.read(name)).hexdigest() != checksum:
                raise ValueError(f"ZIP content mismatch: {name}")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    print(f"Verified {len(files)} files in {archive}")
    print(f"SHA256 {digest}")
    return archive


if __name__ == "__main__":
    build()
