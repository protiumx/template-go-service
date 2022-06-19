CREATE TABLE "users" (
  "id" uuid PRIMARY KEY,
  "user_name" text UNIQUE NOT NULL,
  "password_hash" bytea NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now() at time zone 'utc'),
  "updated_at" timestamptz NOT NULL DEFAULT (now() at time zone 'utc')
);

