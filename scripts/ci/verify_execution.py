"""Fail closed if discovery/plan drift yields a green run with missing or skipped tests."""
import json, subprocess, sys
from pathlib import Path
plan,bundle=sys.argv[1:];plan=plan.removesuffix('.xctestplan')
root=Path(__file__).resolve().parents[2]
rows=json.loads((root/'Documentation/CI/test-inventory.json').read_text())
if plan=='VeilPR':expected={r['id'] for r in rows if r['layer']=='PR Gate'}
elif plan=='VeilIntegration':
 expected={r['id'] for r in rows if r['file'].startswith(('Tests/PhotoVeilTests/','Tests/PhotoVeilIntegrationTests/','Tests/PhotoVeilUITests/')) and not r['id'].startswith('DetectionBenchmarkTests/')}
elif plan=='VeilDevice':expected={r['id'] for r in rows if r['layer']=='Real Device'}
else:raise ValueError('Unknown test plan')
def get(name):
 return json.loads(subprocess.check_output(['xcrun','xcresulttool','get','test-results',name,'--path',bundle]))
def cases(value):
 if isinstance(value,dict):
  if value.get('nodeType')=='Test Case':yield value
  for child in value.values():yield from cases(child)
 elif isinstance(value,list):
  for child in value:yield from cases(child)
summary=get('summary');nodes=list(cases(get('tests')));actual={n['nodeIdentifier'] for n in nodes}
assert expected and actual==expected, f'Execution inventory mismatch: missing={expected-actual}, unexpected={actual-expected}'
assert all(n['result']=='Passed' for n in nodes), 'A required case did not pass'
assert summary['result']=='Passed' and summary['failedTests']==0 and summary['skippedTests']==0 and summary['expectedFailures']==0
configs=summary['devicesAndConfigurations'];assert configs, 'No validated destination'
for config in configs:
 assert config['passedTests']==len(expected) and config['failedTests']==0 and config['skippedTests']==0 and config['expectedFailures']==0, 'Destination/configuration has incomplete coverage'
print(f'Execution inventory verified: {plan}, {len(expected)} required cases per destination, no missing/skipped/expected failures')
