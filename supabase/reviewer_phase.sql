-- Reviewer role + assessment tables

-- Allow Reviewer designation
alter table public.profiles
  drop constraint if exists profiles_designation_check;

alter table public.profiles
  add constraint profiles_designation_check
  check (designation in ('Fellow','Resident','Consultant','Reviewer'));

-- Reviewer assignments (who reviews whom)
create table if not exists public.reviewer_assignments (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid references auth.users(id) on delete cascade,
  trainee_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (reviewer_id, trainee_id)
);

-- Reviewer assessments (clinical cases + surgical videos)
create table if not exists public.reviewer_assessments (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid references auth.users(id) on delete cascade,
  trainee_id uuid references auth.users(id) on delete cascade,
  entity_type text not null check (entity_type in ('clinical_case','elog_entry')),
  entity_id uuid not null,
  score int,
  remarks text,
  oscar_scores jsonb default '[]'::jsonb,
  oscar_total int,
  status text not null default 'completed',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (reviewer_id, entity_type, entity_id)
);

create or replace function public.set_reviewer_assessments_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_reviewer_assessments_updated on public.reviewer_assessments;
create trigger trg_reviewer_assessments_updated
before update on public.reviewer_assessments
for each row execute function public.set_reviewer_assessments_updated_at();

create index if not exists idx_reviewer_assignments_reviewer
  on public.reviewer_assignments(reviewer_id);
create index if not exists idx_reviewer_assignments_trainee
  on public.reviewer_assignments(trainee_id);
create index if not exists idx_reviewer_assessments_reviewer
  on public.reviewer_assessments(reviewer_id, status);
create index if not exists idx_reviewer_assessments_entity
  on public.reviewer_assessments(entity_type, entity_id);

alter table public.reviewer_assignments enable row level security;
alter table public.reviewer_assessments enable row level security;

-- Reviewer assignments policies
drop policy if exists "reviewer assignments select" on public.reviewer_assignments;
create policy "reviewer assignments select"
on public.reviewer_assignments
for select to authenticated
using (reviewer_id = auth.uid() or trainee_id = auth.uid());

drop policy if exists "reviewer assignments write" on public.reviewer_assignments;
create policy "reviewer assignments write"
on public.reviewer_assignments
for insert to authenticated
with check (
  reviewer_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.designation = 'Reviewer'
  )
);

drop policy if exists "reviewer assignments delete" on public.reviewer_assignments;
create policy "reviewer assignments delete"
on public.reviewer_assignments
for delete to authenticated
using (
  reviewer_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.designation = 'Reviewer'
  )
);

-- Reviewer assessments policies
drop policy if exists "reviewer assessments select" on public.reviewer_assessments;
create policy "reviewer assessments select"
on public.reviewer_assessments
for select to authenticated
using (reviewer_id = auth.uid() or trainee_id = auth.uid());

drop policy if exists "reviewer assessments insert" on public.reviewer_assessments;
create policy "reviewer assessments insert"
on public.reviewer_assessments
for insert to authenticated
with check (
  reviewer_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.designation = 'Reviewer'
  )
);

drop policy if exists "reviewer assessments update" on public.reviewer_assessments;
create policy "reviewer assessments update"
on public.reviewer_assessments
for update to authenticated
using (reviewer_id = auth.uid())
with check (reviewer_id = auth.uid());

-- Extend elog_entries select to include reviewer assignments
drop policy if exists "elog select" on public.elog_entries;
create policy "elog select"
on public.elog_entries
for select
to authenticated
using (
  created_by = auth.uid()
  or exists (
    select 1 from public.supervisor_assignments sa
    where sa.consultant_id = auth.uid() and sa.trainee_id = elog_entries.created_by
  )
  or exists (
    select 1 from public.reviewer_assignments ra
    where ra.reviewer_id = auth.uid() and ra.trainee_id = elog_entries.created_by
  )
);
