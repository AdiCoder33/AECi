alter table if exists public.presentations_publications
  add column if not exists abstract text;
