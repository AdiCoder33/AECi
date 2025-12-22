-- Phase 4: Clinical cases, assessments, roster, notifications, profile upgrades

-- Profile upgrades
alter table if exists public.profiles
  add column if not exists gender text check (gender in ('male','female')),
  add column if not exists degrees text[] not null default '{}'::text[],
  add column if not exists aravind_centre text check (aravind_centre in ('Madurai','Chennai','Coimbatore','Tirunelveli','Salem','Tirupati','Pondicherry')),
  add column if not exists id_number text,
  add column if not exists date_of_joining date,
  add column if not exists hod_name text;

-- Clinical cases
create table if not exists public.clinical_cases (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete cascade,
  date_of_examination date not null,
  patient_name text not null,
  uid_number text not null,
  mr_number text not null,
  patient_gender text not null check (patient_gender in ('male','female')),
  patient_age int not null,
  chief_complaint text not null,
  complaint_duration_value int not null,
  complaint_duration_unit text not null check (complaint_duration_unit in ('days','weeks','years')),
  systemic_history jsonb not null default '[]'::jsonb,
  past_ocular_history text,
  ucva_re text,
  ucva_le text,
  bcva_re text,
  bcva_le text,
  iop_re numeric,
  iop_le numeric,
  anterior_segment_findings text,
  fundus_findings text,
  diagnosis text not null,
  diagnosis_other text,
  management text,
  learning_point text,
  keywords text[] not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint clinical_cases_keywords_len check (coalesce(array_length(keywords, 1),0) <= 5)
);

create or replace function public.set_clinical_cases_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_clinical_cases_updated on public.clinical_cases;
create trigger trg_clinical_cases_updated
before update on public.clinical_cases
for each row execute function public.set_clinical_cases_updated_at();

-- Followups
create table if not exists public.case_followups (
  id uuid primary key default gen_random_uuid(),
  case_id uuid references public.clinical_cases(id) on delete cascade,
  followup_index int not null,
  date_of_examination date not null,
  interval_days int not null,
  ucva_re text,
  ucva_le text,
  bcva_re text,
  bcva_le text,
  iop_re numeric,
  iop_le numeric,
  anterior_segment_findings text,
  fundus_findings text,
  management text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (case_id, followup_index)
);

create or replace function public.set_case_followups_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_case_followups_updated on public.case_followups;
create trigger trg_case_followups_updated
before update on public.case_followups
for each row execute function public.set_case_followups_updated_at();

-- Media
create table if not exists public.case_media (
  id uuid primary key default gen_random_uuid(),
  case_id uuid references public.clinical_cases(id) on delete cascade,
  followup_id uuid references public.case_followups(id) on delete cascade,
  category text not null check (category in ('ANTERIOR_SEGMENT_IMAGE','FUNDUS','OCT','FAF','OCTA','EDI','B_SCAN','FFA','ICGA','ERG','EOG','UBM','HFA','ANCILLARY')),
  media_type text not null check (media_type in ('image','video')),
  storage_path text not null,
  note text,
  created_at timestamptz default now()
);

-- Assessment roster
create table if not exists public.assessment_roster (
  id uuid primary key default gen_random_uuid(),
  centre text not null check (centre in ('Madurai','Chennai','Coimbatore','Tirunelveli','Salem','Tirupati','Pondicherry')),
  month_key text not null,
  consultant_id uuid references auth.users(id) on delete cascade,
  is_active boolean default true,
  created_at timestamptz default now(),
  unique (centre, month_key, consultant_id)
);

-- Case assessments
create table if not exists public.case_assessments (
  id uuid primary key default gen_random_uuid(),
  case_id uuid references public.clinical_cases(id) on delete cascade,
  submitted_by uuid references auth.users(id) on delete cascade,
  assigned_consultant_id uuid references auth.users(id) on delete cascade,
  status text not null check (status in ('draft','submitted','in_review','completed')) default 'submitted',
  consultant_comments text,
  assessed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (case_id)
);

create or replace function public.set_case_assessments_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_case_assessments_updated on public.case_assessments;
create trigger trg_case_assessments_updated
before update on public.case_assessments
for each row execute function public.set_case_assessments_updated_at();

-- Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  entity_type text not null,
  entity_id uuid not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_clinical_cases_created_by on public.clinical_cases(created_by, updated_at desc);
create index if not exists idx_clinical_cases_keywords on public.clinical_cases using gin(keywords);
create index if not exists idx_case_assessments_assigned on public.case_assessments(assigned_consultant_id, status);
create index if not exists idx_notifications_user on public.notifications(user_id, is_read, created_at desc);

