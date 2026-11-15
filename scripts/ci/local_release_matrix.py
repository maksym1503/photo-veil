"""Local Intel-host runtime compatibility check; never changes canonical test plans."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
NATIVE_UI = 'VeilCommerceUITests/testNativeTrialUnlocksExportsAndSurvivesAppRestart()'


def inventory():
    rows = json.loads((ROOT / 'Documentation/CI/test-inventory.json').read_text())
    expected = {r['id']: r for r in rows
                if r['file'].startswith(('Tests/PhotoVeilTests/', 'Tests/PhotoVeilIntegrationTests/',
                                         'Tests/PhotoVeilCommerceTests/', 'Tests/PhotoVeilUITests/'))
                and not r['id'].startswith('DetectionBenchmarkTests/')}
    assert len(expected) == 153, 'Reassess matrix when canonical inventory changes'
    return expected


def assigned(shard):
    assert shard in ('26.1', '26.5')
    return {key: row for key, row in inventory().items()
            if (key.startswith('StoreKitSubscriptionTests/') or key == NATIVE_UI) == (shard == '26.1')}


def fingerprint(derived):
    source = hashlib.sha256()
    for base in ('Sources', 'Tests', 'Configuration', 'PhotoVeil.xcodeproj'):
        for path in sorted((ROOT / base).rglob('*')):
            if path.is_file() and 'xcuserdata' not in path.parts:
                source.update(str(path.relative_to(ROOT)).encode())
                source.update(path.read_bytes())
    root_inputs = [ROOT / name for name in ('Package.swift', 'PhotoVeilInfo.plist', 'PrivacyInfo.xcprivacy', 'Documentation/CI/test-inventory.json', 'scripts/ci/local_release_matrix.py')]
    for path in root_inputs:
        source.update(str(path.relative_to(ROOT)).encode()); source.update(path.read_bytes())
    for path in sorted(ROOT.glob('*.xctestplan')):
        source.update(path.name.encode()); source.update(path.read_bytes())
    products = Path(derived) / 'Build/Products'
    build = hashlib.sha256()
    inputs = 0
    for path in sorted(products.rglob('*')):
        if path.is_file() and (path.suffix in ('.xctestrun', '.xctest', '.dylib') or
                               (path.parent.suffix in ('.app', '.xctest') and not path.suffix)):
            inputs += 1
            build.update(str(path.relative_to(products)).encode()); build.update(path.read_bytes())
    assert products.exists() and inputs > 0, 'Missing build products / executable provenance'
    return {'source_sha256': source.hexdigest(), 'build_sha256': build.hexdigest()}


def nodes(value):
    if isinstance(value, dict):
        if value.get('nodeType') == 'Test Case':
            yield value
        for child in value.values(): yield from nodes(child)
    elif isinstance(value, list):
        for child in value: yield from nodes(child)


def result(bundle, name):
    return json.loads(subprocess.check_output(
        ['xcrun', 'xcresulttool', 'get', 'test-results', name, '--path', str(bundle)]))


mode, *args = sys.argv[1:]
if mode == 'selectors':
    for key, row in sorted(assigned(args[0]).items()):
        target = {'StoreKitSubscriptionTests': 'PhotoVeilCommerceTests',
                  'VeilCommerceUITests': 'PhotoVeilUITests',
                  'PhotoVeilUITests': 'PhotoVeilUITests',
                  'VeilPRSmokeTests': 'PhotoVeilPRUITests'}.get(key.split('/')[0])
        if target is None:
            target = 'PhotoVeilCoreTests'
        print('-only-testing:' + target + '/' + key.removesuffix('()'))
elif mode == 'fingerprint':
    print(json.dumps(fingerprint(args[0]), indent=2))
elif mode == 'verify':
    directory = Path(args[0]); seen = set(); reports = []
    fingerprints = [json.loads((directory / f'{s}-before.json').read_text()) for s in ('26.1', '26.5')]
    assert fingerprints[0] == fingerprints[1], 'Shards have different source/build provenance'
    for shard in ('26.1', '26.5'):
        assert json.loads((directory / f'{shard}-after.json').read_text()) == fingerprints[0], 'Source/build changed during execution'
        bundle = directory / f'{shard}.xcresult'
        summary = result(bundle, 'summary'); cases = list(nodes(result(bundle, 'tests')))
        actual = [n['nodeIdentifier'] for n in cases]; wanted = set(assigned(shard))
        assert len(actual) == len(set(actual)), 'Repeated case / retry'
        assert set(actual) == wanted, f'{shard}: missing={wanted-set(actual)}, unexpected={set(actual)-wanted}'
        assert all(n['result'] == 'Passed' for n in cases), f'{shard}: failed assigned case'
        for case in cases:
            detail = json.loads(subprocess.check_output(['xcrun', 'xcresulttool', 'get', 'test-results', 'test-details', '--path', str(bundle), '--test-id', case['nodeIdentifier']]))
            assert detail['testDescription'] == 'Test case with 1 run', 'Case repeated / retried'
            assert detail['testResult'] == 'Passed'
        assert summary['result'] == 'Passed'
        for key in ('failedTests', 'skippedTests', 'expectedFailures'): assert summary[key] == 0
        assert summary['passedTests'] == len(wanted)
        configs = summary['devicesAndConfigurations']; assert len(configs) == 1, 'Expected one destination/configuration'
        for config in configs:
            assert config['passedTests'] == len(wanted)
            for key in ('failedTests', 'skippedTests', 'expectedFailures'): assert config[key] == 0
        device = configs[0]['device']
        assert device['osVersion'] == shard, 'Incorrect assigned runtime'
        assert device['platform'] == 'iOS Simulator', 'Incorrect destination platform'
        assert device.get('architecture') and device.get('modelName'), 'Missing device provenance'
        assert not (seen & wanted); seen |= wanted
        reports.append({'runtime': shard, 'passed': len(wanted), 'bundle': str(bundle), 'configurations': configs})
    assert seen == set(inventory())
    report = {'status': 'PASS', 'scope': f'{len(seen)}/{len(inventory())} across documented local compatibility matrix; not a single-runtime Integration pass',
              'unique_cases': len(seen), 'provenance': fingerprints[0], 'shards': reports}
    (directory / 'matrix-result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
else:
    raise SystemExit('Use selectors <26.1|26.5>, fingerprint <derived>, verify <directory>')
