provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "cloudup_vpc" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "cloudup-vpc"
  }

}

resource "aws_subnet" "api_subnet" {
  cidr_block = "10.0.0.32/27"
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "public-subnet"
  }
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
}

resource "aws_subnet" "db_subnet_az1" {
  cidr_block = "10.0.0.16/28"
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "db-subnet-az1"
  }
  availability_zone = "${data.aws_availability_zones.all.names[1]}"
}

resource "aws_subnet" "db_subnet_az0" {
  cidr_block = "10.0.0.0/28"
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "db-subnet-az0"
  }
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
}
/*
resource "aws_subnet" "db_subnet_az2" {
  cidr_block = "10.0.0.8/29"
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "db-subnet-az2"
  }
  availability_zone = "${data.aws_availability_zones.all.names[2]}"
}
*/
resource "aws_db_subnet_group" "rds_subnets" {
  name = "cloudup-rds-subnets"
  description = "RDS subnet group"
  subnet_ids = [
    "${aws_subnet.db_subnet_az0.id}",
    "${aws_subnet.db_subnet_az1.id}"]
    /*"${aws_subnet.db_subnet_az2.id}"]*/
}


/*
resource "aws_subnet" "server_subnet" {
  cidr_block = "10.0.0.16/28"
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "private-subnet"
  }
  availability_zone = "${data.aws_availability_zones.all.names[2]}"
}*/

/* 
Configuration to make a very simple sandbox VPC for a few instances
For more details and options on the AWS vpc module, visit: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.30.0
*/
/*module "single_public_subnet_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.30.0"

  name = "${var.vpc_name}-vpc"

  cidr = "10.0.0.0/26"
  azs = ["${data.aws_availability_zones.all.names}"]
  public_subnets = ["10.0.0.0/28"]
  private_subnets = ["10.0.0.0/28"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_s3_endpoint = true

  tags = {
    Owner = "${var.vpc_name}"
    Environment = "dev"
    Terraform = "true"
  }
}
}*/