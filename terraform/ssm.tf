locals {
  ssm_interface_endpoints = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = toset(local.ssm_interface_endpoints)
  vpc_id              = aws_vpc.django_vpc.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags = {
    Name = "vpc_endpoint-${each.value}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.django_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]
  tags = {
    Name = "vpc_endpoint-s3"
  }
}

resource "aws_s3_bucket" "ssm_bucket" {
  bucket_prefix = "ansible-ssm-relay-"
  force_destroy = true

  tags = {
    Name = "ansible-ssm-relay"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = <<EOF
[webservers]
%{ for idx, inst in aws_instance.app ~}
app-${idx + 1} ansible_host=${inst.id}
%{ endfor ~}

[db]
db-1 ansible_host=${aws_instance.db.id}

[webservers:vars]
ansible_connection=aws_ssm
ansible_aws_ssm_bucket_name=${aws_s3_bucket.ssm_bucket.bucket}
ansible_aws_ssm_region=${var.region}
ansible_python_interpreter=/usr/bin/python3
db_private_ip=${aws_instance.db.private_ip}
db_password_parameter=${aws_ssm_parameter.db_password.name}
django_secret_parameter=${aws_ssm_parameter.django_secret.name}
alb_dns_name=${aws_lb.alb.dns_name}

[db:vars]
ansible_connection=aws_ssm
ansible_aws_ssm_bucket_name=${aws_s3_bucket.ssm_bucket.bucket}
ansible_aws_ssm_region=${var.region}
ansible_python_interpreter=/usr/bin/python3
db_password_parameter=${aws_ssm_parameter.db_password.name}
EOF
}
