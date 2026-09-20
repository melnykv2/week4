# postgres-setup

Installs and configures PostgreSQL on the database host, creates the application's
database and user, and opens access to instances in the VPC's private address space.

## What it does

1. Installs `postgresql`, `postgresql-contrib`, `python3-psycopg2` (required by the
   `community.postgresql` Ansible modules used below), and `acl` (required for
   privilege escalation to the `postgres` system user — see Notes).
2. Sets `listen_addresses` in `postgresql.conf` so Postgres accepts connections on
   all interfaces (network-level access is already restricted by the security group,
   not by this setting).
3. Adds a rule to `pg_hba.conf` allowing password-authenticated connections from the
   VPC's CIDR range.
4. Creates the application database and user (via `community.postgresql.postgresql_db`
   / `postgresql_user`, not raw SQL, for idempotency).

## Requirements

- Collection: `community.postgresql`
- Target OS: Debian/Ubuntu (uses `apt`)

## Role variables

Defined in `defaults/main.yml` (safe to override):

| Variable | Default | Purpose |
|---|---|---|
| `postgres_listen_addresses` | `"*"` | Interfaces Postgres binds to |
| `postgres_allowed_cidr` | `10.0.0.0/16` | CIDR trusted in `pg_hba.conf` (matches the VPC CIDR) |

Defined in `vars/main.yml` (internal, not meant to be overridden):

| Variable | Value | Purpose |
|---|---|---|
| `postgresql_version` | `"14"` | PostgreSQL major version installed by Ubuntu 22.04/24.04's default apt repo |
| `postgres_config_dir` | `/etc/postgresql/{{ postgresql_version }}/main` | Location of `postgresql.conf`/`pg_hba.conf` |

**Expected from `group_vars/all.yml`** (not owned by this role, since the `deploy`
role — running on different hosts — needs the same values):

- `postgres_db_name`, `postgres_db_user` — the application's database/username
- `db_password` — looked up at runtime from AWS SSM Parameter Store (never stored in git)

## Handlers

- `Restart PostgreSQL` — full restart, needed for `listen_addresses` (only read at startup)
- `Reload PostgreSQL` — live reload, sufficient for `pg_hba.conf` changes

## Notes

- The `acl` package is required because tasks use `become_user: postgres` (a non-root
  account). Without `acl`/`setfacl` present, Ansible can't hand off the temporary
  module file to that user and privilege escalation fails.
- Intended to run against the `dbservers` inventory group, with `become: true` set at
  the play level (see `db.yml`).
