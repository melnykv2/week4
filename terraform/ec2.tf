
resource "aws_instance" "app" {
  count = 2

  ami = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  subnet_id = aws_subnet.private_subnet[count.index].id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<EOF
#!/bin/bash
systemctl enable --now amazon-ssm-agent
EOF

  tags = {
    Name = "app-${count.index + 1}"
  }
  depends_on = [aws_iam_role_policy_attachment.ssm_core]
}

resource "aws_instance" "db" {
  ami = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.db.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = false
  subnet_id = aws_subnet.private_subnet[0].id

  user_data = <<EOF
#!/bin/bash
systemctl enable --now amazon-ssm-agent
EOF

  tags = {
    Name = "db"
  }

  depends_on = [aws_iam_role_policy_attachment.ssm_core]
}
