-- Phase 3 migration: Teaching library, taxonomy, analytics, quality, audit

-- 1) Extend elog_entries with quality fields
alter table if exists public.elog_entries
  add column if not exists quality_score int default 0,
  add column if not exists quality_issues jsonb default '[]'::jsonb;

-- 2) Teaching library tables
create table if not exists public.teaching_item_proposals (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid references public.elog_entries(id) on delete cascade,
  proposed_by uuid references auth.users(id) on delete cascade,
  note text,
  status text not null check (status in ('pending','approved','rejected')) default 'pending',
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.teaching_items (
  id uuid primary key default gen_random_uuid(),
  source_entry_id uuid references public.elog_entries(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  centre text not null check (centre in ('Chennai','Coimbatore','Madurai','Pondicherry','Tirupati','Salem','Tirunelveli')),
  module_type text not null check (module_type in ('cases','images','learning','records')),
  title text not null,
  teaching_summary text,
  redacted_payload jsonb not null,
  media_paths jsonb default '[]'::jsonb,
  keywords text[] not null,
  share_scope text not null check (share_scope in ('private','centre','institution')) default 'centre',
  is_featured boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function public.set_teaching_items_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_teaching_items_updated on public.teaching_items;
create trigger trg_teaching_items_updated
before update on public.teaching_items
for each row execute function public.set_teaching_items_updated_at();

create table if not exists public.teaching_item_bookmarks (
  id uuid primary key default gen_random_uuid(),
  teaching_item_id uuid references public.teaching_items(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (teaching_item_id, user_id)
);

-- 3) Taxonomy tables
create table if not exists public.keyword_terms (
  id uuid primary key default gen_random_uuid(),
  term text not null unique,
  normalized text not null unique,
  status text not null check (status in ('active','deprecated')) default 'active',
  replacement_term_id uuid references public.keyword_terms(id),
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create table if not exists public.keyword_suggestions (
  id uuid primary key default gen_random_uuid(),
  suggested_term text not null,
  suggested_by uuid references auth.users(id),
  status text not null check (status in ('pending','accepted','rejected')) default 'pending',
  reviewed_by uuid references auth.users(id),
  created_at timestamptz default now(),
  reviewed_at timestamptz
);

-- 4) Analytics snapshots
create table if not exists public.analytics_snapshots (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('user','consultant','centre','institution')),
  scope_id text not null,
  period_start date not null,
  period_end date not null,
  metrics jsonb not null,
  created_at timestamptz default now(),
  unique (scope, scope_id, period_start, period_end)
);

-- 5) Audit events
create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id),
  action text not null,
  target_type text not null,
  target_id text not null,
  metadata jsonb,
  created_at timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_teaching_items_scope on public.teaching_items(share_scope, centre);
create index if not exists idx_teaching_items_keywords on public.teaching_items using gin(keywords);
create index if not exists idx_elog_entries_keywords on public.elog_entries using gin(keywords);
create index if not exists idx_audit_events_actor on public.audit_events(actor_id);

-- RLS enable
alter table public.teaching_item_proposals enable row level security;
alter table public.teaching_items enable row level security;
alter table public.teaching_item_bookmarks enable row level security;
alter table public.keyword_terms enable row level security;
alter table public.keyword_suggestions enable row level security;
alter table public.analytics_snapshots enable row level security;
alter table public.audit_events enable row level security;

-- RLS policies
-- Proposals
drop policy if exists "proposal insert" on public.teaching_item_proposals;
create policy "proposal insert"
on public.teaching_item_proposals
for insert to authenticated
with check (proposed_by = auth.uid());

drop policy if exists "proposal select" on public.teaching_item_proposals;
create policy "proposal select"
on public.teaching_item_proposals
for select using (
  proposed_by = auth.uid()
  or exists (
    select 1 from public.supervisor_assignments sa
    join public.elog_entries e on e.created_by = sa.trainee_id
    where e.id = teaching_item_proposals.entry_id and sa.consultant_id = auth.uid()
  )
);

