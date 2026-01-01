-- Case assessment recipients (reviewer + view-only access)

create table if not exists public.case_assessment_recipients (
  id uuid primary key default gen_random_uuid(),
  case_id uuid references public.clinical_cases(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  can_review boolean not null default false,
  created_at timestamptz default now(),
  unique (case_id, recipient_id)
);

create index if not exists idx_case_assessment_recipients_case
  on public.case_assessment_recipients(case_id);
create index if not exists idx_case_assessment_recipients_recipient
  on public.case_assessment_recipients(recipient_id);

alter table public.case_assessment_recipients enable row level security;

drop policy if exists "case recipients select" on public.case_assessment_recipients;
create policy "case recipients select"
on public.case_assessment_recipients
for select
to authenticated
using (
  recipient_id = auth.uid()
  or exists (
    select 1 from public.clinical_cases c
    where c.id = case_assessment_recipients.case_id
      and c.created_by = auth.uid()
  )
);

drop policy if exists "case recipients insert" on public.case_assessment_recipients;
create policy "case recipients insert"
on public.case_assessment_recipients
for insert
to authenticated
with check (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_assessment_recipients.case_id
      and c.created_by = auth.uid()
  )
);

drop policy if exists "case recipients delete" on public.case_assessment_recipients;
create policy "case recipients delete"
on public.case_assessment_recipients
for delete
to authenticated
using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_assessment_recipients.case_id
      and c.created_by = auth.uid()
  )
);

-- Update clinical_cases select to allow recipients view access
drop policy if exists "clinical select" on public.clinical_cases;
create policy "clinical select" on public.clinical_cases
for select
to authenticated
using (
  created_by = auth.uid()
  or exists (
    select 1 from public.case_assessment_recipients r
    where r.case_id = clinical_cases.id
      and r.recipient_id = auth.uid()
  )
);
