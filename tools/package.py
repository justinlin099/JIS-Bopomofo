"""Create deterministic source and Windows ZIPs from an explicit inventory."""
import hashlib
import json
import zipfile
from repository import ROOT, repository_files, runtime_files, version
from verify import verify
STAMP = (2026, 9, 12, 0, 0, 0)

def write_zip(path, files):
    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, STAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data)
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('ZIP CRC verification failed: ' + path.name)

def main():
    verify()
    release_version = version()
    source = {name: (ROOT / name).read_bytes() for name in repository_files()}
    files = {name: (ROOT / relative).read_bytes()
             for name, relative in runtime_files().items()}
    for name in ['LICENSE', 'COPYRIGHT', 'THIRD_PARTY_NOTICES.md']:
        files[name] = source[name]
    files['COMPATIBILITY.md'] = source['docs/COMPATIBILITY.md']
    files['INSTALLATION.md'] = source['docs/INSTALLATION.md']
    files['README.txt'] = """JIS Bopomofo

Read INSTALLATION.md and COMPATIBILITY.md before installing.
Extract ALL files into a new writable folder.
Right-click Install.cmd, choose Run as administrator, then restart Windows.
Install-Spaces.cmd installs only the two additional Space keys.
Restore.cmd restores both features; Restore-Spaces.cmd restores only Space keys.
Check.cmd and Diagnose.cmd write read-only system reports to this folder.
Retain the Fujitsu-JIS-Core and Fujitsu-JIS-SpaceKeys ProgramData backups.

License: GPL-3.0-or-later. Corresponding project source is included in source/.
Microsoft Windows components are not distributed with this package.
""".encode('utf-8')
    files.update({'source/' + name: data for name, data in source.items()})
    manifest = [{'file': name, 'bytes': len(data),
                 'sha256': hashlib.sha256(data).hexdigest()}
                for name, data in sorted(files.items())]
    files['release-manifest.json'] = json.dumps(
        {'version': release_version, 'files': manifest}, indent=2).encode('utf-8')
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    installer = dist / ('jis-bopomofo-' + release_version + '-windows-x64.zip')
    source_zip = dist / ('jis-bopomofo-' + release_version + '-source.zip')
    write_zip(installer, files)
    write_zip(source_zip, {'jis-bopomofo/' + name: data for name, data in source.items()})
    hashes = ''.join(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n'
                     for path in [source_zip, installer])
    checksum = dist / ('jis-bopomofo-' + release_version + '-SHA256SUMS.txt')
    checksum.write_text(hashes, encoding='ascii')
    print(hashes.strip())
    print('Release files written to dist/. No system settings changed.')

if __name__ == '__main__':
    main()
