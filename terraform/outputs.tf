output "region" {
  value = var.region
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "db_instance_id" {
  value = aws_instance.db.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/../ansible/inventory.tpl", {
    app_instance_ids        = aws_instance.app[*].id
    db_instance_id          = aws_instance.db.id
    db_private_ip           = aws_instance.db.private_ip
    region                  = var.region
    s3_bucket_name          = aws_s3_bucket.ssm_bucket.bucket
    db_password_parameter   = aws_ssm_parameter.db_password.name
    django_secret_parameter = aws_ssm_parameter.django_secret.name
    alb_dns_name            = aws_lb.alb.dns_name
  })
}
