resource "aws_vpc" "dcjewelry_vpc" {
  cidr_block           = var.config.cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "DCJewelry VPC"
  }
}

resource "aws_internet_gateway" "dcjewelry_igw" {
  vpc_id = aws_vpc.dcjewelry_vpc.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.dcjewelry_vpc.id
  cidr_block        = var.config.public_subnet_ips[0]
  availability_zone = var.config.availability_zones[0]
  tags = {
    Name = "DCJewelry Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.dcjewelry_vpc.id
  cidr_block        = var.config.public_subnet_ips[1]
  availability_zone = var.config.availability_zones[1]
  tags = {
    Name = "DCJewelry Public Subnet 2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.dcjewelry_vpc.id
  cidr_block        = var.config.private_subnet_ips[0]
  availability_zone = var.config.availability_zones[0]
  tags = {
    Name = "DCJewelry Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.dcjewelry_vpc.id
  cidr_block        = var.config.private_subnet_ips[1]
  availability_zone = var.config.availability_zones[1]
  tags = {
    Name = "DCJewelry Private Subnet 2"
  }
}

resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.dcjewelry_vpc.id
  tags = {
    Name = "DCJewelry Public RTB"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dcjewelry_igw.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.dcjewelry_vpc.id
  tags = {
    Name = "DCJewelry Private RTB"
  }
}
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
