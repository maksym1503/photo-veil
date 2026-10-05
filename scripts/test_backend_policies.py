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
    shim="""
create role anon; create role authenticated; create role service_role bypassrls;
create schema auth; create schema storage;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text unique);
alter table storage.objects enable row level security;
create function storage.foldername(text) returns text[] language sql immutable as $$ select (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;
grant usage on schema public,auth,storage to authenticated,anon;
grant all on storage.objects to authenticated;
"""
    run(base,input=shim,text=True,stdout=subprocess.DEVNULL)
    run(base+['-f','supabase/migrations/202610050001_veil_gallery.sql'],stdout=subprocess.DEVNULL)
    run(base+['-f','supabase/tests/ownership.sql'])
finally:
    if started: subprocess.run(['pg_ctl','-D',str(root/'db'),'stop','-m','immediate'],stdout=subprocess.DEVNULL)
    shutil.rmtree(root)
