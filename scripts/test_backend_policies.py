"""Real PostgreSQL RLS tests with minimal local Auth/Storage schema shims.
This does not replace real Supabase Storage API/provider integration tests.
Only creates/removes an isolated temporary cluster; never connects to an existing database.
"""
import pathlib, shutil, socket, subprocess, tempfile
root = pathlib.Path(tempfile.mkdtemp(prefix='veil-v4-policies-'))
with socket.socket() as s:
    s.bind(('127.0.0.1',0)); port=s.getsockname()[1]
def run(args, **kwargs): return subprocess.run(args, check=True, **kwargs)
started=False
try:
    run(['initdb','-D',str(root/'db'),'-A','trust','--no-locale'],stdout=subprocess.DEVNULL)
    run(['pg_ctl','-D',str(root/'db'),'-l',str(root/'postgres.log'),'-o',f'-p {port} -h 127.0.0.1 -k {root}','start'],stdout=subprocess.DEVNULL);started=True
    base=['psql','-h','127.0.0.1','-p',str(port),'-d','postgres','-v','ON_ERROR_STOP=1']
    shim=pathlib.Path('scripts/backend_shim.sql').read_text()
    run(base,input=shim,text=True,stdout=subprocess.DEVNULL)
    run(base+['-f','supabase/migrations/202610050001_veil_gallery.sql'],stdout=subprocess.DEVNULL)
    run(base,input=pathlib.Path('supabase/migrations/202610050002_apple_revocation.sql').read_text().replace('create extension if not exists supabase_vault with schema vault;',''),text=True,stdout=subprocess.DEVNULL)
    run(base+['-f','supabase/tests/ownership.sql'])
    run(base+['-f','supabase/tests/vault_privileges.sql'])
finally:
    if started: subprocess.run(['pg_ctl','-D',str(root/'db'),'stop','-m','immediate'],stdout=subprocess.DEVNULL)
    shutil.rmtree(root)
