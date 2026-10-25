-- Additive chat capabilities for Hodný pes. Existing rows and policies are preserved.
alter table public.hp_messages
  add column if not exists media_path text,
  add column if not exists media_type text,
  add column if not exists reply_to uuid references public.hp_messages(id) on delete set null;
create index if not exists hp_messages_reply_to_idx on public.hp_messages(reply_to) where reply_to is not null;

create table if not exists public.hp_group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.hp_groups(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  media_path text,
  media_type text,
  reply_to uuid references public.hp_group_messages(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists hp_group_messages_group_time_idx on public.hp_group_messages(group_id, created_at desc);
alter table public.hp_group_messages enable row level security;
drop policy if exists hp_group_messages_select_member on public.hp_group_messages;
create policy hp_group_messages_select_member on public.hp_group_messages for select to authenticated using (
  exists (select 1 from public.hp_group_members gm where gm.group_id = hp_group_messages.group_id and gm.user_id = auth.uid())
);
drop policy if exists hp_group_messages_insert_member on public.hp_group_messages;
create policy hp_group_messages_insert_member on public.hp_group_messages for insert to authenticated with check (
  sender_id = auth.uid() and exists (select 1 from public.hp_group_members gm where gm.group_id = hp_group_messages.group_id and gm.user_id = auth.uid())
);
drop policy if exists hp_group_messages_delete_sender on public.hp_group_messages;
create policy hp_group_messages_delete_sender on public.hp_group_messages for delete to authenticated using (sender_id = auth.uid());

-- Typing events are ephemeral and scoped to direct-message participants or group members.
drop policy if exists hp_chat_typing_read on realtime.messages;
create policy hp_chat_typing_read on realtime.messages for select to authenticated using (
  (realtime.topic() like 'hp-dm-%' and position(auth.uid()::text in realtime.topic()) > 0)
  or (realtime.topic() like 'hp-group-%' and exists (
    select 1 from public.hp_group_members gm
    where gm.group_id::text = substring(realtime.topic() from 10) and gm.user_id = auth.uid()
  ))
);
drop policy if exists hp_chat_typing_send on realtime.messages;
create policy hp_chat_typing_send on realtime.messages for insert to authenticated with check (
  (realtime.topic() like 'hp-dm-%' and position(auth.uid()::text in realtime.topic()) > 0)
  or (realtime.topic() like 'hp-group-%' and exists (
    select 1 from public.hp_group_members gm
    where gm.group_id::text = substring(realtime.topic() from 10) and gm.user_id = auth.uid()
  ))
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('hp-chat-media','hp-chat-media',false,15728640,
  array['image/jpeg','image/png','image/webp','video/mp4','audio/webm','audio/mp4','audio/mpeg','audio/ogg','audio/wav'])
on conflict (id) do update set public=false,file_size_limit=15728640,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists hp_chat_media_upload_own on storage.objects;
create policy hp_chat_media_upload_own on storage.objects for insert to authenticated with check (
  bucket_id='hp-chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text
);
drop policy if exists hp_chat_media_read_participants on storage.objects;
create policy hp_chat_media_read_participants on storage.objects for select to authenticated using (
  bucket_id='hp-chat-media' and (
    (storage.foldername(name))[1]=(select auth.uid())::text
    or exists(select 1 from public.hp_messages m where m.media_path=name and (m.sender_id=auth.uid() or m.recipient_id=auth.uid()))
    or exists(select 1 from public.hp_group_messages gm join public.hp_group_members member on member.group_id=gm.group_id where gm.media_path=name and member.user_id=auth.uid())
  )
);
drop policy if exists hp_chat_media_delete_own on storage.objects;
create policy hp_chat_media_delete_own on storage.objects for delete to authenticated using (
  bucket_id='hp-chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text
);
do $$ begin alter publication supabase_realtime add table public.hp_group_messages;
exception when duplicate_object then null; when undefined_object then null; end $$;
