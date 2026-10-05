-- TEST ONLY: minimal Auth/Storage/Vault schema shims for disposable PostgreSQL RLS tests.
-- Vault here is deliberately a test double, not encryption and never production storage.
create role anon; create role authenticated; create role service_role bypassrls;
create schema auth; create schema storage; create schema vault;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text unique);
alter table storage.objects enable row level security;
create function storage.foldername(text) returns text[] language sql immutable as $$ select (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;
grant usage on schema public,auth,storage to authenticated,anon;
grant all on storage.objects to authenticated;
create table vault.secrets(id uuid primary key default gen_random_uuid(), secret text);
create view vault.decrypted_secrets as select id,secret as decrypted_secret from vault.secrets;
create function vault.create_secret(value text) returns uuid language plpgsql as $$ declare key uuid; begin insert into vault.secrets(secret) values(value) returning id into key; return key; end $$;
create function vault.update_secret(key uuid,value text) returns void language sql as $$ update vault.secrets set secret=value where id=key $$;
