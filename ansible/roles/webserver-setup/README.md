# webserver-setup

Prepares an application server with the generic software it needs before any
app-specific deployment happens: Python and nginx.

## What it does

1. Installs `python3.12`, `python3.12-dev`, `python3.12-venv` (pinned to 3.12, the
   version this project's Django app requires) and `python3-pip`.
2. Installs `nginx` and ensures the service is started and enabled on boot.

## Role variables

None. Every package installed here is a fixed requirement of this project (a specific
Python version the app needs, and the choice to use nginx) rather than something a
caller would reasonably want to override — so `defaults/main.yml` and `vars/main.yml`
are intentionally empty.
