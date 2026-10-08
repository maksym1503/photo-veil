"""Emit actionable native results, raw artifacts remain authoritative."""
import json, subprocess, sys, time
from pathlib import Path
bundle,output,start,status=sys.argv[1:5]
phase=sys.argv[5] if len(sys.argv)>5 else 'test-execution'; out=Path(output);out.mkdir(parents=True,exist_ok=True)
meta={'wall_seconds':round(time.time()-int(start),2),'exit_code':int(status),'bundle':bundle}
if Path(bundle).exists():
 for command,name in [('summary','summary'),('tests','tests')]:
  r=subprocess.run(['xcrun','xcresulttool','get','test-results',command,'--path',bundle],capture_output=True,text=True)
  if r.returncode==0:(out/(name+'.json')).write_text(r.stdout)
 r=subprocess.run(['xcrun','xcresulttool','export','attachments','--path',bundle,'--output-path',str(out/'failure-attachments'),'--only-failures'],capture_output=True,text=True)
 (out/'attachment-export.log').write_text(r.stdout+r.stderr)
meta['phase']=phase
(out/'timing.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta))
if (out/'summary.json').exists():print((out/'summary.json').read_text())

if int(status) and not (out/'summary.json').exists():
 log=out/('build.log' if phase=='compilation' else 'tests.log')
 if log.exists():print('Failure log tail:\n'+'\n'.join(log.read_text(errors='replace').splitlines()[-50:]))
summary_path=out/'summary.json'
contexts=[]
if summary_path.exists():
 summary=json.loads(summary_path.read_text())
 for failure in summary.get('testFailures',[]):
  identity=' '.join(str(failure.get(k,'')) for k in ['testName','testIdentifier','targetName'])
  if 'PrivacyImageRendererTests' in identity:layer='rendering / pixel parity'
  elif 'VisionIntegrationTests' in identity:layer='real Vision integration'
  elif 'UITests' in identity or 'AcceptanceTests' in identity:layer='UI / system integration (inspect state and native evidence)'
  else:layer='core / state / persistence'
  contexts.append({'layer':layer,'failure':failure})
if int(status) and not contexts:
 contexts.append({'layer':phase+' / infrastructure','note':'No assertion identity available; inspect native build/test logs, do not infer product success'})
(out/'failure-context.json').write_text(json.dumps(contexts,indent=2)+'\n')
