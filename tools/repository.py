"""Explicit distribution inventory; no Git or installer execution required."""
import json
import re
from pathlib import Path, PurePosixPath
ROOT = Path(__file__).resolve().parents[1]

def repository_files():
    inventory = json.loads((ROOT / 'tools/repository-files.json').read_text(encoding='utf-8'))
    if inventory['format'] != 1:
        raise ValueError('Unsupported repository inventory')
    files = inventory['files']
    if files != sorted(set(files)):
        raise ValueError('Inventory must be sorted and unique')
    for name in files:
        path = PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or chr(92) in name or ':' in name:
            raise ValueError('Unsafe distribution path: ' + name)
        local = ROOT / name
        if not local.is_file() or local.is_symlink():
            raise ValueError('Missing or symlinked distribution file: ' + name)
        if local.resolve() != ROOT.resolve().joinpath(*path.parts):
            raise ValueError('Path resolves outside distribution inventory: ' + name)
    return files

def runtime_files():
    manifest = json.loads((ROOT / 'validation/source-manifest.json').read_text(encoding='utf-8'))
    files = {Path(row['file']).name: row['file']
             for row in manifest['files'] if row['file'].startswith('windows/')}
    files['JisCoreRouter64.dll'] = 'prebuilt/JisCoreRouter64.dll'
    return files

def version():
    value = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', value):
        raise ValueError('VERSION must contain a numeric semantic version')
    return value
