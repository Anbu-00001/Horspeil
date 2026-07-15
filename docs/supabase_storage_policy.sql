-- Hörspiel — Supabase Storage RLS policies for the `podcasts` bucket
-- ---------------------------------------------------------------------------
-- Apply once, via the Supabase dashboard → SQL Editor → paste → Run.
--
-- WHY THIS EXISTS
-- The `podcasts` bucket is PUBLIC, which only makes finished objects readable
-- without auth. It does NOT grant write access. With zero policies, every
-- upload is denied by RLS (the "new row violates row-level security policy"
-- 403 we saw during setup) — which is the correct default: the publishable key
-- ships inside the app, so uploads must be gated on a real signed-in session,
-- not on possession of the key.
--
-- MODEL
-- The app uploads to `{ownerId}/{fileName}`, where ownerId == auth.uid().
-- These policies let an authenticated user (including anonymous sign-ins, which
-- also carry the `authenticated` role) write/modify/delete ONLY within their
-- own uid-prefixed folder. Reads stay public via the bucket setting, so no
-- SELECT policy is needed for playback.

-- INSERT: a user may upload only into their own folder.
create policy "podcasts: owner can upload"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'podcasts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- UPDATE: a user may overwrite only their own objects.
create policy "podcasts: owner can update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'podcasts'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'podcasts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- DELETE: a user may delete only their own objects.
create policy "podcasts: owner can delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'podcasts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- NOTE ON PUBLIC READ
-- Because the bucket is public, anonymous SELECT on its objects is already
-- allowed by Supabase's built-in public-bucket handling; do not add a broad
-- SELECT policy here. If the bucket is later made private, add:
--   create policy "podcasts: public read"
--   on storage.objects for select to anon, authenticated
--   using (bucket_id = 'podcasts');
-- and switch the app to signed URLs.
