# Django Healthchecks — AWS Deployment

Deploys a fork of [healthchecks](https://github.com/healthchecks/healthchecks) (a
Django cron-job monitoring app) onto AWS, using Terraform for infrastructure and
Ansible for configuration/deployment.

## Architecture

```
Internet
   |
Internet Gateway
   |
Public subnets (2 AZs) ---- ALB (:80)
                               |
                          Target Group
                               |
              +----------------+----------------+
              |                                  |
   Private subnet (AZ-a)              Private subnet (AZ-b)
   App instance 1 (nginx -> gunicorn)  App instance 2 + PostgreSQL
```

- VPC with public + private subnets across 2 AZs; a single Regional NAT Gateway
  provides outbound internet access for private instances.
- All 3 EC2 instances (2 app servers, 1 PostgreSQL server) sit in private subnets
  with no public IPs. They're managed exclusively via **AWS Systems Manager** —
  no SSH, no bastion host.
- VPC Interface Endpoints for SSM (`ssm`, `ssmmessages`, `ec2messages`) plus an S3
  Gateway Endpoint mean SSM connectivity doesn't depend on the NAT Gateway.
- Secrets (DB password, Django secret key) are generated randomly by Terraform
  (`random_password`) and stored in SSM Parameter Store as `SecureString` — never
  committed to git, never hardcoded. Ansible resolves them at runtime via the
  `amazon.aws.ssm_parameter` lookup.
- Terraform generates the Ansible inventory (`ansible/inventory.ini`) directly from
  its own state, so instance IDs, the DB's private IP, the ALB's DNS name, and the
  SSM relay bucket name are always in sync with the real infrastructure.

## Repo layout

- `terraform/` — all infrastructure (VPC, security groups, IAM, SSM endpoints, EC2,
  ALB, secrets). See inline file comments; each `.tf` file is scoped to one concern.
- `ansible/` — configuration and app deployment. See `ansible/README.md` for how to
  run it, and each role's own `README.md` for what it does specifically.

## Deploying from scratch

```
cd terraform
terraform init
terraform plan      # review what will be created
terraform apply     # provisions everything; also writes ansible/inventory.ini

cd ../ansible
ansible-playbook db.yml          # configures PostgreSQL
ansible-playbook webservers.yml  # installs Python/nginx on app servers
ansible-playbook deploy.yml      # clones, configures, and starts the Django app
```

Verify with:
```
aws ssm describe-instance-information   # confirms all 3 instances are SSM-managed
curl -I http://<alb-dns-name>/          # confirms the app is actually serving traffic
```
