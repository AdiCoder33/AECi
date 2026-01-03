-- Allow logbook submission recipients to view shared items

drop policy if exists "clinical select logbook recipients" on public.clinical_cases;
create policy "clinical select logbook recipients" on public.clinical_cases
for select
to authenticated
using (
  exists (
    select 1
    from public.logbook_submission_items i
    join public.logbook_submission_recipients r
      on r.submission_id = i.submission_id
    where i.entity_type = 'clinical_case'
      and i.entity_id = clinical_cases.id
      and r.recipient_id = auth.uid()
  )
);

drop policy if exists "elog select logbook recipients" on public.elog_entries;
create policy "elog select logbook recipients" on public.elog_entries
for select
to authenticated
using (
  exists (
    select 1
    from public.logbook_submission_items i
    join public.logbook_submission_recipients r
      on r.submission_id = i.submission_id
    where i.entity_type = 'elog_entry'
      and i.entity_id = elog_entries.id
      and r.recipient_id = auth.uid()
  )
);

drop policy if exists "pubs select logbook recipients"
  on public.presentations_publications;
create policy "pubs select logbook recipients"
on public.presentations_publications
for select
to authenticated
using (
  exists (
    select 1
    from public.logbook_submission_items i
    join public.logbook_submission_recipients r
      on r.submission_id = i.submission_id
    where i.entity_type = 'publication'
      and i.entity_id = presentations_publications.id
      and r.recipient_id = auth.uid()
  )
);
