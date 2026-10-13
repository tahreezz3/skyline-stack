#!/usr/bin/env python3
"""Fail if any file in game/ or assets_inbox/ is byte-identical to a file in the
reference extraction (../extracted). Skips silently if the extraction is absent.
This catches accidental copies only; see docs/07_LEGAL_CLEANROOM.md."""
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT.parent / "extracted"
MIN_SIZE = 64          # ignore tiny files (empty json, etc.)
MEDIA = {".png", ".jpg", ".jpeg", ".wav", ".ogg", ".mp3", ".ttf", ".otf", ".obj", ".json", ".txt", ".csv"}


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def files(base: Path, exts=None):
    for p in base.rglob("*"):
        if p.is_file() and p.stat().st_size >= MIN_SIZE and (exts is None or p.suffix.lower() in exts):
            yield p


def main() -> int:
    if not REFERENCE.exists():
        print("clean-room: reference extraction not present, skipped")
        return 0
    ours = {}
    for base in (ROOT / "game", ROOT / "assets_inbox"):
        if base.exists():
            for p in files(base):
                if ".godot" in p.parts:
                    continue
                ours.setdefault(p.stat().st_size, []).append(p)
    hits = []
    for ref in files(REFERENCE, MEDIA):
        cands = ours.get(ref.stat().st_size)
        if not cands:
            continue
        rh = sha(ref)
        for c in cands:
            if sha(c) == rh:
                hits.append((c, ref))
    for c, ref in hits:
        print(f"clean-room VIOLATION: {c.relative_to(ROOT)} is identical to {ref}")
    print("clean-room: OK" if not hits else f"clean-room: {len(hits)} violation(s)")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
