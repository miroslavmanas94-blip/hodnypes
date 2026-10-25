-- Expose only non-sensitive fields for explicitly public dog profiles.
-- Health notes, owner identifiers, exact birth dates and private profiles are intentionally excluded.
create or replace view public.hp_public_dog_profiles as
select id, name, breed_name, breed_registry, sex, photo_url, temperament, goals,
       size, coat_color, activities, adoption, description, sports_skills,
       favorite_activities, created_at
from public.dog_profiles
where visibility = 'public';
grant select on public.hp_public_dog_profiles to anon, authenticated;
