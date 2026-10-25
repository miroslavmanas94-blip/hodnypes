-- Additive extension for dog profile details. Existing profiles and permissions are preserved.
alter table public.dog_profiles
  add column if not exists description text not null default '' check (char_length(description) <= 5000);
alter table public.dog_profiles
  add column if not exists visibility text not null default 'public' check (visibility in ('public','followers','private'));
alter table public.dog_profiles
  add column if not exists sports_skills text not null default '' check (char_length(sports_skills) <= 2000);
alter table public.dog_profiles
  add column if not exists favorite_activities text not null default '' check (char_length(favorite_activities) <= 2000);
