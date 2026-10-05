-- Run only against a disposable local Supabase database. All fixtures roll back.
begin;
insert into auth.users(id) values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
insert into public.gallery_items(id,user_id,width,height,effect,processed_path,thumbnail_path) values
('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',64,64,'Blur','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/11111111-1111-1111-1111-111111111111/processed.jpg','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/11111111-1111-1111-1111-111111111111/thumbnail.jpg'),
('22222222-2222-2222-2222-222222222222','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',64,64,'Redact','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/22222222-2222-2222-2222-222222222222/processed.jpg','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/22222222-2222-2222-2222-222222222222/thumbnail.jpg');
insert into storage.objects(bucket_id,name) values
('veil-gallery','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/11111111-1111-1111-1111-111111111111/processed.jpg'),
('veil-gallery','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/22222222-2222-2222-2222-222222222222/processed.jpg');
set local role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',true);
do $$ begin
  if (select count(*) from public.gallery_items) <> 1 then raise exception 'cross-user metadata read'; end if;
  if (select count(*) from storage.objects where bucket_id='veil-gallery') <> 1 then raise exception 'cross-user storage read'; end if;
  if (select count(*) from public.profiles) <> 1 then raise exception 'cross-user profile read'; end if;
  begin
    insert into storage.objects(bucket_id,name) values('veil-gallery','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/33333333-3333-3333-3333-333333333333/processed.jpg');
    raise exception 'cross-user storage insert allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set deletion_requested=false;
    raise exception 'client can reopen deletion gate';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.gallery_items(id,user_id,width,height,effect,processed_path,thumbnail_path) values
    ('33333333-3333-3333-3333-333333333333','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',64,64,'Blur','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/33333333-3333-3333-3333-333333333333/processed.jpg','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/33333333-3333-3333-3333-333333333333/thumbnail.jpg');
    raise exception 'cross-user metadata insert allowed';
  exception when insufficient_privilege then null; end;
  update public.gallery_items set effect='Pixelate' where user_id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if found then raise exception 'cross-user metadata update'; end if;
  delete from public.gallery_items where user_id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  if found then raise exception 'cross-user metadata delete'; end if;
  delete from storage.objects where name like 'bbbbbbbb%';
  if found then raise exception 'cross-user storage delete'; end if;
  insert into storage.objects(bucket_id,name) values('veil-gallery','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/11111111-1111-1111-1111-111111111111/thumbnail.jpg');
end $$;
reset role;
update public.profiles set deletion_requested=true where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set local role authenticated;
do $$ begin
  begin
    insert into storage.objects(bucket_id,name) values('veil-gallery','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/44444444-4444-4444-4444-444444444444/processed.jpg');
    raise exception 'upload allowed after deletion requested';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'Veil ownership policies passed' as result;
