resource "aws_security_group" "ssm_security_group" {
  name        = "ssm_security_group"
  description = "Security group for SSM"
  vpc_id      = aws_vpc.django_vpc.id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id, aws_security_group.db_sg.id]
  }
  tags = {
    Name = "ssm_security_group"
  }
}

locals {
  ssm_interface_endpoints = {
    ssm         = "ssm"
    ssmmessages = "ssmmessages"
    ec2messages = "ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssm_vpc_endpoint" {
  for_each            = local.ssm_interface_endpoints
  vpc_id              = aws_vpc.django_vpc.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  subnet_ids          = aws_subnet.private_subnet[*].id
  security_group_ids  = [aws_security_group.ssm_security_group.id]
  private_dns_enabled = true
  tags = {
    Name = "ssm_vpc_endpoint-${each.value}"
  }
}

resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id            = aws_vpc.django_vpc.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_route_table.private_route_table.id]
  tags = {
    Name = "s3_vpc_endpoint"
  }
}

resource "aws_s3_bucket" "ssm_bucket" {
  bucket_prefix = "ansible-ssm-relay-"
  force_destroy = true
  tags = {
    Name = "ansible_ssm_relay"
  }
}
