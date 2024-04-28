variable "aws_region" {
  description = "The AWS region to deploy the resources to"
}

variable "aws_creds_file" {
  description = "The full path to the .aws/credentials file"
}

variable "aws_profile" {
  description = "The profile in the credentials file to use"
}

variable "aws_pem" {
  description = "The PEM file to use for SSH. This is outputted with the IP for convenience"
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [var.aws_creds_file]
  profile                  = var.aws_profile
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

data "aws_availability_zones" "all" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_vpc" "work-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"

  tags = {
    Name = "work-vpc"
  }
}

resource "aws_subnet" "work-subnet" {
  vpc_id                  = aws_vpc.work-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" #it makes this a public subnet
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "work-subnet"
  }
}

resource "aws_internet_gateway" "work-igw" {
  vpc_id = aws_vpc.work-vpc.id
  tags = {
    Name = "work-igw"
  }
}

resource "aws_route_table" "work-rtble" {
  vpc_id = aws_vpc.work-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.work-igw.id
  }

  tags = {
    Name = "work-rtble"
  }
}

resource "aws_route_table_association" "work-rta" {
  subnet_id      = aws_subnet.work-subnet.id
  route_table_id = aws_route_table.work-rtble.id
}
