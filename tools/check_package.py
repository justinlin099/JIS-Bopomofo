"""Check full package inventory, source equality, runtime bytes and checksums."""
import hashlib
import json
import zipfile
from repository import ROOT, repository_files, runtime_files, version

def check():
    value = version()
    dist = ROOT / 'dist'
    installer = dist / ('jis-bopomofo-' + value + '-windows-x64.zip')
    source_zip = dist / ('jis-bopomofo-' + value + '-source.zip')
    checksum = dist / ('jis-bopomofo-' + value + '-SHA256SUMS.txt')
    expected_hashes = ''.join(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n'
                              for path in [source_zip, installer])
    assert checksum.read_text(encoding='ascii') == expected_hashes, 'Checksum file mismatch'
    paths = repository_files()
    with zipfile.ZipFile(installer) as package, zipfile.ZipFile(source_zip) as source:
        assert package.testzip() is None and source.testzip() is None
        assert len(package.namelist()) == len(set(package.namelist())), 'Duplicate installer entry'
        assert len(source.namelist()) == len(set(source.namelist())), 'Duplicate source entry'
        assert set(source.namelist()) == {'jis-bopomofo/' + path for path in paths}
        extras = {'LICENSE', 'COPYRIGHT', 'THIRD_PARTY_NOTICES.md', 'COMPATIBILITY.md',
                  'INSTALLATION.md', 'README.txt', 'release-manifest.json'}
        expected = set(runtime_files()) | extras | {'source/' + path for path in paths}
        assert set(package.namelist()) == expected, 'Unexpected installer entries'
        for path in paths:
            data = (ROOT / path).read_bytes()
            assert source.read('jis-bopomofo/' + path) == data, path
            assert package.read('source/' + path) == data, path
        for name, relative in runtime_files().items():
            assert package.read(name) == (ROOT / relative).read_bytes(), name
        manifest = json.loads(package.read('release-manifest.json'))
        assert manifest['version'] == value
        assert len(manifest['files']) == len(expected) - 1
        assert {row['file'] for row in manifest['files']} == expected - {'release-manifest.json'}
        for row in manifest['files']:
            data = package.read(row['file'])
            assert len(data) == row['bytes']
            assert hashlib.sha256(data).hexdigest() == row['sha256'], row['file']
        assert b'GPL-3.0-or-later' in package.read('COPYRIGHT')
    print('PASS: ZIP CRC, inventories, corresponding sources, runtime bytes and SHA256 checksums')

if __name__ == '__main__':
    check()