drop policy if exists "proposal update consultants" on public.teaching_item_proposals;
create policy "proposal update consultants"
on public.teaching_item_proposals
for update to authenticated
using (
  exists (
    select 1 from public.supervisor_assignments sa
    join public.elog_entries e on e.created_by = sa.trainee_id
    where e.id = teaching_item_proposals.entry_id and sa.consultant_id = auth.uid()
  )
);

-- Teaching items
drop policy if exists "teaching select" on public.teaching_items;
create policy "teaching select"
on public.teaching_items
for select using (
  share_scope = 'institution'
  or (share_scope = 'centre' and exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.centre = teaching_items.centre
  ))
  or (share_scope = 'private' and (
    teaching_items.created_by = auth.uid()
    or exists (
      select 1 from public.supervisor_assignments sa
      where sa.consultant_id = auth.uid() and sa.trainee_id = teaching_items.created_by
    )
  ))
);

drop policy if exists "teaching insert consultants" on public.teaching_items;
create policy "teaching insert consultants"
on public.teaching_items
for insert to authenticated
with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
);

drop policy if exists "teaching update consultants" on public.teaching_items;
create policy "teaching update consultants"
on public.teaching_items
for update to authenticated
using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
)
with check (true);

drop policy if exists "teaching delete consultants" on public.teaching_items;
create policy "teaching delete consultants"
on public.teaching_items
for delete to authenticated
using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
);

-- Bookmarks owner-only
drop policy if exists "bookmark select" on public.teaching_item_bookmarks;
create policy "bookmark select"
on public.teaching_item_bookmarks
for select using (user_id = auth.uid());

drop policy if exists "bookmark insert" on public.teaching_item_bookmarks;
create policy "bookmark insert"
on public.teaching_item_bookmarks
for insert with check (user_id = auth.uid());

drop policy if exists "bookmark delete" on public.teaching_item_bookmarks;
create policy "bookmark delete"
on public.teaching_item_bookmarks
for delete using (user_id = auth.uid());

-- Keyword terms & suggestions
drop policy if exists "terms select" on public.keyword_terms;
create policy "terms select" on public.keyword_terms for select using (true);

drop policy if exists "terms insert" on public.keyword_terms;
create policy "terms insert" on public.keyword_terms for insert with check (created_by = auth.uid());

drop policy if exists "suggestions select" on public.keyword_suggestions;
create policy "suggestions select" on public.keyword_suggestions for select using (true);

drop policy if exists "suggestions insert" on public.keyword_suggestions;
create policy "suggestions insert" on public.keyword_suggestions for insert with check (suggested_by = auth.uid());

drop policy if exists "suggestions update consultants" on public.keyword_suggestions;
create policy "suggestions update consultants"
on public.keyword_suggestions
for update to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant'))
with check (true);

-- Analytics snapshots
drop policy if exists "analytics select" on public.analytics_snapshots;
create policy "analytics select"
on public.analytics_snapshots
for select using (
  (scope = 'user' and scope_id = auth.uid()::text)
  or (scope = 'consultant' and scope_id = auth.uid()::text)
  or (scope = 'centre' and exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.centre = scope_id
  ))
  or (scope = 'institution' and exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant'
  ))
);

drop policy if exists "analytics insert consultants" on public.analytics_snapshots;
create policy "analytics insert consultants"
on public.analytics_snapshots
for insert to authenticated
with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
);

-- Audit events: owner and assigned consultant
drop policy if exists "audit select" on public.audit_events;
create policy "audit select"
on public.audit_events
for select using (
  actor_id = auth.uid()
  or exists (
    select 1 from public.supervisor_assignments sa
    where sa.consultant_id = auth.uid() and sa.trainee_id = audit_events.actor_id
  )
);

drop policy if exists "audit insert" on public.audit_events;
create policy "audit insert"
on public.audit_events
for insert to authenticated
with check (actor_id = auth.uid());
