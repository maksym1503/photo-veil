"""Register V4 sources/resources without changing owner signing settings."""
import hashlib, plistlib
from pathlib import Path
p=Path('PhotoVeil.xcodeproj/project.pbxproj')
d=plistlib.loads(p.read_bytes());o=d['objects']
def ident(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
project=next(v for v in o.values() if v.get('isa')=='PBXProject')
root=o[project['mainGroup']]
target=next(v for v in o.values() if v.get('isa')=='PBXNativeTarget' and v['name']=='PhotoVeil')
phase=next(o[k] for k in target['buildPhases'] if o[k]['isa']=='PBXSourcesBuildPhase')
for path in sorted(Path('Sources/PhotoVeil').glob('*.swift')):
    name=str(path)
    if any(v.get('isa')=='PBXFileReference' and v.get('path')==name for v in o.values()): continue
    ref,build=ident(name),ident(name+'build')
    o[ref]={'isa':'PBXFileReference','lastKnownFileType':'sourcecode.swift','path':name,'sourceTree':'SOURCE_ROOT'}
    o[build]={'isa':'PBXBuildFile','fileRef':ref};root['children'].append(ref);phase['files'].append(build)
p.write_bytes(plistlib.dumps(d,sort_keys=False))
