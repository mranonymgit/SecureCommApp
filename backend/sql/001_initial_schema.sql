create schema if not exists app;

create extension if not exists pgcrypto;
create extension if not exists citext;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type app.user_role as enum ('admin', 'resident');
  end if;
  if not exists (select 1 from pg_type where typname = 'account_status') then
    create type app.account_status as enum ('pending', 'active', 'suspended', 'archived');
  end if;
  if not exists (select 1 from pg_type where typname = 'visit_status') then
    create type app.visit_status as enum ('requested', 'approved', 'inside', 'exited', 'denied', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'report_status') then
    create type app.report_status as enum ('pending', 'in_progress', 'resolved', 'critical', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'announcement_category') then
    create type app.announcement_category as enum ('general', 'maintenance', 'meeting', 'security', 'urgent');
  end if;
  if not exists (select 1 from pg_type where typname = 'chat_thread_type') then
    create type app.chat_thread_type as enum ('community', 'support');
  end if;
  if not exists (select 1 from pg_type where typname = 'panic_status') then
    create type app.panic_status as enum ('inactive', 'active', 'resolved');
  end if;
  if not exists (select 1 from pg_type where typname = 'access_action') then
    create type app.access_action as enum ('entry', 'exit', 'validation', 'revocation');
  end if;
end $$;

create or replace function app.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function app.current_user_id()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('app.user_id', true), '')::uuid
$$;

create or replace function app.current_community_id()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('app.community_id', true), '')::uuid
$$;

create or replace function app.current_user_role()
returns app.user_role
language sql
stable
as $$
  select nullif(current_setting('app.user_role', true), '')::app.user_role
$$;

create or replace function app.has_role(allowed app.user_role[])
returns boolean
language sql
stable
as $$
  select coalesce(app.current_user_role() = any(allowed), false)
$$;

create or replace function app.audit_row_change()
returns trigger
language plpgsql
as $$
declare
  old_payload jsonb;
  new_payload jsonb;
begin
  if tg_op = 'DELETE' then
    old_payload := to_jsonb(old);
    new_payload := null;
  elsif tg_op = 'UPDATE' then
    old_payload := to_jsonb(old);
    new_payload := to_jsonb(new);
  else
    old_payload := null;
    new_payload := to_jsonb(new);
  end if;

  insert into app.audit_log (
    id,
    community_id,
    table_name,
    row_id,
    action,
    changed_by_user_id,
    old_data,
    new_data,
    created_at
  )
  values (
    gen_random_uuid(),
    coalesce(new.community_id, old.community_id),
    tg_table_name,
    coalesce(new.id, old.id),
    tg_op,
    app.current_user_id(),
    old_payload,
    new_payload,
    now()
  );

  return coalesce(new, old);
end;
$$;

create table if not exists app.communities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status app.account_status not null default 'active',
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.units (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  tower text not null,
  unit_number text not null,
  floor integer null,
  status app.account_status not null default 'active',
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, tower, unit_number)
);

create table if not exists app.users (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  unit_id uuid null references app.units(id) on delete restrict,
  role app.user_role not null,
  full_name text not null,
  email citext not null,
  phone text not null,
  password_hash text null,
  avatar_url text null,
  document_ciphertext bytea null,
  status app.account_status not null default 'pending',
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, email),
  unique (community_id, phone)
);

