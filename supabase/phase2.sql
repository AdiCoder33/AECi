-- Phase 2 migration: supervision workflow + portfolio

-- 1) Extend elog_entries
alter table public.elog_entries
  add column if not exists submitted_at timestamptz,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references auth.users(id),
  add column if not exists review_comment text,
  add column if not exists required_changes jsonb default '[]'::jsonb;

-- Status values handled at app level (draft/submitted/needs_revision/approved/rejected)

-- 2) Review history table
create table if not exists public.elog_entry_reviews (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid references public.elog_entries(id) on delete cascade,
  reviewer_id uuid references auth.users(id) on delete cascade,
  decision text not null check (decision in ('approved','needs_revision','rejected')),
  comment text,
  required_changes jsonb,
  created_at timestamptz default now()
);

-- 3) Supervisor assignments
create table if not exists public.supervisor_assignments (
  id uuid primary key default gen_random_uuid(),
  consultant_id uuid references auth.users(id) on delete cascade,
  trainee_id uuid references auth.users(id) on delete cascade,
  centre text not null check (centre in ('Chennai','Coimbatore','Madurai','Pondicherry','Tirupati','Salem','Tirunelveli')),
  created_at timestamptz default now(),
  unique (consultant_id, trainee_id)
);

-- 4) Portfolio tables
create table if not exists public.research_projects (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete cascade,
  title text not null,
  summary text,
  role text,
  status text not null,
  start_date date,
  end_date date,
  keywords text[] default '{}'::text[],
  attachments jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.presentations_publications (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete cascade,
  type text not null check (type in ('presentation','publication')),
  title text not null,
  venue_or_journal text,
  date date,
  link text,
  keywords text[] default '{}'::text[],
  attachments jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- updated_at triggers
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_research_projects_updated on public.research_projects;
create trigger trg_research_projects_updated
before update on public.research_projects
for each row execute function public.set_updated_at();

drop trigger if exists trg_presentations_updated on public.presentations_publications;
create trigger trg_presentations_updated
before update on public.presentations_publications
for each row execute function public.set_updated_at();

-- Indexes
create index if not exists idx_elog_entries_created_by on public.elog_entries(created_by);
create index if not exists idx_elog_entries_status on public.elog_entries(status);
create index if not exists idx_supervisor_assignments_consultant on public.supervisor_assignments(consultant_id);
create index if not exists idx_supervisor_assignments_trainee on public.supervisor_assignments(trainee_id);
create index if not exists idx_research_projects_created_by on public.research_projects(created_by);
create index if not exists idx_presentations_created_by on public.presentations_publications(created_by);

-- RLS
alter table public.elog_entries enable row level security;
alter table public.elog_entry_reviews enable row level security;
alter table public.supervisor_assignments enable row level security;
alter table public.research_projects enable row level security;
alter table public.presentations_publications enable row level security;

-- helper to check assignment
create or replace view public.v_assigned_pairs as
select consultant_id, trainee_id from public.supervisor_assignments;

-- elog_entries policies
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
);

drop policy if exists "elog insert own" on public.elog_entries;
create policy "elog insert own"
on public.elog_entries
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "elog update owner or reviewer" on public.elog_entries;
create policy "elog update owner or reviewer"
on public.elog_entries
for update
to authenticated
using (
  -- owner editing drafts or needs_revision
  (created_by = auth.uid() and status in ('draft','needs_revision'))
  or
  -- consultant reviewer updating review fields
  (exists (
    select 1 from public.supervisor_assignments sa
    where sa.consultant_id = auth.uid() and sa.trainee_id = elog_entries.created_by
  ))
)
with check (true);

drop policy if exists "elog delete draft owner" on public.elog_entries;
create policy "elog delete draft owner"
on public.elog_entries
for delete
to authenticated
using (created_by = auth.uid() and status = 'draft');

-- elog_entry_reviews policies
drop policy if exists "review insert by assigned consultant" on public.elog_entry_reviews;
create policy "review insert by assigned consultant"
on public.elog_entry_reviews
for insert
to authenticated
with check (
  reviewer_id = auth.uid() and exists (
    select 1 from public.elog_entries e
    join public.supervisor_assignments sa on sa.trainee_id = e.created_by
    where e.id = entry_id and sa.consultant_id = auth.uid()
  )
);

drop policy if exists "review select owner or consultant" on public.elog_entry_reviews;
create policy "review select owner or consultant"
on public.elog_entry_reviews
for select
to authenticated
using (
  exists (
    select 1 from public.elog_entries e
    where e.id = entry_id and e.created_by = auth.uid()
  )
  or
  exists (
    select 1 from public.elog_entries e
    join public.supervisor_assignments sa on sa.trainee_id = e.created_by
    where e.id = entry_id and sa.consultant_id = auth.uid()
  )
);

-- supervisor_assignments policies
drop policy if exists "assignments select" on public.supervisor_assignments;
create policy "assignments select"
on public.supervisor_assignments
for select
to authenticated
using (consultant_id = auth.uid() or trainee_id = auth.uid());

drop policy if exists "assignments insert" on public.supervisor_assignments;
create policy "assignments insert"
on public.supervisor_assignments
for insert
to authenticated
with check (consultant_id = auth.uid());

drop policy if exists "assignments delete" on public.supervisor_assignments;
create policy "assignments delete"
on public.supervisor_assignments
for delete
to authenticated
using (consultant_id = auth.uid());

-- portfolio policies (owner-only; optional consultant select mirroring elog)
drop policy if exists "research owner select" on public.research_projects;
create policy "research owner select"
on public.research_projects
for select using (
  created_by = auth.uid()
  or exists (
    select 1 from public.supervisor_assignments sa
    where sa.consultant_id = auth.uid() and sa.trainee_id = research_projects.created_by
  )
);

drop policy if exists "research owner insert" on public.research_projects;
create policy "research owner insert"
on public.research_projects
for insert with check (created_by = auth.uid());

drop policy if exists "research owner update" on public.research_projects;
create policy "research owner update"
on public.research_projects
for update using (created_by = auth.uid());

drop policy if exists "research owner delete" on public.research_projects;
create policy "research owner delete"
on public.research_projects
for delete using (created_by = auth.uid());

drop policy if exists "pubs owner select" on public.presentations_publications;
create policy "pubs owner select"
on public.presentations_publications
for select using (
  created_by = auth.uid()
  or exists (
    select 1 from public.supervisor_assignments sa
    where sa.consultant_id = auth.uid() and sa.trainee_id = presentations_publications.created_by
  )
);

drop policy if exists "pubs owner insert" on public.presentations_publications;
create policy "pubs owner insert"
on public.presentations_publications
for insert with check (created_by = auth.uid());

drop policy if exists "pubs owner update" on public.presentations_publications;
create policy "pubs owner update"
on public.presentations_publications
for update using (created_by = auth.uid());

drop policy if exists "pubs owner delete" on public.presentations_publications;
create policy "pubs owner delete"
on public.presentations_publications
for delete using (created_by = auth.uid());
