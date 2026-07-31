begin;

create schema if not exists app;
create extension if not exists pgcrypto;
create extension if not exists citext;

alter table app.users add column if not exists avatar_url text null;

-- The application exposes exactly two roles. Legacy privileged roles are folded
-- into admin before replacing the PostgreSQL enum.
drop policy if exists communities_scope on app.communities;
drop policy if exists users_scope on app.users;
drop policy if exists visits_scope on app.visits;
drop policy if exists access_logs_scope on app.access_logs;
drop policy if exists announcements_scope on app.announcements;
drop policy if exists audit_scope on app.audit_log;

do $$
begin
  if exists (
    select 1
    from pg_type type_def
    join pg_namespace namespace_def on namespace_def.oid = type_def.typnamespace
    join pg_enum enum_def on enum_def.enumtypid = type_def.oid
    where namespace_def.nspname = 'app'
      and type_def.typname = 'user_role'
      and enum_def.enumlabel in ('super_admin', 'guard', 'support')
  ) then
    update app.users
    set role = 'admin'
    where role::text in ('super_admin', 'guard', 'support');

    alter table app.users alter column role drop default;
    alter table app.users alter column role type text using role::text;
    drop function if exists app.has_role(app.user_role[]);
    drop function if exists app.current_user_role();
    drop type app.user_role;
    create type app.user_role as enum ('admin', 'resident');
    alter table app.users alter column role type app.user_role using role::app.user_role;
  end if;
end;
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

create table if not exists app.user_preferences (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  theme_mode text not null default 'default',
  notifications_enabled boolean not null default true,
  language text not null default 'es',
  address_text text null,
  home_latitude numeric(10, 7) null,
  home_longitude numeric(10, 7) null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, user_id)
);

create table if not exists app.user_notifications (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  title text not null,
  message text not null,
  source_type text not null default 'system',
  is_read boolean not null default false,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.community_rules (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  title text not null,
  description text not null,
  display_order integer not null default 0,
  is_active boolean not null default true,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.community_faqs (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  question text not null,
  answer text not null,
  is_active boolean not null default true,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app.faq_questions (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  question text not null,
  status text not null default 'pending' check (status in ('pending', 'answered', 'closed')),
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop policy if exists announcement_reactions_scope on app.announcement_reactions;
drop policy if exists user_preferences_scope on app.user_preferences;
drop policy if exists user_notifications_scope on app.user_notifications;
drop policy if exists community_rules_scope on app.community_rules;
drop policy if exists community_rules_admin_write on app.community_rules;
drop policy if exists community_faqs_scope on app.community_faqs;
drop policy if exists community_faqs_admin_write on app.community_faqs;
drop policy if exists faq_questions_scope on app.faq_questions;
drop policy if exists announcements_admin_write on app.announcements;

create index if not exists idx_announcement_reactions_active on app.announcement_reactions(announcement_id) where deleted_at is null;
create index if not exists idx_user_notifications_active on app.user_notifications(user_id) where deleted_at is null;

drop trigger if exists trg_announcement_reactions_updated_at on app.announcement_reactions;
create trigger trg_announcement_reactions_updated_at before update on app.announcement_reactions for each row execute function app.set_updated_at();
drop trigger if exists trg_user_preferences_updated_at on app.user_preferences;
create trigger trg_user_preferences_updated_at before update on app.user_preferences for each row execute function app.set_updated_at();
drop trigger if exists trg_user_notifications_updated_at on app.user_notifications;
create trigger trg_user_notifications_updated_at before update on app.user_notifications for each row execute function app.set_updated_at();
drop trigger if exists trg_community_rules_updated_at on app.community_rules;
create trigger trg_community_rules_updated_at before update on app.community_rules for each row execute function app.set_updated_at();
drop trigger if exists trg_community_faqs_updated_at on app.community_faqs;
create trigger trg_community_faqs_updated_at before update on app.community_faqs for each row execute function app.set_updated_at();
drop trigger if exists trg_faq_questions_updated_at on app.faq_questions;
create trigger trg_faq_questions_updated_at before update on app.faq_questions for each row execute function app.set_updated_at();

alter table app.announcement_reactions enable row level security;
alter table app.user_preferences enable row level security;
alter table app.user_notifications enable row level security;
alter table app.community_rules enable row level security;
alter table app.community_faqs enable row level security;
alter table app.faq_questions enable row level security;

create policy communities_scope on app.communities
  for all using (id = app.current_community_id() and deleted_at is null)
  with check (id = app.current_community_id());

create policy users_scope on app.users
  for all
  using (
    community_id = app.current_community_id()
    and deleted_at is null
    and (id = app.current_user_id() or app.has_role(array['admin']::app.user_role[]))
  )
  with check (
    community_id = app.current_community_id()
    and (id = app.current_user_id() or app.has_role(array['admin']::app.user_role[]))
  );

create policy visits_scope on app.visits
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy access_logs_scope on app.access_logs
  for all
  using (community_id = app.current_community_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy announcements_scope on app.announcements
  for select using (community_id = app.current_community_id() and deleted_at is null);
create policy announcements_admin_write on app.announcements
  for all
  using (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]))
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy announcement_reactions_scope on app.announcement_reactions
  for all
  using (community_id = app.current_community_id() and user_id = app.current_user_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and user_id = app.current_user_id());

create policy user_preferences_scope on app.user_preferences
  for all
  using (community_id = app.current_community_id() and user_id = app.current_user_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and user_id = app.current_user_id());

create policy user_notifications_scope on app.user_notifications
  for all
  using (community_id = app.current_community_id() and user_id = app.current_user_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and user_id = app.current_user_id());

create policy community_rules_scope on app.community_rules
  for select using (community_id = app.current_community_id() and deleted_at is null and is_active);
create policy community_rules_admin_write on app.community_rules
  for all
  using (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]))
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy community_faqs_scope on app.community_faqs
  for select using (community_id = app.current_community_id() and deleted_at is null and is_active);
create policy community_faqs_admin_write on app.community_faqs
  for all
  using (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]))
  with check (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

create policy faq_questions_scope on app.faq_questions
  for all
  using (community_id = app.current_community_id() and user_id = app.current_user_id() and deleted_at is null)
  with check (community_id = app.current_community_id() and user_id = app.current_user_id());

create policy audit_scope on app.audit_log
  for select
  using (community_id = app.current_community_id() and app.has_role(array['admin']::app.user_role[]));

commit;
