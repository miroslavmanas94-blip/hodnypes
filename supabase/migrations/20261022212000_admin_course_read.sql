create policy hp_courses_admin_select on public.hp_courses for select to authenticated
 using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy hp_lessons_admin_select on public.hp_lessons for select to authenticated
 using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='admin'));