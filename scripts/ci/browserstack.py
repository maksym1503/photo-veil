"""Opt-in real-device pilot. Upload only owner-approved fixture-only signed builds.
No credentials in arguments, subprocesses, logs, or repository configuration.
"""
import base64, json, os, subprocess, sys, time, urllib.request
from pathlib import Path
base = 'https://api-cloud.browserstack.com/app-automate/xcuitest/v2/'
user, key = os.environ['BROWSERSTACK_USERNAME'], os.environ['BROWSERSTACK_ACCESS_KEY']
assert not any(c in user + key for c in '\r\n'), 'Invalid credential format'
auth = 'Basic ' + base64.b64encode((user + ':' + key).encode()).decode()
out = Path(os.environ.get('VEIL_DEVICE_OUTPUT', '/tmp/veil-device')); out.mkdir(parents=True, exist_ok=True)
def request(route, payload=None):
    req = urllib.request.Request(base + route, data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Authorization': auth, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=90) as response: return json.load(response)
def upload(route, path, field):
    path = Path(path).resolve(); assert path.is_file()
    # curl streams large signed archives; credential remains only on stdin.
    credential = (user + ':' + key).replace('\\', '\\\\').replace('"', '\\"')
    command = ['curl', '--fail', '--silent', '--show-error', '--max-time', '300', '--config', '-',
        '--request', 'POST', base + route, '--form', 'file=@' + str(path)]
    result = subprocess.run(command, input='user = "' + credential + '"\n', capture_output=True, text=True)
    if result.returncode: raise RuntimeError('Provider upload failed; inspect provider availability/credentials without printing secrets')
    return json.loads(result.stdout)[field]
if len(sys.argv) == 3:
    app = upload('app', sys.argv[1], 'app_url')
    suite = upload('test-suite', sys.argv[2], 'test_url')
else:
    # Owner-uploaded artifacts stay inside the provider, never public GitHub artifacts.
    app, suite = os.environ['BROWSERSTACK_APP_URL'], os.environ['BROWSERSTACK_TEST_SUITE_URL']
    assert os.environ['BROWSERSTACK_BUILD_SHA'] == os.environ['GITHUB_SHA'], 'Approved build SHA differs from candidate'
assert app.startswith('bs://') and suite.startswith('bs://'), 'Invalid provider artifact reference'
created = request('build', {'app': app, 'testSuite': suite, 'devices': [os.environ['VEIL_DEVICE']],
    'project': 'Veil device acceptance', 'only-testing': ['VeilDeviceAcceptanceTests'],
    'enableResultBundle': True, 'networkLogs': False})
build_id = created['build_id']; print('Submitted real-device acceptance build:', build_id, flush=True)
deadline = time.monotonic() + 1800
while time.monotonic() < deadline:
    result = request('builds/' + build_id)
    evidence = {k: result[k] for k in ['status','duration'] if k in result}
    evidence['build_id'] = build_id
    evidence['case_counts'] = [s.get('testcases', {}) for d in result.get('devices', []) for s in d.get('sessions', [])]
    (out / 'provider-result.json').write_text(json.dumps(evidence, indent=2) + '\n')
    status = result.get('status'); print('Device acceptance status:', status, flush=True)
    if status in ('failed', 'timeout', 'error', 'cancelled'): sys.exit(1)
    # Some API versions use 'done': it is NOT sufficient without positive case counts.
    if status in ('passed', 'done'):
        cases = [s['testcases'] for d in result.get('devices', []) for s in d.get('sessions', [])]
        okay = cases and all(c['count'] > 0 and c['status'].get('passed', 0) == c['count'] for c in cases)
        sys.exit(0 if okay else 1)
    time.sleep(15)
raise TimeoutError('Provider acceptance exceeded its 30-minute bound; cancel in provider dashboard and inspect last result')
