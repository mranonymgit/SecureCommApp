begin;

-- Supabase test accounts must pass the API's EmailStr validation. These values
-- only update the two bootstrap records created before this correction.
update app.users
set email = 'admin@sca.mx'
where email = 'admin@sca.local'
  and role = 'admin'
  and deleted_at is null;

update app.users
set email = 'residente@sca.mx'
where email = 'residente@sca.local'
  and role = 'resident'
  and deleted_at is null;

commit;
