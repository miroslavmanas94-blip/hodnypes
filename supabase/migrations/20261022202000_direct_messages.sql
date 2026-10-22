create table if not exists public.hp_messages (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 4000),
 read_at timestamptz,
 created_at timestamptz not null default now(),
 check(sender_id <> recipient_id)
);
create index if not exists hp_messages_sender_idx on public.hp_messages(sender_id,created_at desc);
create index if not exists hp_messages_recipient_idx on public.hp_messages(recipient_id,created_at desc);
alter table public.hp_messages enable row level security;
create policy hp_messages_select on public.hp_messages for select to authenticated using(sender_id=auth.uid() or recipient_id=auth.uid());
create policy hp_messages_insert on public.hp_messages for insert to authenticated with check(sender_id=auth.uid());
create policy hp_messages_update on public.hp_messages for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid());
do $$ begin alter publication supabase_realtime add table public.hp_messages; exception when duplicate_object then null; when undefined_object then null; end $$;