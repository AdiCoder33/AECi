-- Fix and update profiles table schema to match the app model
-- Run this in your Supabase SQL Editor

-- Add missing columns if they don't exist
alter table public.profiles 
add column if not exists gender text check (gender in ('Male', 'Female', 'Other'));

alter table public.profiles 
add column if not exists profile_photo_url text;

alter table public.profiles 
add column if not exists degrees text[] default '{}';

alter table public.profiles 
add column if not exists aravind_centre text;

alter table public.profiles 
add column if not exists id_number text;

alter table public.profiles 
add column if not exists date_of_joining date;

alter table public.profiles 
add column if not exists hod_name text;

-- Add comments for documentation
comment on column public.profiles.gender is 'User gender: Male, Female, or Other';
comment on column public.profiles.profile_photo_url is 'URL to user profile photo in storage';
comment on column public.profiles.degrees is 'Array of degrees (DO, MS/MD, DNB, etc.)';
comment on column public.profiles.aravind_centre is 'Aravind centre location';
comment on column public.profiles.id_number is 'Additional ID number';
comment on column public.profiles.date_of_joining is 'Date user joined Aravind';
comment on column public.profiles.hod_name is 'Head of Department name';

-- Verify the table structure
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' 
and table_name = 'profiles'
order by ordinal_position;
