variable "aws_region" {}
variable "aws_profile" {}
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
variable "db_allocated_storage"{}
variable "db_engine"{}
variable "db_engine_version"{}
variable "db_instance_class"{}
variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
