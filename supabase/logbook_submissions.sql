-- Logbook submissions (share selected sections with doctors)

create table if not exists public.logbook_submissions (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete cascade,
  module_keys text[] not null,
  created_at timestamptz default now()
);

create table if not exists public.logbook_submission_recipients (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid references public.logbook_submissions(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (submission_id, recipient_id)
);

create index if not exists idx_logbook_submissions_created_by
  on public.logbook_submissions(created_by);
create index if not exists idx_logbook_submission_recipients_submission
  on public.logbook_submission_recipients(submission_id);
create index if not exists idx_logbook_submission_recipients_recipient
  on public.logbook_submission_recipients(recipient_id);

alter table public.logbook_submissions enable row level security;
alter table public.logbook_submission_recipients enable row level security;

create or replace function public.is_logbook_submission_owner(
  p_submission_id uuid,
  p_user_id uuid
) returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.logbook_submissions s
    where s.id = p_submission_id and s.created_by = p_user_id
  );
$$;

revoke all on function public.is_logbook_submission_owner(uuid, uuid) from public;
grant execute on function public.is_logbook_submission_owner(uuid, uuid) to authenticated;

drop policy if exists "logbook submissions select" on public.logbook_submissions;
create policy "logbook submissions select"
on public.logbook_submissions
for select
to authenticated
using (
  created_by = auth.uid()
  or exists (
    select 1 from public.logbook_submission_recipients r
    where r.submission_id = logbook_submissions.id
      and r.recipient_id = auth.uid()
  )
);

drop policy if exists "logbook submissions insert" on public.logbook_submissions;
create policy "logbook submissions insert"
on public.logbook_submissions
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "logbook submissions delete" on public.logbook_submissions;
create policy "logbook submissions delete"
on public.logbook_submissions
for delete
to authenticated
using (created_by = auth.uid());

drop policy if exists "logbook recipients select" on public.logbook_submission_recipients;
create policy "logbook recipients select"
on public.logbook_submission_recipients
for select
to authenticated
using (
  recipient_id = auth.uid()
  or public.is_logbook_submission_owner(submission_id, auth.uid())
);

drop policy if exists "logbook recipients insert" on public.logbook_submission_recipients;
create policy "logbook recipients insert"
on public.logbook_submission_recipients
for insert
to authenticated
with check (
  public.is_logbook_submission_owner(submission_id, auth.uid())
);

drop policy if exists "logbook recipients delete" on public.logbook_submission_recipients;
create policy "logbook recipients delete"
on public.logbook_submission_recipients
for delete
to authenticated
using (
  public.is_logbook_submission_owner(submission_id, auth.uid())
);
