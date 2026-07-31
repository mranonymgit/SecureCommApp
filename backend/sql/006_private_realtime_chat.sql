begin;

-- Broadcast is intentionally used instead of Postgres Changes. FastAPI remains
-- the source of truth for history and writes; Realtime only signals a change.
create or replace function app.realtime_can_access_chat(topic text)
returns boolean
language sql
stable
security definer
set search_path = app, public, pg_catalog
as $$
  select
    split_part(topic, ':', 1) = 'community'
    and split_part(topic, ':', 3) = 'thread'
    and (auth.jwt() ->> 'community_id') = split_part(topic, ':', 2)
    and exists (
      select 1
      from app.users u
      join app.chat_threads t on t.id::text = split_part(topic, ':', 4)
      where u.id = auth.uid()
        and u.community_id::text = split_part(topic, ':', 2)
        and u.role::text = (auth.jwt() ->> 'user_role')
        and t.community_id = u.community_id
        and t.thread_type = 'community'
        and u.status = 'active'
        and u.deleted_at is null
        and t.deleted_at is null
    );
$$;

create or replace function app.realtime_can_access_user_topic(topic text)
returns boolean
language sql
stable
security definer
set search_path = app, public, pg_catalog
as $$
  select
    split_part(topic, ':', 1) = 'community'
    and split_part(topic, ':', 3) = 'user'
    and (auth.jwt() ->> 'community_id') = split_part(topic, ':', 2)
    and auth.uid()::text = split_part(topic, ':', 4)
    and exists (
      select 1 from app.users u
      where u.id = auth.uid()
        and u.community_id::text = split_part(topic, ':', 2)
        and u.role::text = (auth.jwt() ->> 'user_role')
        and u.status = 'active'
        and u.deleted_at is null
    );
$$;

drop policy if exists "sca_chat_broadcast_read" on realtime.messages;
create policy "sca_chat_broadcast_read"
on realtime.messages for select to authenticated
using (
  realtime.messages.extension in ('broadcast', 'presence')
  and (
    app.realtime_can_access_chat(realtime.topic())
    or app.realtime_can_access_user_topic(realtime.topic())
  )
);

drop policy if exists "sca_chat_broadcast_write" on realtime.messages;
create policy "sca_chat_broadcast_write"
on realtime.messages for insert to authenticated
with check (
  realtime.messages.extension in ('broadcast', 'presence')
  and (
    app.realtime_can_access_chat(realtime.topic())
    or app.realtime_can_access_user_topic(realtime.topic())
  )
);

create or replace function app.broadcast_chat_message()
returns trigger
language plpgsql
security definer
set search_path = app, public, pg_catalog
as $$
declare
  record_row app.chat_messages;
begin
  if TG_OP = 'DELETE' then
    record_row := old;
  else
    record_row := new;
  end if;
  perform realtime.send(
    jsonb_build_object('table', TG_TABLE_NAME, 'action', TG_OP),
    TG_OP,
    'community:' || record_row.community_id::text || ':thread:' || record_row.thread_id::text,
    true
  );
  return null;
end;
$$;

drop trigger if exists trg_chat_messages_broadcast on app.chat_messages;
create trigger trg_chat_messages_broadcast
after insert or update or delete on app.chat_messages
for each row execute function app.broadcast_chat_message();

create or replace function app.broadcast_user_notification()
returns trigger
language plpgsql
security definer
set search_path = app, public, pg_catalog
as $$
declare
  record_row app.user_notifications;
begin
  if TG_OP = 'DELETE' then
    record_row := old;
  else
    record_row := new;
  end if;
  perform realtime.send(
    jsonb_build_object('table', TG_TABLE_NAME, 'action', TG_OP),
    TG_OP,
    'community:' || record_row.community_id::text || ':user:' || record_row.user_id::text,
    true
  );
  return null;
end;
$$;

drop trigger if exists trg_user_notifications_broadcast on app.user_notifications;
create trigger trg_user_notifications_broadcast
after insert or update or delete on app.user_notifications
for each row execute function app.broadcast_user_notification();

commit;
