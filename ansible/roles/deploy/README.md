# deploy

Clones the Django application from GitHub, installs its Python
dependencies into a virtualenv, writes `.env` from a template using the
current PostgreSQL connection details, runs migrations and `collectstatic`,
installs the provided `nginx.conf`, and runs the app under Gunicorn via a
systemd service.

Owns the Nginx configuration (`files/nginx.conf`) 

## Variables consumed

See `values/main.yml` for the full contract and where each variable is
defined. In short: deployment layout comes from `group_vars/webservers.yml`,
database/secret values come from `group_vars/all/vars.yml` (secrets are
fetched from AWS SSM Parameter Store at run time),
and repo/venv defaults live in this role's own `defaults/main.yml`.

