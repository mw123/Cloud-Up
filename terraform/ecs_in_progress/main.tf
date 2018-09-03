/*
module "michaniki_master_cluster" {
  source = "./ecs-cluster"

  name = "training-server-cluster"
  size = 1
  instance_type = "p2.xlarge"
  vpc_id = "${module.michaniki_vpc.vpc_id}"
  subnet_ids = "${module.michaniki_vpc.public_subnet_ids}"
}

module "michaniki_master_service" {
  source = "./ecs-service"

  name = "master-service"
  ecs_cluster_id = "${module.michaniki_master_cluster.ecs_cluster_id}"
  image = "${var.}"

}

module "michaniki_vpc" {
  source = "./vpc"

  vpc_name = "michaniki-vpc"
}
*/

resource "aws_ecr_repository" "michaniki" {
  name = "michaniki-image"
}
