"""Coverage assignment and privacy guardrails, cheap enough for every PR."""
import json,re,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
rows=json.loads((root/'Documentation/CI/test-inventory.json').read_text()); inventory={r['id'] for r in rows}
actual=set()
for p in (root/'Tests').rglob('*.swift'):
 s=p.read_text();cls=re.search(r'(?:final )?class (\w+): XCTestCase',s)
 if cls:actual.update(cls[1]+'/'+n+'()' for n in re.findall(r'func (test\w+)\(',s))
assert actual==inventory, f'Test inventory drift: new={actual-inventory}, stale={inventory-actual}'
pr=json.loads((root/'VeilPR.xctestplan').read_text());integration=json.loads((root/'VeilIntegration.xctestplan').read_text())
assert len(pr['testTargets'])==2
assert any(t['target']['name']=='PhotoVeilUITests' and not t['parallelizable'] for t in integration['testTargets'])
assert 'VisionIntegrationTests' not in pr['testTargets'][0]['selectedTests']
assert all(r['layer'] in ['PR Gate','Integration','Real Device','Backend'] for r in rows)
# Scan index content, not owner-local ignored files. Do not print matched secret material.
for name in subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0'):
 if not name:continue
 data=subprocess.check_output(['git','show',':'+name],cwd=root)
 if name == 'Tests/PhotoVeilTests/BackendConfigurationTests.swift':
  data=data.replace(b'sb_secret_' + b'TEST_ONLY_PRIVATE_VALUE', b'REDACTED_TEST_SENTINEL')
 assert not re.search(rb'sb_secret_[A-Za-z0-9_-]{20,}',data), f'Server secret-like content: {name}'
 assert not name.endswith(('.p8','.p12','.mobileprovision')), f'Signing material tracked: {name}'
 assert name != 'Configuration/VeilBackend.plist', 'Owner backend configuration tracked'
 assert not re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}',data), f'Secret-like content: {name}'
# Enforce actual test-plan homes, not only a complete-looking spreadsheet.
def selected(plan, target):
    return next(t for t in plan['testTargets'] if t['target']['name'] == target)
assert 'skippedTests' not in selected(integration, 'PhotoVeilUITests')
assert 'selectedTests' not in selected(integration, 'PhotoVeilUITests'), 'All existing UI cases must remain included'
assert 'selectedTests' not in selected(integration, 'PhotoVeilCoreTests')
assert 'skippedTests' not in selected(integration, 'PhotoVeilCoreTests')
pr_classes=set(selected(pr,'PhotoVeilCoreTests')['selectedTests'] + selected(pr,'PhotoVeilPRUITests')['selectedTests'])
assigned={r['id'].split('/')[0] for r in rows if r['layer']=='PR Gate'}
assert pr_classes==assigned, f'PR plan/inventory differ: {pr_classes ^ assigned}'
assert all(r['deterministic'] and not r['real_vision'] and not r['system_ui'] for r in rows if r['blocks_pr'])
assert sum(r.get('baseline',False) for r in rows)==85, 'Preserve the full pre-migration baseline'
device=json.loads((root/'VeilDevice.xctestplan').read_text())
assert selected(device,'PhotoVeilPRUITests')['selectedTests']==['VeilDeviceAcceptanceTests']
assert 'VeilDeviceAcceptanceTests' not in pr_classes
assert len(inventory)==len(rows), 'Duplicate inventory ID'
# Native core source membership must not silently lose a source file.
import plistlib
project=plistlib.loads((root/'PhotoVeil.xcodeproj/project.pbxproj').read_bytes())['objects']
core=next(v for v in project.values() if v.get('isa')=='PBXNativeTarget' and v['name']=='PhotoVeilCoreTests')
phase=next(project[p] for p in core['buildPhases'] if project[p]['isa']=='PBXSourcesBuildPhase')
paths={project[project[b]['fileRef']]['path'] for b in phase['files']}
expected={r['file'] for r in rows if r['file'].startswith(('Tests/PhotoVeilTests/','Tests/PhotoVeilIntegrationTests/')) and not r['id'].startswith('DetectionBenchmarkTests/')}
assert paths==expected, f'Native core source drift: {paths ^ expected}'

indexed=plistlib.loads(subprocess.check_output(['git','show',':PhotoVeil.xcodeproj/project.pbxproj'],cwd=root))['objects']
assert not any(v.get('buildSettings',{}).get('DEVELOPMENT_TEAM') for v in indexed.values()), 'Owner-local signing team must not be committed'
print(f'Inventory complete: {len(actual)} Swift tests. PR plan excludes real Vision/system UI; legacy integration retained.')
