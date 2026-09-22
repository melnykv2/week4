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

## Handlers

- `Restart app service` — fires when the systemd unit or `.env` changes
- `Reload Nginx` — fires when the nginx site config changes