create table if not exists app.resident_profiles (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  unit_id uuid not null references app.units(id) on delete restrict,
  blood_type text null,
  conditions text null,
  allergies text null,
  emergency_contact_name text null,
  emergency_contact_phone_ciphertext bytea null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists app.visits (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  resident_user_id uuid not null references app.users(id) on delete restrict,
  visitor_name text not null,
  visitor_type text not null,
  qr_code text not null unique,
  plate_ciphertext bytea null,
  status app.visit_status not null default 'requested',
  entry_guard_id uuid null references app.users(id) on delete restrict,
  exit_guard_id uuid null references app.users(id) on delete restrict,
  entry_at timestamptz null,
  exit_at timestamptz null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.access_logs (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  visit_id uuid not null references app.visits(id) on delete restrict,
  actor_user_id uuid null references app.users(id) on delete restrict,
  action app.access_action not null,
  details jsonb not null default '{}'::jsonb,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.announcements (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  created_by_user_id uuid not null references app.users(id) on delete restrict,
  category app.announcement_category not null default 'general',
  title text not null,
  content text not null,
  image_url text null,
  is_important boolean not null default false,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.announcement_reactions (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  announcement_id uuid not null references app.announcements(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  reaction text not null check (reaction in ('like', 'dislike')),
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, announcement_id, user_id)
);

create table if not exists app.chat_threads (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  thread_type app.chat_thread_type not null,
  title text not null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.chat_messages (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  thread_id uuid not null references app.chat_threads(id) on delete restrict,
  sender_user_id uuid not null references app.users(id) on delete restrict,
  body text not null,
  audio_url text null,
  audio_duration text null,
  is_admin boolean not null default false,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.reports (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  reporter_user_id uuid not null references app.users(id) on delete restrict,
  title text not null,
  description text not null,
  latitude numeric(10, 7) null,
  longitude numeric(10, 7) null,
  status app.report_status not null default 'pending',
  assigned_to_user_id uuid null references app.users(id) on delete restrict,
  evidence_url text null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.panic_alerts (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  resident_user_id uuid not null references app.users(id) on delete restrict,
  activated_by_user_id uuid not null references app.users(id) on delete restrict,
  status app.panic_status not null default 'active',
  message text null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.audit_log (
  id uuid primary key default gen_random_uuid(),
  community_id uuid null references app.communities(id) on delete set null,
  table_name text not null,
  row_id uuid null,
  action text not null,
  changed_by_user_id uuid null references app.users(id) on delete set null,
  old_data jsonb null,
  new_data jsonb null,
  created_at timestamptz not null default now()
);

create index if not exists idx_users_community_active on app.users(community_id) where deleted_at is null;
create index if not exists idx_reports_community_active on app.reports(community_id) where deleted_at is null;
create index if not exists idx_visits_community_active on app.visits(community_id) where deleted_at is null;
create index if not exists idx_announcements_community_active on app.announcements(community_id) where deleted_at is null;
create index if not exists idx_chat_messages_thread_active on app.chat_messages(thread_id) where deleted_at is null;

create unique index if not exists ux_users_community_email_active on app.users(community_id, lower(email)) where deleted_at is null;
create unique index if not exists ux_users_community_phone_active on app.users(community_id, phone) where deleted_at is null;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_users_updated_at'
  ) then
    create trigger trg_users_updated_at
    before update on app.users
    for each row execute function app.set_updated_at();
  end if;
end $$;

create trigger trg_units_updated_at before update on app.units for each row execute function app.set_updated_at();
create trigger trg_resident_profiles_updated_at before update on app.resident_profiles for each row execute function app.set_updated_at();
create trigger trg_visits_updated_at before update on app.visits for each row execute function app.set_updated_at();
create trigger trg_access_logs_updated_at before update on app.access_logs for each row execute function app.set_updated_at();
create trigger trg_announcements_updated_at before update on app.announcements for each row execute function app.set_updated_at();
create trigger trg_chat_threads_updated_at before update on app.chat_threads for each row execute function app.set_updated_at();
create trigger trg_chat_messages_updated_at before update on app.chat_messages for each row execute function app.set_updated_at();
create trigger trg_reports_updated_at before update on app.reports for each row execute function app.set_updated_at();
create trigger trg_panic_alerts_updated_at before update on app.panic_alerts for each row execute function app.set_updated_at();

create trigger trg_users_audit after insert or update or delete on app.users for each row execute function app.audit_row_change();
create trigger trg_visits_audit after insert or update or delete on app.visits for each row execute function app.audit_row_change();
create trigger trg_access_logs_audit after insert or update or delete on app.access_logs for each row execute function app.audit_row_change();
create trigger trg_panic_alerts_audit after insert or update or delete on app.panic_alerts for each row execute function app.audit_row_change();
create trigger trg_reports_audit after insert or update or delete on app.reports for each row execute function app.audit_row_change();

alter table app.communities enable row level security;
alter table app.units enable row level security;
alter table app.users enable row level security;
alter table app.resident_profiles enable row level security;
alter table app.visits enable row level security;
alter table app.access_logs enable row level security;
alter table app.announcements enable row level security;
alter table app.chat_threads enable row level security;
alter table app.chat_messages enable row level security;
alter table app.reports enable row level security;
alter table app.panic_alerts enable row level security;
alter table app.audit_log enable row level security;

create policy communities_scope on app.communities
  for all
  using (id = app.current_community_id() and deleted_at is null)
  with check (id = app.current_community_id());

create policy units_scope on app.units
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy users_scope on app.users
  for all
  using (
    community_id = app.current_community_id()
    and deleted_at is null
    and (id = app.current_user_id() or app.has_role(array['admin']::app.user_role[]))
  )
  with check (
    community_id = app.current_community_id()
    and (app.has_role(array['admin']::app.user_role[]) or id = app.current_user_id())
  );

create policy resident_profiles_scope on app.resident_profiles
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy visits_scope on app.visits
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy access_logs_scope on app.access_logs
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy announcements_scope on app.announcements
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy chat_threads_scope on app.chat_threads
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy chat_messages_scope on app.chat_messages
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy reports_scope on app.reports
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy panic_alerts_scope on app.panic_alerts
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id());

create policy audit_scope on app.audit_log
  for select
  using (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));
