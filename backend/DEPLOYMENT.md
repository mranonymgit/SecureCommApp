# SCA Backend Deployment

This backend is ready to run against a hosted PostgreSQL database in Supabase.
Once deployed, you do not need to run any local command to "open" the database.

## 1) Create the Supabase project

1. Create a new Supabase project.
2. Open the `Connect` dialog and select `Session pooler` for Render. Render is
   IPv4-only, while Supabase's direct database endpoint is IPv6 by default.
3. Copy the Session pooler string and change only its scheme to
   `postgresql+asyncpg://` for `DATABASE_URL`.
4. Keep `RLS` enabled for the tables in `sql/001_initial_schema.sql`.

## 2) Apply the database schema

Run every migration that has not been applied, in numerical order. They are
idempotent where practical; never re-run a migration that your release tracker
already marks as applied without reviewing it first.

```bash
python scripts/apply_migration.py sql/001_initial_schema.sql
python scripts/apply_migration.py sql/002_production_schema_alignment.sql
python scripts/apply_migration.py sql/003_initial_account_email_alignment.sql
python scripts/apply_migration.py sql/004_admin_management_features.sql
python scripts/apply_migration.py sql/005_announcement_links_and_sos_notifications.sql
python scripts/apply_migration.py sql/006_private_realtime_chat.sql
python scripts/apply_migration.py sql/007_community_realtime.sql
python scripts/apply_migration.py sql/008_storage_configuration.sql
```

If you use the Supabase SQL editor, paste the same files in that order.

Create the initial community and exactly two accounts with:

```bash
python scripts/bootstrap_accounts.py
```

It creates only one `admin` and one `resident`, hashes generated passwords with
bcrypt, and prints each temporary password only when the account is first created.

## 3) Configure backend secrets

Set these environment variables in your hosting provider:

- `DATABASE_URL` using Supabase's Session pooler URL on port `5432`, for
  example (copy the real host from `Connect`):

```bash
postgresql+asyncpg://postgres.<project-ref>:<url-encoded-password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

- `JWT_SECRET_KEY`
- `JWT_ALGORITHM=HS256`
- `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`
- `SUPABASE_JWT_SIGNING_KEY`, the private JWK or PEM of a backend-owned key
  imported into Supabase. It never reaches Flutter.
- `SUPABASE_JWT_ALGORITHM=ES256`
- `SUPABASE_JWT_KEY_ID`, the `kid` of the imported key.
- `SUPABASE_JWT_SECRET` only if the project still intentionally uses the
  legacy shared JWT secret; in that case use `HS256` and leave `kid` empty.
- `SUPABASE_REALTIME_TOKEN_EXPIRE_MINUTES=10`
- `ENCRYPTION_KEY`
- `SUPABASE_PROJECT_URL`
- `SUPABASE_SECRET_KEY` using a server-only `sb_secret_*` key. A legacy
  `SUPABASE_SERVICE_ROLE_KEY` is supported as a fallback. Never add either to
  Flutter.
- `SUPABASE_STORAGE_BUCKET=sca-media`
- `SUPABASE_STORAGE_SIGNED_URL_SECONDS=900`
- `GROQ_API_KEY`
- `GROQ_MODEL=llama-3.3-70b-versatile`
- `CORS_ORIGINS=https://your-flutter-web-domain.example` (comma-separated if
  there is more than one Web deployment; do not use `*` in production)
- `APP_ENV=production`

## 4) Deploy the API

Recommended runtime:

- Render
- Railway
- Fly.io
- Google Cloud Run

The container starts with:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## 5) Flutter configuration

Point the app to the hosted API:

```bash
flutter run \
  --dart-define=SCA_API_URL=https://securecommapp-backend.onrender.com \
  --dart-define=SCA_COMMUNITY_SLUG=sca
```

Enable private Supabase Realtime without exposing privileged credentials:

```bash
flutter run \
  --dart-define=SCA_API_URL=https://securecommapp-backend.onrender.com \
  --dart-define=SCA_COMMUNITY_SLUG=sca \
  --dart-define=SUPABASE_URL=https://csgftuemldlbycozeeea.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your-key
```

Use the same four `--dart-define` values for `flutter build web --release` and
`flutter build apk --release`. The publishable key is safe for the client; the
server secret and JWT signing key are not.

`006_private_realtime_chat.sql` configures private Broadcast channels for chat,
Presence, typing state and user notifications. `007_community_realtime.sql`
adds one private, minimal-payload channel per community. It does **not** need
`ALTER PUBLICATION supabase_realtime ADD TABLE ...`; that command is only for
Postgres Changes, which SCA intentionally does not use here.

`008_storage_configuration.sql` creates or hardens the private `sca-media`
bucket. Uploads go through FastAPI with the server key; Flutter receives only
short-lived signed URLs.

### Realtime signing key (recommended ES256 flow)

1. Install/login to Supabase CLI and generate the key locally:

```bash
supabase gen signing-key --algorithm ES256
```

2. Store the complete private JWK output in a password manager. In Supabase,
   open `Project Settings > JWT Keys`, add/import a standby key and paste that
   JWK.
3. Record its `kid`, rotate the imported key into use, and wait for the
   Dashboard operation to finish before testing.
4. In Render set the same private JWK as `SUPABASE_JWT_SIGNING_KEY`, its `kid`
   as `SUPABASE_JWT_KEY_ID`, and `SUPABASE_JWT_ALGORITHM=ES256`.
5. Flutter receives only the short-lived `realtime_token` returned by FastAPI
   and the `sb_publishable_*` key. Never place the private JWK or
   `sb_secret_*` key in a Flutter build.

If you are using Firebase Auth on the client later, keep the backend JWT flow as the
API authorization layer and exchange the Firebase session on the app side for a
backend-issued token only when you are ready to unify auth. The current backend is
already prepared to validate JWTs from the SCA API.

## 6) Security notes

- Every business table includes `deleted_at`, `created_at`, and `updated_at`.
- Sensitive operations are protected by JWT. The public recovery endpoint only
  creates a generic administrator-approval request; it never changes a password
  directly and does not disclose whether an account exists.
- RLS policies must remain enabled in Supabase.
- Foreign keys are restrictive on critical tables.
- Audit triggers write to `app.audit_log`.
- Use app-layer encryption or `pgcrypto` for sensitive fields.
- Cached local data and mock layers are removed from the user panel flow.
- Groq is configured only through `GROQ_API_KEY`; do not hardcode secrets in source.

## 7) Suggested production flow

1. Apply the pending SQL migrations in Supabase SQL Editor.
2. Create the publishable/server API keys and the Realtime signing key.
3. Bootstrap the first community, administrator, and resident only if they do
   not already exist.
4. Add every environment variable to Render and deploy the current commit.
5. Build Flutter with the hosted API, Supabase URL and publishable key.
6. Verify login, residents, reports, chats, reactions, notifications and SOS
   against the hosted database on two simultaneous sessions.
