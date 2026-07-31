begin;

alter table app.announcements add column if not exists link_url text null;
alter table app.announcements add constraint announcements_link_url_length check (link_url is null or length(link_url) <= 2048);

create index if not exists idx_user_notifications_unread
  on app.user_notifications (community_id, user_id, created_at desc)
  where deleted_at is null and is_read = false;

commit;
