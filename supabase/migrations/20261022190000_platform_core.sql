-- Hodný pes platform foundation: core member features with RLS and realtime.
create extension if not exists pgcrypto;

create table if not exists public.hp_posts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 3000),
 post_type text not null default 'text' check (post_type in ('text','training','question','achievement','poll','event','guide')),
 visibility text not null default 'public' check (visibility in ('public','followers','private')),
 dog_id uuid references public.dog_profiles(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.hp_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.hp_posts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 1200),
 created_at timestamptz not null default now()
);
create table if not exists public.hp_reactions (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.hp_posts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 reaction text not null default 'paw' check (reaction in ('paw','heart','laugh','clap','fire','love','useful','support')),
 created_at timestamptz not null default now(),
 unique(post_id,user_id)
);
create table if not exists public.hp_follows (
 follower_id uuid not null references auth.users(id) on delete cascade,
 following_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(follower_id,following_id),
 check(follower_id <> following_id)
);
create table if not exists public.hp_groups (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 name text not null check (char_length(name) between 2 and 100),
 description text not null default '' check (char_length(description)<=1000),
 visibility text not null default 'public' check (visibility in ('public','private')),
 created_at timestamptz not null default now()
);
create table if not exists public.hp_group_members (
 group_id uuid not null references public.hp_groups(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','moderator','member')),
 created_at timestamptz not null default now(),
 primary key(group_id,user_id)
);
create table if not exists public.hp_events (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(title) between 3 and 160),
 description text not null default '' check(char_length(description)<=5000),
 event_type text not null default 'meetup' check(event_type in ('meetup','competition','seminar','course','camp','workshop','open_day','webinar')),
 starts_at timestamptz not null,
 ends_at timestamptz,
 capacity integer check(capacity is null or capacity > 0),
 dog_suitability text not null default 'all' check(dog_suitability in ('all','puppies','experienced','reactive_friendly')),
 notes text not null default '' check(char_length(notes)<=2000),
 status text not null default 'published' check(status in ('draft','published','cancelled')),
 created_at timestamptz not null default now(),
 check(ends_at is null or ends_at >= starts_at)
);
create table if not exists public.hp_event_registrations (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.hp_events(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 dog_id uuid references public.dog_profiles(id) on delete set null,
 status text not null default 'registered' check(status in ('registered','waitlist','cancelled','attended')),
 created_at timestamptz not null default now(),
 unique(event_id,user_id,dog_id)
);
create table if not exists public.hp_missions (
 id uuid primary key default gen_random_uuid(),
 title text not null check(char_length(title) between 3 and 160),
 description text not null default '' check(char_length(description)<=2000),
 category text not null default 'daily',
 difficulty integer not null default 1 check(difficulty between 1 and 5),
 points integer not null default 10 check(points between 0 and 1000),
 cadence text not null default 'daily' check(cadence in ('daily','weekly','individual','seasonal')),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.hp_mission_completions (
 id uuid primary key default gen_random_uuid(),
 mission_id uuid not null references public.hp_missions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 dog_id uuid references public.dog_profiles(id) on delete set null,
 note text not null default '' check(char_length(note)<=1000),
 completed_at timestamptz not null default now(),
 unique(mission_id,user_id,dog_id,completed_at)
);
create table if not exists public.hp_training_entries (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 dog_id uuid references public.dog_profiles(id) on delete set null,
 activity text not null check(char_length(activity) between 2 and 120),
 duration_minutes integer not null default 10 check(duration_minutes between 1 and 1440),
 mood integer check(mood between 1 and 5),
 success_rating integer check(success_rating between 1 and 5),
 notes text not null default '' check(char_length(notes)<=4000),
 next_goal text not null default '' check(char_length(next_goal)<=1000),
 created_at timestamptz not null default now()
);
create table if not exists public.hp_courses (
 id uuid primary key default gen_random_uuid(),
 title text not null check(char_length(title) between 3 and 180),
 summary text not null default '' check(char_length(summary)<=1500),
 category text not null default 'training',
 difficulty text not null default 'beginner' check(difficulty in ('beginner','intermediate','advanced')),
 language text not null default 'cs' check(language in ('cs','en')),
 is_paid boolean not null default false,
 published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.hp_lessons (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.hp_courses(id) on delete cascade,
 title text not null check(char_length(title) between 2 and 180),
 content text not null default '' check(char_length(content)<=20000),
 position integer not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.hp_course_progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 course_id uuid not null references public.hp_courses(id) on delete cascade,
 lesson_id uuid references public.hp_lessons(id) on delete cascade,
 completed_at timestamptz not null default now(),
 primary key(user_id,course_id,lesson_id)
);
create table if not exists public.hp_articles (
 id uuid primary key default gen_random_uuid(),
 author_id uuid references auth.users(id) on delete set null,
 title text not null check(char_length(title) between 3 and 200),
 summary text not null default '' check(char_length(summary)<=1200),
 body text not null default '' check(char_length(body)<=30000),
 category text not null default 'training',
 language text not null default 'cs' check(language in ('cs','en')),
 status text not null default 'pending' check(status in ('draft','pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create table if not exists public.hp_notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 kind text not null default 'system',
 title text not null check(char_length(title) between 1 and 160),
 body text not null default '' check(char_length(body)<=1500),
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.hp_user_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 language text not null default 'cs' check(language in ('cs','en')),
 notification_preferences jsonb not null default '{"messages":true,"community":true,"missions":true,"events":true,"courses":true}'::jsonb,
 profile_visibility text not null default 'public' check(profile_visibility in ('public','followers','private')),
 digest text not null default 'off' check(digest in ('off','daily','weekly')),
 updated_at timestamptz not null default now()
);
create table if not exists public.hp_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references auth.users(id) on delete cascade,
 target_type text not null check(target_type in ('post','comment','profile','group','event','article')),
 target_id uuid not null,
 reason text not null check(char_length(reason) between 3 and 1000),
 status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')),
 created_at timestamptz not null default now()
);

create index if not exists hp_posts_created_idx on public.hp_posts(created_at desc);
create index if not exists hp_comments_post_idx on public.hp_comments(post_id,created_at);
create index if not exists hp_events_start_idx on public.hp_events(starts_at) where status='published';
create index if not exists hp_notifications_user_idx on public.hp_notifications(user_id,created_at desc);
create index if not exists hp_training_user_idx on public.hp_training_entries(user_id,created_at desc);
create index if not exists hp_articles_status_idx on public.hp_articles(status,created_at desc);

alter table public.hp_posts enable row level security;
alter table public.hp_comments enable row level security;
alter table public.hp_reactions enable row level security;
alter table public.hp_follows enable row level security;
alter table public.hp_groups enable row level security;
alter table public.hp_group_members enable row level security;
alter table public.hp_events enable row level security;
alter table public.hp_event_registrations enable row level security;
alter table public.hp_missions enable row level security;
alter table public.hp_mission_completions enable row level security;
alter table public.hp_training_entries enable row level security;
alter table public.hp_courses enable row level security;
alter table public.hp_lessons enable row level security;
alter table public.hp_course_progress enable row level security;
alter table public.hp_articles enable row level security;
alter table public.hp_notifications enable row level security;
alter table public.hp_user_preferences enable row level security;
alter table public.hp_reports enable row level security;

do $$
declare t text;
begin
 foreach t in array array['hp_posts','hp_comments','hp_reactions','hp_follows','hp_groups','hp_group_members','hp_events','hp_event_registrations','hp_missions','hp_mission_completions','hp_training_entries','hp_courses','hp_lessons','hp_course_progress','hp_articles','hp_notifications','hp_user_preferences','hp_reports'] loop
   execute format('drop policy if exists %I on public.%I',t||'_select',t);
   execute format('drop policy if exists %I on public.%I',t||'_insert',t);
   execute format('drop policy if exists %I on public.%I',t||'_update',t);
   execute format('drop policy if exists %I on public.%I',t||'_delete',t);
 end loop;
end $$;

create policy hp_posts_select on public.hp_posts for select to authenticated using (visibility='public' or user_id=auth.uid());
create policy hp_posts_insert on public.hp_posts for insert to authenticated with check (user_id=auth.uid());
create policy hp_posts_update on public.hp_posts for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy hp_posts_delete on public.hp_posts for delete to authenticated using (user_id=auth.uid());
create policy hp_comments_select on public.hp_comments for select to authenticated using (exists(select 1 from public.hp_posts p where p.id=post_id and (p.visibility='public' or p.user_id=auth.uid())));
create policy hp_comments_insert on public.hp_comments for insert to authenticated with check (user_id=auth.uid() and exists(select 1 from public.hp_posts p where p.id=post_id and p.visibility='public'));
create policy hp_comments_delete on public.hp_comments for delete to authenticated using (user_id=auth.uid());
create policy hp_reactions_select on public.hp_reactions for select to authenticated using (true);
create policy hp_reactions_insert on public.hp_reactions for insert to authenticated with check (user_id=auth.uid());
create policy hp_reactions_update on public.hp_reactions for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy hp_reactions_delete on public.hp_reactions for delete to authenticated using (user_id=auth.uid());
create policy hp_follows_select on public.hp_follows for select to authenticated using (follower_id=auth.uid() or following_id=auth.uid());
create policy hp_follows_insert on public.hp_follows for insert to authenticated with check (follower_id=auth.uid());
create policy hp_follows_delete on public.hp_follows for delete to authenticated using (follower_id=auth.uid());
create policy hp_groups_select on public.hp_groups for select to authenticated using (visibility='public' or owner_id=auth.uid() or exists(select 1 from public.hp_group_members gm where gm.group_id=id and gm.user_id=auth.uid()));
create policy hp_groups_insert on public.hp_groups for insert to authenticated with check(owner_id=auth.uid());
create policy hp_groups_update on public.hp_groups for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy hp_groups_delete on public.hp_groups for delete to authenticated using(owner_id=auth.uid());
create policy hp_group_members_select on public.hp_group_members for select to authenticated using (user_id=auth.uid());
create policy hp_group_members_insert on public.hp_group_members for insert to authenticated with check(user_id=auth.uid());
create policy hp_group_members_delete on public.hp_group_members for delete to authenticated using(user_id=auth.uid() or exists(select 1 from public.hp_groups g where g.id=group_id and g.owner_id=auth.uid()));
create policy hp_events_select on public.hp_events for select to authenticated using(status='published' or owner_id=auth.uid());
create policy hp_events_insert on public.hp_events for insert to authenticated with check(owner_id=auth.uid());
create policy hp_events_update on public.hp_events for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy hp_events_delete on public.hp_events for delete to authenticated using(owner_id=auth.uid());
create policy hp_event_registrations_select on public.hp_event_registrations for select to authenticated using(user_id=auth.uid() or exists(select 1 from public.hp_events e where e.id=event_id and e.owner_id=auth.uid()));
create policy hp_event_registrations_insert on public.hp_event_registrations for insert to authenticated with check(user_id=auth.uid());
create policy hp_event_registrations_update on public.hp_event_registrations for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy hp_event_registrations_delete on public.hp_event_registrations for delete to authenticated using(user_id=auth.uid());
create policy hp_missions_select on public.hp_missions for select to authenticated using(active);
create policy hp_missions_insert on public.hp_missions for insert to authenticated with check(false);
create policy hp_mission_completions_select on public.hp_mission_completions for select to authenticated using(user_id=auth.uid());
create policy hp_mission_completions_insert on public.hp_mission_completions for insert to authenticated with check(user_id=auth.uid());
create policy hp_mission_completions_delete on public.hp_mission_completions for delete to authenticated using(user_id=auth.uid());
create policy hp_training_entries_select on public.hp_training_entries for select to authenticated using(user_id=auth.uid());
create policy hp_training_entries_insert on public.hp_training_entries for insert to authenticated with check(user_id=auth.uid());
create policy hp_training_entries_update on public.hp_training_entries for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy hp_training_entries_delete on public.hp_training_entries for delete to authenticated using(user_id=auth.uid());
create policy hp_courses_select on public.hp_courses for select to authenticated using(published or exists(select 1 from public.hp_course_progress cp where cp.course_id=id and cp.user_id=auth.uid()));
create policy hp_courses_insert on public.hp_courses for insert to authenticated with check(false);
create policy hp_lessons_select on public.hp_lessons for select to authenticated using(exists(select 1 from public.hp_courses c where c.id=course_id and c.published));
create policy hp_lessons_insert on public.hp_lessons for insert to authenticated with check(false);
create policy hp_course_progress_select on public.hp_course_progress for select to authenticated using(user_id=auth.uid());
create policy hp_course_progress_insert on public.hp_course_progress for insert to authenticated with check(user_id=auth.uid());
create policy hp_articles_select on public.hp_articles for select to authenticated using(status='approved' or author_id=auth.uid());
create policy hp_articles_insert on public.hp_articles for insert to authenticated with check(author_id=auth.uid() and status in ('draft','pending'));
create policy hp_articles_update on public.hp_articles for update to authenticated using(author_id=auth.uid() and status in ('draft','pending')) with check(author_id=auth.uid() and status in ('draft','pending'));
create policy hp_notifications_select on public.hp_notifications for select to authenticated using(user_id=auth.uid());
create policy hp_notifications_update on public.hp_notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy hp_user_preferences_select on public.hp_user_preferences for select to authenticated using(user_id=auth.uid());
create policy hp_user_preferences_insert on public.hp_user_preferences for insert to authenticated with check(user_id=auth.uid());
create policy hp_user_preferences_update on public.hp_user_preferences for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy hp_reports_select on public.hp_reports for select to authenticated using(reporter_id=auth.uid());
create policy hp_reports_insert on public.hp_reports for insert to authenticated with check(reporter_id=auth.uid());

-- Seed mission templates only; these are official system missions, not fake user data.
insert into public.hp_missions(title,description,category,difficulty,points,cadence,active)
select v.title,v.description,v.category,v.difficulty,v.points,v.cadence,true
from (values
 ('Pět minut pozornosti','V klidu si se psem procvičte oční kontakt a odměňte každý dobrovolný pohled.','poslušnost',1,10,'daily'),
 ('Přivolání s odměnou','Natrénujte několik krátkých přivolání v bezpečném prostředí.','přivolání',2,20,'weekly'),
 ('Klid na místě','Odměňte psa za klidné setrvání na pelíšku nebo podložce.','klid',1,10,'daily'),
 ('Nový trik','Rozdělte nový trik na malé kroky a skončete úspěchem.','triky',2,20,'weekly'),
 ('Čichací hra','Schovejte několik pamlsků do bezpečné čichací hry.','nosework',1,10,'daily'),
 ('Pozitivní socializace','Z bezpečné vzdálenosti odměňte klidné pozorování okolí.','socializace',2,20,'weekly')
) v(title,description,category,difficulty,points,cadence)
where not exists(select 1 from public.hp_missions m where m.title=v.title);

do $$ begin
 alter publication supabase_realtime add table public.hp_posts;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.hp_comments;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.hp_notifications;
exception when duplicate_object then null; when undefined_object then null; end $$;
