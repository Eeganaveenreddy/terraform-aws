# Main VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "terra_vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "terra-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  # subnet_id     = aws_subnet.public[0].id # Place NAT in Public Subnet
  subnet_id = aws_subnet.public_subnet[0].id
  tags = {
    Name = "terra-ngw"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.terra_vpc.id
  count = var.public_subnet_count
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1 + count.index)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Terra-Public-Subnet-${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.terra_vpc.id
  count = var.private_subnet_count
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 100 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Terra-Private-Subnet-${count.index + 1}"
    Type = "Private"
  }
}

