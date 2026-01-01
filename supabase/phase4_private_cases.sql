-- Phase 4 patch: make clinical cases private to owner

drop policy if exists "clinical select" on public.clinical_cases;
create policy "clinical select own"
on public.clinical_cases
for select
to authenticated
using (created_by = auth.uid());

drop policy if exists "followup select" on public.case_followups;
create policy "followup select own"
on public.case_followups
for select
to authenticated
using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_followups.case_id and c.created_by = auth.uid()
  )
);

drop policy if exists "case_media select" on public.case_media;
create policy "case_media select own"
on public.case_media
for select
to authenticated
using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_media.case_id and c.created_by = auth.uid()
  )
);
