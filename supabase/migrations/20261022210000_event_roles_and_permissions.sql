alter table public.user_roles drop constraint if exists user_roles_role_check;
alter table public.user_roles add constraint user_roles_role_check
 check (role = any (array['member','trainer','admin','event_organizer','moderator']::text[]));

drop policy if exists hp_events_insert on public.hp_events;
create policy hp_events_insert on public.hp_events for insert to authenticated
 with check (
   owner_id=auth.uid()
   and (
     event_type='meetup'
     or exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role in ('trainer','admin','event_organizer'))
   )
);
