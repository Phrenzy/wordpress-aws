variable "aws_region" {}
variable "aws_profile" {}
variable "aws_access" {}
variable "aws_secret_key" {}
#variable "localip" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = map
}
variable "stackname"{}
variable "web_instance_type"{}
variable "web_ami"{}
variable "ec2_key_pair"{}
variable "ec2_storage"{}

variable "db_allocated_storage"{}
variable "db_engine"{}
variable "db_instance_class"{}
variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
