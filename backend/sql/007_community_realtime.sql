begin;

-- One private community channel carries lightweight change signals. Flutter
-- then reloads only the affected repository through FastAPI, preserving signed
-- URLs and the server's authorization rules.
create or replace function app.realtime_can_access_community_topic(topic text)
returns boolean
language sql
stable
security definer
set search_path = app, public, pg_catalog
as $$
  select
    split_part(topic, ':', 1) = 'community'
    and split_part(topic, ':', 3) = 'changes'
    and (auth.jwt() ->> 'community_id') = split_part(topic, ':', 2)
    and exists (
      select 1
      from app.users u
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
    or app.realtime_can_access_community_topic(realtime.topic())
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

create or replace function app.broadcast_community_change()
returns trigger
language plpgsql
security definer
set search_path = app, public, pg_catalog
as $$
declare
  record_row jsonb;
  record_community_id text;
begin
  if TG_OP = 'DELETE' then
    record_row := to_jsonb(old);
  else
    record_row := to_jsonb(new);
  end if;
  record_community_id := record_row ->> 'community_id';
  perform realtime.send(
    jsonb_build_object('table', TG_TABLE_NAME, 'action', TG_OP),
    TG_OP,
    'community:' || record_community_id || ':changes',
    true
  );
  return null;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users',
    'resident_profiles',
    'visits',
    'access_logs',
    'announcements',
    'announcement_reactions',
    'reports',
    'panic_alerts',
    'community_rules',
    'community_faqs',
    'faq_questions',
    'password_change_requests'
  ]
  loop
    if to_regclass('app.' || table_name) is not null then
      execute format('drop trigger if exists %I on app.%I', 'trg_' || table_name || '_community_broadcast', table_name);
      execute format(
        'create trigger %I after insert or update or delete on app.%I for each row execute function app.broadcast_community_change()',
        'trg_' || table_name || '_community_broadcast',
        table_name
      );
    end if;
  end loop;
end;
$$;

-- Retries after a lost HTTP response must not create duplicate active SOS
-- incidents or fan out the same emergency notification repeatedly.
with duplicated_active_alerts as (
  select
    id,
    row_number() over (
      partition by community_id, resident_user_id
      order by created_at desc, id desc
    ) as position
  from app.panic_alerts
  where status = 'active'
    and deleted_at is null
)
update app.panic_alerts alert
set status = 'resolved'
from duplicated_active_alerts duplicate
where alert.id = duplicate.id
  and duplicate.position > 1;

create unique index if not exists uq_panic_alert_active_resident
on app.panic_alerts (community_id, resident_user_id)
where status = 'active' and deleted_at is null;

commit;
