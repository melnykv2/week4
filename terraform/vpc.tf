resource "aws_vpc" "django_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "django_vpc"
  }
}

resource "aws_internet_gateway" "django_igw" {
  vpc_id = aws_vpc.django_vpc.id
  tags = {
    Name = "django_igw"
  }
}

data "aws_availability_zones" "django_az" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.django_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.django_az.names[count.index]
  tags = {
    Name = "public_subnet${count.index}"
  }
}
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.django_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.django_az.names[count.index]
  tags = {
    Name = "private_subnet${count.index}"
  }
}

resource "aws_nat_gateway" "django_nat" {
  availability_mode = "regional"
  vpc_id            = aws_vpc.django_vpc.id
  tags = {
    Name = "django_nat"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.django_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.django_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.django_nat.id
  }
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
