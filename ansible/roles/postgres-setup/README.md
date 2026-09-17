# postgres-setup

Installs PostgreSQL 15, initializes the data directory,
configures it to accept password-authenticated connections from the two
application servers only, and creates the application database, role, and schema grants.

## Variables consumed

| Variable            | Defined in                          |
|---------------------|--------------------------------------|
| `postgres_db`       | `group_vars/all/vars.yml`            |
| `postgres_user`     | `group_vars/all/vars.yml`            |
| `postgres_password` | `group_vars/all/vars.yml`, resolved via an `amazon.aws.ssm_parameter` lookup against the SecureString parameter Terraform creates in `secrets.tf` |
| `postgres_packages`, `postgres_service_name`, `postgres_data_dir`, `postgres_listen_addresses` | this role's `defaults/main.yml` |

