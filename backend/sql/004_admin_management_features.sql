begin;

create type app.password_change_status as enum ('pending', 'approved', 'rejected');

create table app.password_change_requests (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references app.communities(id) on delete restrict,
  user_id uuid not null references app.users(id) on delete restrict,
  requested_password_hash text not null,
  status app.password_change_status not null default 'pending',
  reviewed_by_user_id uuid null references app.users(id) on delete restrict,
  reviewed_at timestamptz null,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index uq_password_change_request_pending
  on app.password_change_requests (community_id, user_id)
  where status = 'pending' and deleted_at is null;

create index idx_password_change_requests_admin
  on app.password_change_requests (community_id, status, created_at desc)
  where deleted_at is null;

create trigger trg_password_change_requests_updated_at
  before update on app.password_change_requests
  for each row execute function app.set_updated_at();
create trigger trg_password_change_requests_audit
  after insert or update or delete on app.password_change_requests
  for each row execute function app.audit_row_change();

alter table app.password_change_requests enable row level security;
create policy password_change_requests_scope on app.password_change_requests
  for all
  using (
    community_id = app.current_community_id()
    and deleted_at is null
    and (user_id = app.current_user_id() or app.has_role(array['admin']::app.user_role[]))
  )
  with check (
    community_id = app.current_community_id()
    and (user_id = app.current_user_id() or app.has_role(array['admin']::app.user_role[]))
  );

commit;
