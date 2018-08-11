provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "new_michaniki" {
  image_id = "ami-de752aa6"
  instance_type = "p2.xlarge"
  security_groups = ["${aws_security_group.instance_sg.id}"]
  key_name = "${var.fellow_name}-IAM-keypair"

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "80" &
                yum update -y
                yum install -y docker
                service docker start
                usermod -a -G docker ec2-user
                curl -L https://github.com/docker/compose/releases/download/1.20.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
                chown root:docker /usr/local/bin/docker-compose

                cd /home/ec2-user
                yum install git
                git clone https://github.com/InsightDataCommunity/Michaniki.git
                cd /home/ec2-user/Michaniki
                chown ec2-user:ec2-user /home/ec2-user/Michaniki/docker-compose.yml
                export AWS_ACCESS_KEY_ID="${var.AWS_ACCESS_KEY_ID}"
                export AWS_SECRET_ACCESS_KEY="${var.AWS_SECRET_ACCESS_KEY}"
                /usr/local/bin/docker-compose -f /home/ec2-user/Michaniki/docker-compose.yml up --build
              EOF

  /*provisioner "file" {
    source = "${var.project_home}/provision_files/init.sh}"
    destination = "/etc/init.sh"
    connection {
      type="ssh"
      user="ec2-user"
      private_key="${file("${var.HOME}/.ssh/${var.fellow_name}-IAM-keypair.pem")}"
    }
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /etc/init.sh"]
    connection {
      type="ssh"
      user="ec2-user"
      private_key="${file("${var.HOME}/.ssh/${var.fellow_name}-IAM-keypair.pem")}"
    }
  }*/

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "instance_sg" {
  name = "new-michaniki-instance"
  ingress {
    from_port = 3031
    to_port = 3031
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "michaniki_asg" {
  launch_configuration = "${aws_launch_configuration.new_michaniki.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 2
  max_size = 5

  load_balancers = ["${aws_elb.michaniki_elb.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "michaniki-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "michaniki_elb" {
  name = "michaniki-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 3031
    instance_protocol = "http"
  }
}
resource "aws_security_group" "elb_sg" {
  name = "michaniki-elb-sg"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_dns_name" {
  value = "${aws_elb.michaniki_elb.dns_name}"
}



/*
provider "docker" {
  host = "tcp://localhost:2376"

  registry_auth {
    address = "registry.hub.docker.com"
    username = "${var.DOCKERHUB_USER}"
    password = "${var.DOCKERHUB_PASSWD}"
  }
}

data "docker_registry_image" "michaniki_client" {
  name = "${var.DOCKERHUB_USER}/michaniki_michaniki_client"
}

resource "docker_image" "ubuntu" {
  name          = "${data.docker_registry_image.michaniki_client.name}"
  pull_triggers = ["${data.docker_registry_image.michaniki_client.sha256_digest}"]
}

resource "docker_container" "nginx" {
  image = "${docker_image.nginx.latest}"
  name  = "enginecks"
  ports {
    internal = 80
    external = 80
  }
}*/