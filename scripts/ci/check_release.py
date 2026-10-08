"""Release must not contain DEBUG analysis implementation or fixture photo resources."""
import subprocess, sys
from pathlib import Path
app = Path(sys.argv[1])
assert app.is_dir(), f"Missing Release app: {app}"
fixture_names={p.name for p in (Path(__file__).resolve().parents[2]/'Tests/PhotoVeilUITests/Fixtures').glob('*.jpg')}
assert not any(p.name in fixture_names for p in app.rglob('*')), 'Debug fixture leaked into Release'
assert b'-veil-analysis-fixture' not in (app/'PhotoVeil').read_bytes(), 'Test launch configuration leaked into Release'
symbols = subprocess.check_output(["nm", str(app / "PhotoVeil")], stderr=subprocess.DEVNULL)
assert b"FixturePrivacyAnalyzer" not in symbols, "Test analyzer leaked into Release"
print("Release: no fixture analyzer or bundled debug photo fixtures")
