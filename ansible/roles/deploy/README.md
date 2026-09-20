# deploy

Deploys the Django application: clones the code, installs dependencies, configures
the environment, runs database migrations and static-asset build steps, and starts
the app behind nginx.

## What it does (`tasks/main.yml`, in order)

1. **`packages.yml`** — installs `acl` (see Notes), creates the `django-user` system
   account, creates `/opt/django-app` owned by it, clones the app repo, creates a
   Python 3.12 virtualenv and installs `requirements.txt` plus `gunicorn` into it.
2. **`envs.yml`** — renders `templates/app.env.j2` to `{{ app_dir }}/.env` (mode
   `0600`, owned by `django-user` — it contains the DB password and Django secret key
   in plaintext, so it must not be world-readable).
3. **`migration.yml`** — runs `manage.py migrate` (once — see Notes on `run_once`),
   then `collectstatic` and `compress` (django-compressor's offline-mode build step;
   these run on *every* host, since they produce local files per instance, not shared
   database state).
4. **`run-server.yml`** — writes a systemd unit for the app (gunicorn, bound to
   `127.0.0.1:8000`), enables/starts it, and installs `files/nginx.conf` as the
   nginx site (removing the default site first) so nginx on port 80 proxies to it.

## Requirements

- Target OS: Debian/Ubuntu (uses `apt`, `systemd`)
- The app's `requirements.txt` does **not** include a WSGI server or the `libpq`
  runtime library — both are installed explicitly by this role/`webserver-setup`,
  since the app needs them but doesn't declare them as Python dependencies.

## Role variables

`defaults/main.yml`:

| Variable | Default | Purpose |
|---|---|---|
| `app_user` | `django-user` | System account that owns and runs the app |
| `app_dir` | `/opt/django-app` | App code + venv location |
| `venv_dir` | `{{ app_dir }}/venv` | Python virtualenv path |
| `app_service_name` | `django-app` | systemd unit name |
| `app_bind_host` / `app_bind_port` | `127.0.0.1` / `8000` | Where gunicorn listens; must match `files/nginx.conf`'s `proxy_pass` exactly, since that file is static (no templating) |

`values/main.yml` is intentionally empty — kept only because the assignment's
directory listing names it, but everything that would have gone here fit the
override-friendly `defaults/` test instead. (Note: `values/` is not a directory
Ansible auto-loads, unlike `vars/`/`defaults/` — if it's ever populated, it needs an
explicit `vars_files` entry in `deploy.yml`.)

**Expected from `group_vars/all.yml`** (shared with `postgres-setup`, since both
roles run on different hosts but must agree on the same database credentials):
`postgres_db_name`, `postgres_db_user`, `db_password`, `django_secret_key`.

**Expected from inventory `[webservers:vars]`**: `db_host` (the DB instance's private
IP) and `alb_dns_name`.

## Files & templates

- `templates/app.env.j2` — renders the app's `.env`. Sets `ALLOWED_HOSTS=*` — see
  Notes, this is deliberate, not an oversight.
- `files/nginx.conf` — static reverse-proxy config (80 → `127.0.0.1:8000`). Static,
  not a template, so it must be kept in sync by hand with `app_bind_host`/`app_bind_port`.

## Handlers

- `Restart app service` — fires when the systemd unit or `.env` changes
- `Reload Nginx` — fires when the nginx site config changes

## Notes / lessons learned building this role

- **`acl` package**: required on the target for the same reason as `postgres-setup`
  — tasks use `become_user: "{{ app_user }}"`, and privilege escalation to a
  non-root user needs `setfacl` to hand off temp files.
- **`libpq5`**: the app's Postgres driver (`psycopg` v3) has no pure-Python fallback
  without the system `libpq` shared library present — without it, migrations fail
  with `ImportError: no pq wrapper available`.
- **`run_once: true` on the migration task**: both app instances point at the same
  database. Without this, Ansible runs `migrate` on both hosts in parallel, and
  they race — one succeeds, the other fails with `DuplicateColumn` because the
  schema change already landed. `collectstatic`/`compress`, by contrast, must run
  on *every* host, since each instance needs its own local copy of the built assets.
- **`ALLOWED_HOSTS=*`**: the ALB's health checker connects to each instance's
  private IP directly (`target_type = "instance"`), sending a `Host` header that
  will never match a fixed hostname allow-list, and instance IPs aren't stable
  across replacement anyway. Network-level access is already restricted by security
  groups, so this is an acceptable trade-off here, not a default to copy blindly
  into a public-facing app without that context.
- **`collectstatic`/`compress` step**: without it, every page using `{% compress %}`
  (i.e. nearly the whole site) 500s with `OfflineGenerationError` — django-compressor
  is configured for offline mode, so bundling must happen at deploy time, not per-request.
- All `command` tasks that need `.env` values (`migrate`, `collectstatic`, `compress`)
  pass them via an explicit `environment:` block — this app does **not** auto-load
  `.env` (no `python-dotenv`/`django-environ` call in `manage.py`), so nothing reaches
  the process unless something injects it. Gunicorn gets it for free via the systemd
  unit's `EnvironmentFile=` directive instead.
