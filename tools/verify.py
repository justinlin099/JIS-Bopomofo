"""Offline consistency checks. Never imports or runs an installer."""
from pathlib import Path
import base64,hashlib,json,re,struct
from urllib.parse import unquote
from repository import repository_files, version
ROOT=Path(__file__).resolve().parents[1]
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 files=repository_files();version()
 for name in files:
  p=ROOT/name
  if p.suffix=='.md':
   for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8-sig')):
    if '://' not in target and not target.startswith('#'):
     relative=unquote(target.split('#')[0])
     assert (p.parent/relative).exists(),'Broken documentation link: '+name+' -> '+target
  if p.suffix.lower() in {'.iso','.vhd','.vhdx','.clixml','.pdb'} or p.name.endswith(('-results.json','.log.txt')):
   raise ValueError('Private/generated artifact in release inventory: '+name)
  if p.suffix.lower()=='.dll':assert name=='prebuilt/JisCoreRouter64.dll'

 manifest=json.loads((ROOT/'validation/source-manifest.json').read_text(encoding='utf-8'))
 for entry in manifest['files']:
  assert digest(ROOT/entry['file'])==entry['sha256'], 'Source changed; review validation provenance: '+entry['file']
 binary=ROOT/'prebuilt/JisCoreRouter64.dll'
 expected=json.loads((ROOT/'prebuilt/manifest.json').read_text(encoding='utf-8'))['sha256']
 assert digest(binary)==expected
 assert expected in (ROOT/'windows/Manage-Jis.ps1').read_text(encoding='utf-8-sig')
 data=binary.read_bytes();pe=struct.unpack_from('<I',data,60)[0]
 assert data[:2]==b'MZ' and data[pe:pe+4]==b'PE\0\0' and struct.unpack_from('<H',data,pe+4)[0]==0x8664
 recipes=json.loads((ROOT/'windows/table7-build-recipes.json').read_text(encoding='utf-8-sig'))
 seen=set()
 for recipe in recipes['recipes']:
  assert recipe['sourceSHA256'] not in seen;seen.add(recipe['sourceSHA256'])
  end=0
  for edit in recipe['edits']:
   before=base64.b64decode(edit['before'],validate=True);after=base64.b64decode(edit['after'],validate=True)
   assert len(before)==len(after)>0 and edit['offset']>=end
   end=edit['offset']+len(before);assert end<=recipe['sourceLength']
  assert len(base64.b64decode(recipe['append'],validate=True))==recipe['outputLength']-recipe['sourceLength']
  assert re.fullmatch(r'ImTcCore-JIS-Table7-[A-Za-z0-9-]+\.dll',recipe['output'])
 assert '9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628' in seen
 evidence=json.loads((ROOT/'validation/cases.json').read_text(encoding='utf-8'))
 assert all(g['cases']==g['passed']==len(g['results']) for g in evidence['groups'])
 assert len(evidence['transactions'])==9 and all(x['passed'] for x in evidence['transactions'])
 for p in ROOT.rglob('*'):
  if not p.is_file() or any(x in {'.git','dist','build','__pycache__'} for x in p.relative_to(ROOT).parts):continue
  assert p.suffix.lower() not in {'.iso','.vhd','.vhdx','.clixml'},'Private VM artifact: '+str(p)
  if p.suffix.lower()=='.dll':assert p==binary,'Only the project-owned validated DLL may be distributed'
 print('PASS: repository inventory, documentation links, pinned sources, router, recipes and validation evidence')
if __name__=='__main__':verify()
