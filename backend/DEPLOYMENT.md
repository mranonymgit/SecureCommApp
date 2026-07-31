# SCA Backend Deployment

This backend is ready to run against a hosted PostgreSQL database in Supabase.
Once deployed, you do not need to run any local command to "open" the database.

## 1) Create the Supabase project

1. Create a new Supabase project.
2. Copy the PostgreSQL connection string from `Project Settings > Database`.
3. Use the direct string in your backend as `DATABASE_URL`.
4. Keep `RLS` enabled for the tables in `sql/001_initial_schema.sql`.

## 2) Apply the database schema

For a new project, run both migrations in order. For the existing project, run
only `002_production_schema_alignment.sql` after confirming `001` was already applied.

```bash
python scripts/apply_migration.py sql/001_initial_schema.sql
python scripts/apply_migration.py sql/002_production_schema_alignment.sql
python scripts/apply_migration.py sql/003_initial_account_email_alignment.sql
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

- `DATABASE_URL` using the Supabase PostgreSQL URL, for example:

```bash
postgresql+asyncpg://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres
```

- `JWT_SECRET_KEY`
- `JWT_ALGORITHM=HS256`
- `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`
- `ENCRYPTION_KEY`
- `SUPABASE_PROJECT_URL`
- `SUPABASE_ANON_KEY`
- `GROQ_API_KEY`
- `GROQ_MODEL=llama-3.3-70b-versatile`
- `APP_ENV=production`

## 4) Deploy the API

Recommended runtime:

- Render
- Railway
- Fly.io
- Google Cloud Run

The container starts with:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## 5) Flutter configuration

Point the app to the hosted API:

```bash
flutter run --dart-define=SCA_API_URL=https://your-api-domain.com
```

Optionally define the community slug used by the login flow:

```bash
flutter run --dart-define=SCA_COMMUNITY_SLUG=sca
```

If you are using Firebase Auth on the client later, keep the backend JWT flow as the
API authorization layer and exchange the Firebase session on the app side for a
backend-issued token only when you are ready to unify auth. The current backend is
already prepared to validate JWTs from the SCA API.

## 6) Security notes

- Every business table includes `deleted_at`, `created_at`, and `updated_at`.
- Sensitive operations are protected by JWT. Password changes require the current JWT;
  an unauthenticated password-reset endpoint is intentionally not exposed.
- RLS policies must remain enabled in Supabase.
- Foreign keys are restrictive on critical tables.
- Audit triggers write to `app.audit_log`.
- Use app-layer encryption or `pgcrypto` for sensitive fields.
- Cached local data and mock layers are removed from the user panel flow.
- Groq is configured only through `GROQ_API_KEY`; do not hardcode secrets in source.

## 7) Suggested production flow

1. Deploy the backend container.
2. Run the SQL schema in Supabase.
3. Bootstrap the first community, administrator, and resident.
4. Configure the Flutter app to point to the deployed API.
5. Verify login, residents, reports, chats, and alerts against the hosted database.
