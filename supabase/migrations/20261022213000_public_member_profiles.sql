create table if not exists public.hp_public_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 username text not null unique check(char_length(username) between 3 and 30),
 first_name text not null default '' check(char_length(first_name)<=80),
 last_name text not null default '' check(char_length(last_name)<=80),
 city text not null default '' check(char_length(city)<=120),
 bio text not null default '' check(char_length(bio)<=1000),
 website text not null default '' check(char_length(website)<=300),
 avatar_url text not null default '' check(char_length(avatar_url)<=2048),
 interests text[] not null default '{}',
 profile_visibility text not null default 'public' check(profile_visibility in ('public','followers','private')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.hp_public_profiles enable row level security;
create policy hp_public_profiles_select on public.hp_public_profiles for select to authenticated
 using(profile_visibility='public' or user_id=auth.uid() or (profile_visibility='followers' and exists(select 1 from public.hp_follows f where f.follower_id=auth.uid() and f.following_id=user_id)));
create policy hp_public_profiles_insert on public.hp_public_profiles for insert to authenticated with check(user_id=auth.uid());
create policy hp_public_profiles_update on public.hp_public_profiles for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy hp_public_profiles_delete on public.hp_public_profiles for delete to authenticated using(user_id=auth.uid());