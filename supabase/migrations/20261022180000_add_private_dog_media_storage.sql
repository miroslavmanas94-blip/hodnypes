-- Private media storage for Hodný pes.
-- Files are stored under <auth.uid()>/<random filename>; no public bucket URLs.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'dog-media',
  'dog-media',
  false,
  15728640,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'dog media read own files'
  ) then
    create policy "dog media read own files"
      on storage.objects for select to authenticated
      using (
        bucket_id = 'dog-media'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'dog media upload own files'
  ) then
    create policy "dog media upload own files"
      on storage.objects for insert to authenticated
      with check (
        bucket_id = 'dog-media'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'dog media update own files'
  ) then
    create policy "dog media update own files"
      on storage.objects for update to authenticated
      using (
        bucket_id = 'dog-media'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      )
      with check (
        bucket_id = 'dog-media'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'dog media delete own files'
  ) then
    create policy "dog media delete own files"
      on storage.objects for delete to authenticated
      using (
        bucket_id = 'dog-media'
        and (storage.foldername(name))[1] = (select auth.uid())::text
      );
  end if;
end $$;
