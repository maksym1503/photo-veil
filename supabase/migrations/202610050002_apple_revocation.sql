begin;
create extension if not exists supabase_vault with schema vault;
create schema if not exists veil_private;
revoke all on schema veil_private from public, anon, authenticated;
create table veil_private.apple_credentials (
  user_id uuid primary key references auth.users(id) on delete cascade,
  secret_id uuid not null
);
revoke all on veil_private.apple_credentials from public, anon, authenticated;
create function public.veil_store_apple_refresh(owner_id uuid, refresh_token text) returns void
language plpgsql security definer set search_path = '' as $$
declare existing uuid;
begin
  select secret_id into existing from veil_private.apple_credentials where user_id = owner_id for update;
  if existing is null then
    existing := vault.create_secret(refresh_token);
    insert into veil_private.apple_credentials(user_id,secret_id) values(owner_id,existing);
  else perform vault.update_secret(existing, refresh_token); end if;
end $$;
create function public.veil_apple_refresh(owner_id uuid) returns text
language sql security definer set search_path = '' as $$
  select s.decrypted_secret from vault.decrypted_secrets s join veil_private.apple_credentials a on a.secret_id = s.id where a.user_id = owner_id;
$$;
create function public.veil_clear_apple_refresh(owner_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare existing uuid;
begin
  select secret_id into existing from veil_private.apple_credentials where user_id = owner_id;
  delete from veil_private.apple_credentials where user_id = owner_id;
  delete from vault.secrets where id = existing;
end $$;
revoke all on function public.veil_store_apple_refresh(uuid,text), public.veil_apple_refresh(uuid), public.veil_clear_apple_refresh(uuid) from public, anon, authenticated;
grant execute on function public.veil_store_apple_refresh(uuid,text), public.veil_apple_refresh(uuid), public.veil_clear_apple_refresh(uuid) to service_role;
-- Auth deletion and Vault cleanup are one database transaction. A failed admin delete retains the credential for retry.
create function public.veil_remove_apple_secret() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform public.veil_clear_apple_refresh(old.id);
  return old;
end $$;
revoke all on function public.veil_remove_apple_secret() from public, anon, authenticated;
create trigger veil_remove_apple_secret before delete on auth.users for each row execute function public.veil_remove_apple_secret();
commit;
