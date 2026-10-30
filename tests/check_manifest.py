from pathlib import Path
root=Path(__file__).resolve().parents[1]/'LifeForge'
toc=(root/'LifeForge.toc').read_text(encoding='utf-8')
assert '## Interface: 16001' in toc
files=[]
for raw in toc.splitlines():
    raw=raw.strip()
    if raw and not raw.startswith('#'):
        f=root/Path(raw.replace('\\','/'))
        assert f.is_file(), f'Missing TOC path: {f}'
        files.append(str(f))
assert len(files)==24, len(files)
print('OK:',len(files),'addon files referenced by manifest')