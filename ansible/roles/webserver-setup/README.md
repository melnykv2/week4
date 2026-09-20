# webserver-setup

Prepares an application server with the generic software it needs before any
app-specific deployment happens: Python and nginx.

## What it does

1. Installs `python3.12`, `python3.12-dev`, `python3.12-venv` (pinned to 3.12, the
   version this project's Django app requires) and `python3-pip`.
2. Installs `nginx` and ensures the service is started and enabled on boot.

## What it deliberately does *not* do

This role only gets nginx running with its default configuration — it does not write
any site-specific reverse-proxy config. The actual config that proxies port 80 to the
Django app (port 8000) lives in the `deploy` role instead (`deploy/files/nginx.conf`),
since that's the role that actually knows what it's fronting. This role has no
`templates/`/`files/` directory for exactly that reason.

## Requirements

- Target OS: Debian/Ubuntu (uses `apt`)

## Role variables

None. Every package installed here is a fixed requirement of this project (a specific
Python version the app needs, and the choice to use nginx) rather than something a
caller would reasonably want to override — so `defaults/main.yml` and `vars/main.yml`
are intentionally empty.

## Notes

- Intended to run against the `webservers` inventory group (see `webservers.yml`).
- Run this once per instance before `deploy.yml` — it's idempotent, so re-running it
  is harmless, but it doesn't need to run on every deploy.
