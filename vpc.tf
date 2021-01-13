# SIMPLE VPC
# AWS Creds
provider "aws" {
  region  = "eu-west-2"
  profile = "logging"
}

# Variables
variable "env_name" {
  default = "WindowsApp"
}

variable "vpc_cidr" {
  default = "10.15.0.0/16"
}

variable "vm-count" {
  default = 2
}

variable "workspace_name" {
}

variable "workspace_team" {
}

# Get AZs
data "aws_availability_zones" "available" {}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "${var.env_name} VPC"
    Deploy = "vpc"
  }
}

# Create Internet gateway
resource "aws_internet_gateway" "vpc" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name   = "${var.env_name} Internet Gateway"
    Deploy = "vpc"
  }
}

# Create Public Subnets
resource "aws_subnet" "Public_subnet" {
  count             = var.vm-count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name   = "${var.env_name}  Public Subnet AZ${count.index + 1}"
    Deploy = "vpc"
  }
}

# Create Public Route Table for Internet Access
resource "aws_route_table" "public_vpc" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc.id
  }

  tags = {
    Name   = "${var.env_name} Public Route Table"
    Deploy = "vpc"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.vm-count
  subnet_id      = element(aws_subnet.Public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_vpc.id
}

# Create EIP for the App servers.
resource "aws_eip" "Servers" {
  count    = var.vm-count
  vpc      = true
  instance = element(aws_instance.server.*.id, count.index)
}

# Create userdata template
data "template_file" "userdata" {
  template = file("${path.module}/bootstrap.tpl")
}

# Create Instance 01
resource "aws_instance" "server" {
  count                       = var.vm-count
  ami                         = "ami-08d0b6a95e13d8252"
  instance_type               = "t2.micro"
  #user_data                   = "${data.template_file.userdata.rendered}"
  associate_public_ip_address = false

  tags = {
    Name = "${var.env_name}0${count.index +1}a"
  }

  key_name        = "LinuxAppKey"
  subnet_id       = element(aws_subnet.Public_subnet.*.id, count.index)
  security_groups = [aws_security_group.Server_SG.id]
}

# Create Security Group
resource "aws_security_group" "Server_SG" {
  name        = "${var.env_name}_Security_SG"
  description = "Used for access the instances"
  vpc_id      = aws_vpc.vpc.id

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Redirected Port

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
