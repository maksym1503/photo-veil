-- Run on a disposable local Supabase database (or documented schema-shim test cluster).
begin;
insert into auth.users(id) values('cccccccc-cccc-cccc-cccc-cccccccccccc');
set local role authenticated;
do $$ begin
  begin
    perform public.veil_apple_refresh('cccccccc-cccc-cccc-cccc-cccccccccccc');
    raise exception 'authenticated client can read provider token';
  exception when insufficient_privilege then null; end;
  begin
    perform public.veil_store_apple_refresh('cccccccc-cccc-cccc-cccc-cccccccccccc','TEST-ONLY');
    raise exception 'authenticated client can write provider token';
  exception when insufficient_privilege then null; end;
end $$;
set local role service_role;
select public.veil_store_apple_refresh('cccccccc-cccc-cccc-cccc-cccccccccccc','TEST-ONLY');
do $$ begin
  if public.veil_apple_refresh('cccccccc-cccc-cccc-cccc-cccccccccccc') <> 'TEST-ONLY' then raise exception 'service token storage failed'; end if;
end $$;
reset role;
delete from auth.users where id='cccccccc-cccc-cccc-cccc-cccccccccccc';
do $$ begin
  if exists(select 1 from veil_private.apple_credentials where user_id='cccccccc-cccc-cccc-cccc-cccccccccccc') then raise exception 'credential reference retained'; end if;
  if exists(select 1 from vault.decrypted_secrets where decrypted_secret='TEST-ONLY') then raise exception 'vault cleanup not transactional'; end if;
end $$;
rollback;
select 'Veil token privileges and cleanup passed' as result;
