#!/usr/bin/env python3
"""Build a manual-install archive containing this mod, its UI dependency and licenses."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
output = root / 'artifacts/HearYourFriends-experimental.zip'
output.parent.mkdir(exist_ok=True)
files = [p for p in (root / 'Mods').rglob('*') if p.is_file() and p.name != 'HearYourFriends-report.json']
files += [root / 'README.md', root / 'LICENSE']
with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
    for path in sorted(files):
        archive.write(path, path.relative_to(root))
with ZipFile(output) as archive:
    assert archive.testzip() is None, 'Archive CRC verification failed'
    assert 'Mods/HearYourFriends/Scripts/config.lua' in archive.namelist()
    assert 'Mods/shared/ModMenu/LICENSE' in archive.namelist()
print(output)
