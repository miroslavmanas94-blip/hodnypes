-- Admin-only publication and moderation controls.
create policy hp_courses_admin_insert on public.hp_courses for insert to authenticated
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_courses_admin_update on public.hp_courses for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_courses_admin_delete on public.hp_courses for delete to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_lessons_admin_insert on public.hp_lessons for insert to authenticated
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_lessons_admin_update on public.hp_lessons for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_lessons_admin_delete on public.hp_lessons for delete to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_articles_admin_update on public.hp_articles for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_articles_admin_delete on public.hp_articles for delete to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_reports_admin_select on public.hp_reports for select to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_reports_admin_update on public.hp_reports for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_missions_admin_insert on public.hp_missions for insert to authenticated
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_missions_admin_update on public.hp_missions for update to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'))
 with check (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_missions_admin_delete on public.hp_missions for delete to authenticated
 using (exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
