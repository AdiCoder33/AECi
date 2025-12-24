-- Add gender column to profiles table
alter table public.profiles 
add column if not exists gender text check (gender in ('Male', 'Female', 'Other'));

-- Add comment
comment on column public.profiles.gender is 'User gender: Male, Female, or Other';
