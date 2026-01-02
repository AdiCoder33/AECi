-- Logbook submission items (per-entry selection)

create table if not exists public.logbook_submission_items (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid references public.logbook_submissions(id) on delete cascade,
  module_key text not null,
  entity_type text not null,
  entity_id uuid not null,
  created_at timestamptz default now(),
  unique (submission_id, entity_type, entity_id)
);

create index if not exists idx_logbook_submission_items_submission
  on public.logbook_submission_items(submission_id);
create index if not exists idx_logbook_submission_items_entity
  on public.logbook_submission_items(entity_type, entity_id);

alter table public.logbook_submission_items enable row level security;

drop policy if exists "logbook items select" on public.logbook_submission_items;
create policy "logbook items select"
on public.logbook_submission_items
for select
to authenticated
using (
  public.is_logbook_submission_owner(submission_id, auth.uid())
  or exists (
    select 1 from public.logbook_submission_recipients r
    where r.submission_id = logbook_submission_items.submission_id
      and r.recipient_id = auth.uid()
  )
);

drop policy if exists "logbook items insert" on public.logbook_submission_items;
create policy "logbook items insert"
on public.logbook_submission_items
for insert
to authenticated
with check (
  public.is_logbook_submission_owner(submission_id, auth.uid())
);

drop policy if exists "logbook items delete" on public.logbook_submission_items;
create policy "logbook items delete"
on public.logbook_submission_items
for delete
to authenticated
using (
  public.is_logbook_submission_owner(submission_id, auth.uid())
);
