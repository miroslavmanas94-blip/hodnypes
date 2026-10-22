create unique index if not exists hp_event_registration_single_user
 on public.hp_event_registrations(event_id,user_id) where dog_id is null;

create or replace function public.hp_assign_event_waitlist()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare cap integer; active_count integer;
begin
 select capacity into cap from public.hp_events where id=new.event_id and status='published';
 if cap is null then
   new.status := 'registered';
 else
   select count(*) into active_count from public.hp_event_registrations
   where event_id=new.event_id and status in ('registered','attended');
   if active_count >= cap then new.status := 'waitlist'; else new.status := 'registered'; end if;
 end if;
 return new;
end;
$$;
drop trigger if exists hp_event_registration_capacity on public.hp_event_registrations;
create trigger hp_event_registration_capacity
before insert on public.hp_event_registrations
for each row execute function public.hp_assign_event_waitlist();

create or replace function public.hp_promote_event_waitlist()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
 if old.status in ('registered','attended') and new.status='cancelled' then
   update public.hp_event_registrations
   set status='registered'
   where id = (
     select id from public.hp_event_registrations
     where event_id=new.event_id and status='waitlist'
     order by created_at asc
     limit 1
   );
 end if;
 return new;
end;
$$;
drop trigger if exists hp_event_waitlist_promotion on public.hp_event_registrations;
create trigger hp_event_waitlist_promotion
after update of status on public.hp_event_registrations
for each row execute function public.hp_promote_event_waitlist();
