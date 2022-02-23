resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.PROJECT}-${var.DEPLOYMENT}"
    Project = var.PROJECT
  }
}

resource "aws_subnet" "public_sn" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "${var.PROJECT}-${var.DEPLOYMENT}-public-sn"
    Project = var.PROJECT
  }
}                 

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.PROJECT}-${var.DEPLOYMENT}-igw"
    Project = var.PROJECT
  }
}

resource "aws_route_table" "main_public_rt" {
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
    }

    tags = {
      Name = "${var.PROJECT}-${var.DEPLOYMENT}-public-rt"
      Project = var.PROJECT
    }
}

resource "aws_route_table_association" "rt_sn_public" {
    subnet_id = aws_subnet.public_sn.id
    route_table_id = aws_route_table.main_public_rt.id
}