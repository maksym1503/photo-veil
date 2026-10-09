#!/usr/bin/env python3
"""Read-only Codex config/catalog checks. No model turns, product builds or writes."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        sys.exit('Use Python 3.11+ or an environment with tomli installed.')

ROOT = Path(__file__).resolve().parents[1]
ROLES = {'cto', 'engineering_lead', 'developer', 'qa', 'reviewer'}


def run(*args):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise RuntimeError(f'{args[0:3]} failed: {result.stderr.strip()}')
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--schema', type=Path, help='Optional downloaded official config JSON schema; requires jsonschema')
    args = parser.parse_args()
    config = tomllib.loads((ROOT / '.codex/config.toml').read_text())
    roles = {}
    for path in (ROOT / '.codex/agents').glob('*.toml'):
        role = tomllib.loads(path.read_text())
        name = role.get('name')
        if name in roles:
            raise ValueError(f'Duplicate role: {name}')
        for key in ('name', 'description', 'developer_instructions', 'model', 'model_reasoning_effort'):
            if not isinstance(role.get(key), str) or not role[key].strip():
                raise ValueError(f'{path}: missing {key}')
        roles[name] = role
    if set(roles) != ROLES:
        raise ValueError(f'Expected {ROLES}, got {set(roles)}')
    if config['agents']['max_concurrent_threads_per_session'] != 2 or not config['agents']['enabled']:
        raise ValueError('Expected enabled agents with two-child cap')
    for name in ('cto', 'reviewer'):
        if roles[name].get('sandbox_mode') != 'read-only':
            raise ValueError(f'{name} must be read-only')
    if args.schema:
        import jsonschema
        schema = json.loads(args.schema.read_text())
        jsonschema.validate(config, schema)
        for role in roles.values():
            # These two manifest fields are defined by the standalone-agent format.
            jsonschema.validate({k: v for k, v in role.items() if k not in ('name', 'description')}, schema)
        print('Official JSON schema: PASS')
    catalog = {m['slug']: m for m in json.loads(run('codex', 'debug', 'models'))['models']}
    selections = {'root': config, **roles, 'fallback': {
        'model': config['agents']['default_subagent_model'],
        'model_reasoning_effort': config['agents']['default_subagent_reasoning_effort']}}
    for name, settings in selections.items():
        model, effort = settings['model'], settings['model_reasoning_effort']
        if model not in catalog or catalog[model].get('visibility') != 'list':
            raise ValueError(f'{name}: model absent from visible account catalog: {model}')
        if effort not in {r['effort'] for r in catalog[model]['supported_reasoning_levels']}:
            raise ValueError(f'{name}: unsupported reasoning effort: {effort}')
        print(f'{name}: {model}/{effort} catalog PASS')
    doctor = json.loads(run('codex', '--strict-config', 'doctor', '--json'))
    check = doctor['checks']['config.load']
    if check['status'] != 'ok':
        raise ValueError(f'Installed strict config check: {check["summary"]}')
    if check['details'].get('model') != config['model']:
        raise ValueError('Project model not effective; check trust or higher-priority configuration')
    print(f'Installed strict parser and effective root model: PASS ({doctor["codexVersion"]})')
    for key, value in doctor['checks'].items():
        if value['status'] not in ('ok', 'skipped'):
            print(f'Doctor note: {key}: {value["summary"]}')
    prompt = run('codex', 'debug', 'prompt-input', 'Orchestration instruction discovery only')
    if 'Veil engineering instructions' not in prompt:
        raise ValueError('Root AGENTS.md not discovered')
    print('Root instructions discovered: PASS')
    print('Static checks do not prove role invocation. See Documentation/Engineering/VALIDATION.md for live smoke tests.')


if __name__ == '__main__':
    try:
        main()
    except (KeyError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
        sys.exit(str(exc))
