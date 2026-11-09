"""Prepare a local review kit, without uploading or choosing a project license."""
from pathlib import Path
import hashlib
import json
import re
import runpy
import shutil
import struct
import subprocess


def prepare():
    root = Path(__file__).resolve().parents[1]
    draft = root / "docs" / "curseforge"
    metadata = json.loads((draft / "project.json").read_text(encoding="utf-8"))
    metadata["sourceCommit"] = subprocess.check_output(
        ["git", "rev-parse", metadata["sourceCommit"]], cwd=root
    ).decode("ascii").strip()
    archive = runpy.run_path(str(root / "tools" / "package-wiiiui.py"))["build"]()
    if metadata["fileName"] != archive.name:
        raise ValueError("Listing filename does not match the verified addon version")
    if metadata["releaseType"] != "Alpha" or metadata["interface"] != 16001:
        raise ValueError("Review release type and target client before preparing")
    version = archive.stem.removeprefix("WIIIUIForever-")
    if version not in (draft / "CHANGELOG.md").read_text(encoding="utf-8"):
        raise ValueError("Listing changelog version is stale")
    committed_toc = subprocess.check_output(
        ["git", "show", f'{metadata["sourceCommit"]}:WIIIUIForever/WIIIUIForever.toc'], cwd=root
    ).decode("utf-8-sig")
    if not re.search(rf"^## Version:\s*{re.escape(version)}\s*$", committed_toc, re.M):
        raise ValueError("Listing source commit does not identify this version")
    committed_names = subprocess.check_output(
        ["git", "ls-tree", "-r", "--name-only", metadata["sourceCommit"], "--", "WIIIUIForever"], cwd=root
    ).decode("utf-8").splitlines()
    disk_names = {path.relative_to(root).as_posix() for path in (root / "WIIIUIForever").rglob("*") if path.is_file()}
    if set(committed_names) != disk_names:
        raise ValueError("Installable file list differs from the declared source commit")
    for name in committed_names:
        data = subprocess.check_output(["git", "show", f'{metadata["sourceCommit"]}:{name}'], cwd=root)
        if data != (root / name).read_bytes():
            raise ValueError(f"Uncommitted installable changes: {name}")

    avatar = (draft / metadata["projectAvatar"]).read_bytes()
    if avatar[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", avatar[16:24]) != (400, 400):
        raise ValueError("Project avatar must be a 400 x 400 PNG")
    output = root / "dist" / f"curseforge-{version}"
    output.mkdir(parents=True, exist_ok=True)
    for path in (archive, archive.with_suffix(".zip.sha256")):
        shutil.copy2(path, output / path.name)
    for name in ("DESCRIPTION.md", "CHANGELOG.md", "avatar-candidate.png", "avatar-candidate.svg"):
        shutil.copy2(draft / name, output / name)
    (output / "project.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    shutil.copy2(root / "LICENSE.md", output / "LICENSE.md")
    gallery = json.loads((draft / "gallery.json").read_text(encoding="utf-8"))
    (output / "gallery").mkdir(exist_ok=True)
    for entry in gallery:
        source = (draft / entry["file"]).resolve()
        if not source.is_relative_to(root / "docs" / "screenshots") or not source.is_file():
            raise ValueError(f"Invalid gallery source: {source}")
        shutil.copy2(source, output / "gallery" / source.name)
        entry["file"] = f"gallery/{source.name}"
    (output / "gallery.json").write_text(json.dumps(gallery, indent=2) + "\n", encoding="utf-8")
    (output / "START-HERE.txt").write_text(
        "WIIIUI Forever - CurseForge review kit\n\n"
        f"Upload only {archive.name} as the addon file.\n"
        "Use DESCRIPTION.md, CHANGELOG.md, project.json and gallery.json for listing fields.\n"
        "The 400x400 avatar is a candidate for maintainer review. The in-game icon is unchanged.\n"
        "Release type: Alpha. Flavor: Forever. Game version: 1.60.1.\n"
        "License: MIT for original code only; third-party artwork and upstream material are excluded.\n"
        "Do not upload this entire review folder as an addon.\n"
        "Nothing in this kit creates a project, sends a message, or uploads a file.\n",
        encoding="utf-8",
    )
    files = [path for path in sorted(output.rglob("*")) if path.is_file() and path.name != "manifest.json"]
    manifest = {
        "sourceCommit": metadata["sourceCommit"], "addonVersion": version,
        "files": [{"path": path.relative_to(output).as_posix(), "bytes": path.stat().st_size,
                   "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in files],
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for entry in manifest["files"]:
        if hashlib.sha256((output / entry["path"]).read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError(f'Kit copy mismatch: {entry["path"]}')
    print(f"Verified review kit: {output} ({len(files)} files plus manifest)")
    print("MIT selected for original code; project avatar review remains pending. No upload performed.")
    return output


if __name__ == "__main__":
    prepare()
