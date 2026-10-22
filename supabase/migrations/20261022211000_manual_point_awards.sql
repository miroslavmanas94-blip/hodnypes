create table if not exists public.hp_point_awards (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 awarded_by uuid not null references auth.users(id) on delete restrict,
 points integer not null check(points between 1 and 10000),
 reason text not null check(char_length(reason) between 3 and 500),
 created_at timestamptz not null default now()
);
create index if not exists hp_point_awards_user_idx on public.hp_point_awards(user_id,created_at desc);
alter table public.hp_point_awards enable row level security;
create policy hp_point_awards_select on public.hp_point_awards for select to authenticated using(user_id=auth.uid());
create policy hp_point_awards_admin_select on public.hp_point_awards for select to authenticated
 using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_point_awards_admin_insert on public.hp_point_awards for insert to authenticated
 with check(awarded_by=auth.uid() and exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
