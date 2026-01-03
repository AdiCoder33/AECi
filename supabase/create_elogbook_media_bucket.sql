-- Create storage bucket for logbook/clinical case media
insert into storage.buckets (id, name, public)
values ('elogbook-media', 'elogbook-media', false)
on conflict (id) do nothing;

-- Allow authenticated users to read media (used with signed URLs)
drop policy if exists "elogbook-media select authenticated" on storage.objects;
create policy "elogbook-media select authenticated"
on storage.objects
for select
to authenticated
using (bucket_id = 'elogbook-media');

-- Allow authenticated users to upload into their own folder
drop policy if exists "elogbook-media insert own" on storage.objects;
create policy "elogbook-media insert own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'elogbook-media' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own objects
drop policy if exists "elogbook-media update own" on storage.objects;
create policy "elogbook-media update own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'elogbook-media' and
  (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'elogbook-media' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own objects
drop policy if exists "elogbook-media delete own" on storage.objects;
create policy "elogbook-media delete own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'elogbook-media' and
  (storage.foldername(name))[1] = auth.uid()::text
);
