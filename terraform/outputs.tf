output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "db_instance_id" {
  value = aws_instance.db.id
}

output "db_private_ip" {
  value = aws_instance.db.private_ip
}
