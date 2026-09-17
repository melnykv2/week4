# deploy

Clones (or updates) the Django application from GitHub, installs its Python
dependencies into a virtualenv, writes `.env` from a template using the
current PostgreSQL connection details, runs migrations and `collectstatic`,
installs the provided `nginx.conf`, and runs the app under Gunicorn via a
systemd service.

Owns the Nginx *site* configuration (`files/nginx.conf`) even though
`webserver-setup` installs Nginx itself — the site config's paths (static
file directory, upstream port) are specific to *this* deployment, so it
belongs with the role that knows about the deployment, not the generic
server-bootstrap role. `webserver-setup` still satisfies "Nginx listens on
80" out of the box; this role's copy of `nginx.conf` is what makes it proxy
to Gunicorn instead of showing the default page.

## Variables consumed

See `values/main.yml` for the full contract and where each variable is
defined. In short: deployment layout comes from `group_vars/webservers.yml`,
database/secret values come from `group_vars/all/vars.yml` (secrets are
fetched from AWS SSM Parameter Store at run time, never stored in a file),
and repo/venv defaults live in this role's own `defaults/main.yml`.

## Idempotency

- `git` clone only happens once; updates use `update: true` afterwards.
- Restarting the systemd service is handled entirely by the `Restart
  application` handler, triggered only when the code, `.env`, or dependencies
  actually change — not on every run.
