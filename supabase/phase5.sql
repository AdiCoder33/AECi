-- Phase 5: Clinical Details Wizard fields + status

alter table if exists public.clinical_cases
  add column if not exists status text not null default 'draft',
  add column if not exists anterior_segment jsonb default '{}'::jsonb,
  add column if not exists fundus jsonb default '{}'::jsonb,
  add column if not exists bcva_re text,
  add column if not exists bcva_le text,
  add column if not exists iop_re numeric,
  add column if not exists iop_le numeric;

-- Expand complaint duration unit to include months
alter table if exists public.clinical_cases
  drop constraint if exists clinical_cases_complaint_duration_unit_check;

alter table if exists public.clinical_cases
  add constraint clinical_cases_complaint_duration_unit_check
  check (complaint_duration_unit in ('days','weeks','months','years'));

-- Enforce status values for wizard
alter table if exists public.clinical_cases
  drop constraint if exists clinical_cases_status_check;

alter table if exists public.clinical_cases
  add constraint clinical_cases_status_check
  check (status in ('draft','submitted'));

-- Indexes
create index if not exists idx_clinical_cases_keywords on public.clinical_cases using gin(keywords);
create index if not exists idx_clinical_cases_created_by on public.clinical_cases(created_by, updated_at desc);
