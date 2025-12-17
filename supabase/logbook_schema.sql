-- E-Logbook entries table
create table if not exists public.elog_entries (
  id uuid primary key default gen_random_uuid(),
  module_type text not null check (module_type in ('cases','images','learning','records')),
  created_by uuid not null references auth.users(id) on delete cascade,
  patient_unique_id text not null,
  mrn text not null,
  keywords text[] not null,
  status text not null default 'draft',
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- updated_at trigger
create or replace function public.set_elog_entries_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists elog_entries_set_updated_at on public.elog_entries;
create trigger elog_entries_set_updated_at
before update on public.elog_entries
for each row
execute function public.set_elog_entries_updated_at();

alter table public.elog_entries enable row level security;

-- RLS Policies
drop policy if exists "elog select all authenticated" on public.elog_entries;
create policy "elog select all authenticated"
on public.elog_entries
for select
to authenticated
using (true);

drop policy if exists "elog insert own" on public.elog_entries;
create policy "elog insert own"
on public.elog_entries
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "elog update own" on public.elog_entries;
create policy "elog update own"
on public.elog_entries
for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists "elog delete own" on public.elog_entries;
create policy "elog delete own"
on public.elog_entries
for delete
to authenticated
using (created_by = auth.uid());

-- Storage notes:
-- Create a private bucket named `elogbook-media`.
-- Use object paths: ${userId}/${entryId}/${filename}
-- App uses signed URLs to read.
