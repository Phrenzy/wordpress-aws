#
# Written for Terraform v0.14.3

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


# --------  IAM  --------

## Creates IAM account to place EC2 instance inside. Currently unused.
#resource "aws_iam_user" "iam_user" {
#  name = var.stackname
#  path = "/system/"
#}


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


# --------  Route Table  --------

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

# --------  Subnets  --------

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


# --------  RDS subnet group  --------

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name = "wp_rds_subnetgroup"

  subnet_ids = [aws_subnet.wp_rds1_subnet.id,
    aws_subnet.wp_rds2_subnet.id,
    aws_subnet.wp_rds3_subnet.id,
  ]


}


# -------- Route Table Associations --------

resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = aws_subnet.wp_public1_subnet.id
  route_table_id = aws_route_table.wp_public_rt.id
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = aws_subnet.wp_public2_subnet.id
  route_table_id = aws_route_table.wp_public_rt.id
}


# -------- Security groups --------

# --- EC2 ---

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

# --- RDS ---

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


# --------  EC2  --------

resource "aws_instance" "web" {
  instance_type = var.web_instance_type
  ami           = var.web_ami
  key_name               = var.ec2_key_pair
  subnet_id              = aws_subnet.wp_public1_subnet.id
  security_groups        = [(aws_security_group.wp_ec2_sg.id)]
  root_block_device {
    volume_size           = var.ec2_storage
    }
  tags = {
      Name = var.stackname
    }



    provisioner "local-exec" {
      command = <<EOD
  cat <<EOF > aws_hosts
  [web]
  ${aws_instance.web.public_ip}
  [web:vars]
  ansible_python_interpreter=/usr/bin/python3
  EOD
    }
    provisioner "local-exec" {
      command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.web.id} && ansible-playbook -i aws_hosts wordpress.yml"
    }
  }


# --------  RDS  --------

 resource "aws_db_instance" "wp_db" {
    allocated_storage           = var.db_allocated_storage
    allow_major_version_upgrade = false
    auto_minor_version_upgrade  = true
    backup_retention_period     = 7
    delete_automated_backups    = true
    engine                      = var.db_engine
    identifier                  = var.stackname
    instance_class              = var.db_instance_class
    max_allocated_storage       = 0
    name                        = var.dbname
    username                    = var.dbuser
    password                    = var.dbpassword
    db_subnet_group_name        = aws_db_subnet_group.wp_rds_subnetgroup.name
    vpc_security_group_ids      = [aws_security_group.wp_rds_sg.id]
    skip_final_snapshot         = true
  }