-- RLS enable
alter table public.clinical_cases enable row level security;
alter table public.case_followups enable row level security;
alter table public.case_media enable row level security;
alter table public.assessment_roster enable row level security;
alter table public.case_assessments enable row level security;
alter table public.notifications enable row level security;

-- RLS policies
-- clinical_cases
drop policy if exists "clinical select" on public.clinical_cases;
create policy "clinical select" on public.clinical_cases for select using (true);

drop policy if exists "clinical insert" on public.clinical_cases;
create policy "clinical insert" on public.clinical_cases for insert with check (created_by = auth.uid());

drop policy if exists "clinical update" on public.clinical_cases;
create policy "clinical update" on public.clinical_cases
for update using (
  created_by = auth.uid() and not exists (
    select 1 from public.case_assessments ca
    where ca.case_id = clinical_cases.id and ca.status in ('submitted','in_review','completed')
  )
);

drop policy if exists "clinical delete" on public.clinical_cases;
create policy "clinical delete" on public.clinical_cases
for delete using (
  created_by = auth.uid() and not exists (
    select 1 from public.case_assessments ca
    where ca.case_id = clinical_cases.id and ca.status in ('submitted','in_review','completed')
  )
);

-- followups
drop policy if exists "followup select" on public.case_followups;
create policy "followup select" on public.case_followups
for select using (
  exists (select 1 from public.clinical_cases c where c.id = case_followups.case_id)
);

drop policy if exists "followup insert" on public.case_followups;
create policy "followup insert" on public.case_followups
for insert with check (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_followups.case_id and c.created_by = auth.uid()
  )
);

drop policy if exists "followup update" on public.case_followups;
create policy "followup update" on public.case_followups
for update using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_followups.case_id and c.created_by = auth.uid()
  )
);

drop policy if exists "followup delete" on public.case_followups;
create policy "followup delete" on public.case_followups
for delete using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_followups.case_id and c.created_by = auth.uid()
  )
);

-- media
drop policy if exists "case_media select" on public.case_media;
create policy "case_media select" on public.case_media
for select using (
  exists (select 1 from public.clinical_cases c where c.id = case_media.case_id)
);

drop policy if exists "case_media insert" on public.case_media;
create policy "case_media insert" on public.case_media
for insert with check (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_media.case_id and c.created_by = auth.uid()
  )
);

drop policy if exists "case_media update" on public.case_media;
create policy "case_media update" on public.case_media
for update using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_media.case_id and c.created_by = auth.uid()
  )
);

drop policy if exists "case_media delete" on public.case_media;
create policy "case_media delete" on public.case_media
for delete using (
  exists (
    select 1 from public.clinical_cases c
    where c.id = case_media.case_id and c.created_by = auth.uid()
  )
);

-- roster
drop policy if exists "roster select" on public.assessment_roster;
create policy "roster select" on public.assessment_roster for select using (true);

drop policy if exists "roster insert" on public.assessment_roster;
create policy "roster insert" on public.assessment_roster
for insert to authenticated
with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
);

drop policy if exists "roster update" on public.assessment_roster;
create policy "roster update" on public.assessment_roster
for update to authenticated
using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
)
with check (true);

drop policy if exists "roster delete" on public.assessment_roster;
create policy "roster delete" on public.assessment_roster
for delete to authenticated
using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.designation = 'Consultant')
);

-- assessments
drop policy if exists "assessment select" on public.case_assessments;
create policy "assessment select" on public.case_assessments
for select using (
  submitted_by = auth.uid() or assigned_consultant_id = auth.uid()
);

drop policy if exists "assessment insert" on public.case_assessments;
create policy "assessment insert" on public.case_assessments
for insert with check (submitted_by = auth.uid());

drop policy if exists "assessment update" on public.case_assessments;
create policy "assessment update" on public.case_assessments
for update using (assigned_consultant_id = auth.uid())
with check (true);

-- notifications
drop policy if exists "notifications select" on public.notifications;
create policy "notifications select" on public.notifications
for select using (user_id = auth.uid());

drop policy if exists "notifications insert" on public.notifications;
create policy "notifications insert" on public.notifications
for insert with check (user_id = auth.uid());

drop policy if exists "notifications update" on public.notifications;
create policy "notifications update" on public.notifications
for update using (user_id = auth.uid());

-- helper: security definer to send notifications to another user
create or replace function public.notify_user(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_entity_type text,
  p_entity_id uuid
) returns void
language plpgsql
security definer
as $$
begin
  insert into public.notifications(user_id, type, title, body, entity_type, entity_id)
  values (p_user_id, p_type, p_title, p_body, p_entity_type, p_entity_id);
end;
$$;

revoke all on function public.notify_user(uuid, text, text, text, text, uuid) from public;
grant execute on function public.notify_user(uuid, text, text, text, text, uuid) to authenticated;
