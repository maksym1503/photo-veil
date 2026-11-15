"""Release must not contain DEBUG analysis implementation or fixture photo resources."""
import plistlib, subprocess, sys
from pathlib import Path
app = Path(sys.argv[1])
assert app.is_dir(), f"Missing Release app: {app}"
manifest = app / 'PrivacyInfo.xcprivacy'
assert manifest.is_file(), 'Release app privacy manifest is missing'
try:
    privacy = plistlib.loads(manifest.read_bytes())
except Exception as error:
    raise AssertionError('Release app privacy manifest is malformed') from error
assert isinstance(privacy, dict) and isinstance(privacy.get('NSPrivacyCollectedDataTypes'), list), 'Invalid app collection declaration'
info = plistlib.loads((app / 'Info.plist').read_bytes())
advertising = info.get('VeilContextualAdvertising', {})
if isinstance(advertising, dict) and advertising.get('Enabled'):
    assert privacy['NSPrivacyCollectedDataTypes'], 'Live advertising requires reviewed collection declarations'
    assert advertising.get('PrivacyReviewApproved') is True, 'Advertising privacy review is missing'
    assert info.get('VeilPrivacyPolicyURL', '').startswith('https://') and info.get('VeilSupportURL', '').startswith('https://'), 'Advertising requires published legal/support URLs'
if (app / 'VeilBackend.plist').exists():
    assert privacy['NSPrivacyCollectedDataTypes'], 'Backend configuration requires reviewed app privacy collection declarations'
fixture_names={p.name for p in (Path(__file__).resolve().parents[2]/'Tests/PhotoVeilUITests/Fixtures').glob('*.jpg')}
assert not any(p.name in fixture_names for p in app.rglob('*')), 'Debug fixture leaked into Release'
assert b'-veil-analysis-fixture' not in (app/'PhotoVeil').read_bytes(), 'Test launch configuration leaked into Release'
assert not any(p.suffix == '.storekit' for p in app.rglob('*')), 'Local StoreKit configuration leaked into Release'
for flag in [b'-veil-storekit-testing', b'-veil-test-storage-id', b'-veil-legacy-usage']:
    assert flag not in (app/'PhotoVeil').read_bytes(), 'Commerce testing override leaked into Release'
symbols = subprocess.check_output(["nm", str(app / "PhotoVeil")], stderr=subprocess.DEVNULL)
assert b"FixturePrivacyAnalyzer" not in symbols, "Test analyzer leaked into Release"
# otool inspects every slice of a universal binary. Check embedded frameworks too:
# a test-only dependency must not be hidden behind an intermediate framework.
binaries = [app / "PhotoVeil"]
for framework in app.rglob('*.framework'):
    info = framework / 'Info.plist'
    name = plistlib.loads(info.read_bytes()).get('CFBundleExecutable') if info.exists() else framework.stem
    assert isinstance(name, str) and name, f'Missing embedded framework executable name: {framework.name}'
    binary = framework / name
    assert binary.is_file(), f'Missing embedded framework executable: {framework.name}'
    binaries.append(binary)
binaries.extend(app.rglob('*.dylib'))
for binary in binaries:
    linkage = subprocess.check_output(['otool', '-L', str(binary)], stderr=subprocess.STDOUT)
    assert b'StoreKitTest.framework/StoreKitTest' not in linkage, f'StoreKitTest linked in Release: {binary.name}'
assert not any(p.name == 'StoreKitTest.framework' for p in app.rglob('*.framework')), 'StoreKitTest embedded in Release'
print("Release: no fixture analyzer, debug photos, local StoreKit fixture, commerce test launch overrides or StoreKitTest linkage; app privacy manifest/configuration guard passed")
