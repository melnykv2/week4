data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profile.name
  tags = {
    Name = "app-${count.index + 1}"
  }
}

resource "aws_instance" "db" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet[1].id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profile.name
  tags = {
    Name = "db"
  }
}
