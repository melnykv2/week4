resource "random_password" "db" {
  length  = 24
  special = false
}

resource "random_password" "django_secret" {
  length  = 50
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/django-app/db-password"
  type  = "SecureString"
  value = random_password.db.result
}

resource "aws_ssm_parameter" "django_secret" {
  name  = "/django-app/django-secret-key"
  type  = "SecureString"
  value = random_password.django_secret.result
}
