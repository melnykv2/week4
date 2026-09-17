# webserver-setup

Installs Python 3.12, Git, and Nginx; creates the
`django` system user/group and the `/opt/django-app` directory; starts and
enables Nginx with the stock welcome page removed.

The actual reverse-proxy configuration (the provided `nginx.conf`) is applied
by the `deploy` role, since it depends on where the application is deployed 

## Variables consumed

| Variable | Defined in |
|---|---|
| `app_user`, `app_group`, `app_dir` | `group_vars/webservers.yml` |
| `webserver_packages` | this role's `defaults/main.yml` |
