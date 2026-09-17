resource "aws_vpc" "django_vpc" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  enable_dns_support = true

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

resource "aws_nat_gateway" "django_nat" {
  vpc_id = aws_vpc.django_vpc.id
  availability_mode = "regional"

  tags = {
    Name = "django_nat"
  }
}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = aws_vpc.django_vpc.id
  cidr_block = var.private_cidr[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "private_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id = aws_vpc.django_vpc.id
  cidr_block = var.public_cidr[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "public_subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.django_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.django_nat.id
  }

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.django_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}
