create policy hp_articles_admin_select on public.hp_articles for select to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_events_admin_select on public.hp_events for select to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_events_admin_update on public.hp_events for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_events_admin_delete on public.hp_events for delete to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));