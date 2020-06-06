#
# Written for Terraform v0.12.24

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


# --------  IAM  --------

resource "aws_iam_user" "iam_user" {
  name = var.stackname
  path = "/system/"
}


# --------  VPC  --------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.stackname}_VPC"
  }
}


# --------  Internet gateway  --------

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.wp_vpc.id

  tags = {
    Name = "${var.stackname}_IGW"
  }
}

############################################################ Route tables ####

resource "aws_route_table" "wp_public_rt" {
  vpc_id = aws_vpc.wp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_internet_gateway.id
  }

  tags = {
    Name = "${var.stackname}_public"
  }
}

##############################################################  Subnets  ####

resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.cidrs["public1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.stackname}_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.cidrs["public2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.stackname}_public2"
  }
}


resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.cidrs["rds1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.stackname}_rds1"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.cidrs["rds2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.stackname}_rds2"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.cidrs["rds3"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "${var.stackname}_rds3"
  }
}

#-------- Security groups --------

## Security group for EC2 instances

resource "aws_security_group" "wp_ec2_sg" {
  name        = "wp_ec2_sg"
  description = "used for EC2 instances"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    description = "HTTPS in"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP in"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # need to change to personal ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


## Security group for RDS instances

resource "aws_security_group" "wp_rds_sg" {
  name        = "wp_rds_sg"
  description = "used for RDS instances"
  vpc_id      = aws_vpc.wp_vpc.id

  # SQL S3_access

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#################################################################### EC2 ###

#resource "aws_instance" "web" {
#  instance_type = "t2.micro"
#  ami           = var.web_ami
#
#  key_name               = var.ec2_key_pair
#  subnet_id              = aws_subnet.wp_public1_subnet.id
#  security_groups        = [(aws_security_group.wp_ec2_sg.id)]
#
#
#  }
