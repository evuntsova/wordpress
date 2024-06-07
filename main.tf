terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.52.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wordpress_igw"
  }
}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.main.id

  # since this is exactly the route AWS will create, the route will be adopted
  route {
    cidr_block = "10.1.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "wordpess-rt"
  }
}

resource "aws_subnet" "pub-sub-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/18"

  tags = {
    Name = "pub-sub-1"
  }
}

resource "aws_subnet" "pub-sub-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.64.0/18"

  tags = {
    Name = "pub-sub-2"
  }
}

resource "aws_subnet" "pub-sub-3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.128.0/18"

  tags = {
    Name = "pub-sub-3"
  }
}

resource "aws_subnet" "pub-sub-4" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.192.0/19"

  tags = {
    Name = "pub-sub-4"
  }
}

resource "aws_subnet" "pub-sub-5" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/18"

  tags = {
    Name = "pub-sub-5"
  }
}

resource "aws_subnet" "pub-sub-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/18"

  tags = {
    Name = "pub-sub-1"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.gw.id
}

output "route_table_id" {
  value = aws_route_table.test.id
}