#
# Written for Terraform v0.12.24

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}





#-------- VPC --------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.stackname}_VPC"
  }
}

# Internet gateway

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.wp_vpc.id

  tags = {
    Name = "${var.stackname}_IGW"
  }
}
