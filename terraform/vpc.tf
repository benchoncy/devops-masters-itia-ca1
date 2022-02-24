// Create VPC for deployment

locals {
  // Use as many availability zomes as availible up to a maxium of 3
  NUM_SUBNETS = min(length(data.aws_availability_zones.available.names), 3)
}

data "aws_availability_zones" "available" {
  state = "available"
}

// Create a single VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.PROJECT}-${var.ENVIORNMENT}-vpc"
  }
}

// Create a subnet for each availability zone
resource "aws_subnet" "public_sns" {
  count = local.NUM_SUBNETS
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.SUBNET_PREFIX_CIDR, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.PROJECT}-${var.ENVIORNMENT}-public-sn-${count.index}"
  }
}                 

// Make subnets public
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.PROJECT}-${var.ENVIORNMENT}-igw"
  }
}

resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.PROJECT}-${var.ENVIORNMENT}-public-rt"
  }
}

resource "aws_route_table_association" "rt_sn_public" {
    count = local.NUM_SUBNETS
    subnet_id = aws_subnet.public_sns[count.index].id
    route_table_id = aws_route_table.main_public_rt.id
}