begin;
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deletion_requested boolean not null default false
);
create table public.gallery_items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  width integer not null check (width > 0 and width <= 50000),
  height integer not null check (height > 0 and height <= 50000),
  effect text not null check (effect in ('Blur','Pixelate','Redact')),
  processed_path text not null,
  thumbnail_path text not null,
  deleted_at timestamptz,
  version integer not null default 1 check (version = 1),
  check (processed_path = user_id::text || '/' || id::text || '/processed.jpg'),
  check (thumbnail_path = user_id::text || '/' || id::text || '/thumbnail.jpg')
);
create index gallery_owner_date on public.gallery_items(user_id, created_at desc);
alter table public.profiles enable row level security;
alter table public.gallery_items enable row level security;
revoke all on public.profiles, public.gallery_items from anon, authenticated;
grant select, delete on public.profiles to authenticated;
grant insert(id, display_name), update(display_name) on public.profiles to authenticated;
grant select, insert, update, delete on public.gallery_items to authenticated;
create policy profile_select on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profile_insert on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy profile_update on public.profiles for update to authenticated using (id = (select auth.uid()) and not deletion_requested) with check (id = (select auth.uid()));
create policy profile_delete on public.profiles for delete to authenticated using (id = (select auth.uid()) and not deletion_requested);
create policy gallery_select on public.gallery_items for select to authenticated using (user_id = (select auth.uid()));
create policy gallery_insert on public.gallery_items for insert to authenticated with check (
  user_id = (select auth.uid()) and exists(select 1 from public.profiles where id = (select auth.uid()) and not deletion_requested));
create policy gallery_update on public.gallery_items for update to authenticated using (user_id = (select auth.uid())) with check (
  user_id = (select auth.uid()) and exists(select 1 from public.profiles where id = (select auth.uid()) and not deletion_requested));
create policy gallery_delete on public.gallery_items for delete to authenticated using (user_id = (select auth.uid()));
create function public.veil_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id) values(new.id) on conflict do nothing;
  return new;
end $$;
revoke all on function public.veil_new_user() from public, anon, authenticated;
create trigger veil_new_user after insert on auth.users for each row execute function public.veil_new_user();
insert into public.profiles(id) select id from auth.users on conflict do nothing;
create function public.veil_gallery_update() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.id <> old.id or new.user_id <> old.user_id or new.created_at <> old.created_at then raise exception 'immutable gallery identity'; end if;
  if old.deleted_at is not null and new.deleted_at is null then raise exception 'deleted item cannot be restored'; end if;
  new.updated_at = now(); return new;
end $$;
create trigger veil_gallery_update before update on public.gallery_items for each row execute function public.veil_gallery_update();

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values('veil-gallery','veil-gallery',false,52428800,array['image/jpeg']);
create function public.veil_storage_owner(object_name text) returns boolean language sql stable security invoker set search_path = '' as $$
  select (storage.foldername(object_name))[1] = (select auth.uid())::text
    and object_name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/(processed|thumbnail)\.jpg$'
    and exists(select 1 from public.profiles where id = (select auth.uid()) and not deletion_requested)
    and not exists(select 1 from public.gallery_items where user_id = (select auth.uid()) and
        (processed_path = object_name or thumbnail_path = object_name) and deleted_at is not null);
$$;
revoke all on function public.veil_storage_owner(text) from public, anon;
grant execute on function public.veil_storage_owner(text) to authenticated;
create policy veil_storage_select on storage.objects for select to authenticated using (bucket_id = 'veil-gallery' and public.veil_storage_owner(name));
create policy veil_storage_insert on storage.objects for insert to authenticated with check (bucket_id = 'veil-gallery' and public.veil_storage_owner(name));
create policy veil_storage_update on storage.objects for update to authenticated using (bucket_id = 'veil-gallery' and public.veil_storage_owner(name)) with check (bucket_id = 'veil-gallery' and public.veil_storage_owner(name));
create policy veil_storage_delete on storage.objects for delete to authenticated using (bucket_id = 'veil-gallery' and (storage.foldername(name))[1] = (select auth.uid())::text);
commit;
