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
    Name = "wp_vpc"
  }
}
