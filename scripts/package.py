"""Create an install-only addon ZIP; never uploads/publishes it."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parents[1]
addon = root / 'LifeForge'
out = root / 'dist' / 'LifeForge_0.6.0-alpha_addon.zip'
out.parent.mkdir(exist_ok=True)
with ZipFile(out, 'w', ZIP_DEFLATED) as z:
    for f in sorted(addon.rglob('*')):
        if f.is_file():
            z.write(f, f.relative_to(root))
print(out, out.stat().st_size, 'bytes')
