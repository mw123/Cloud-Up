provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "all" {}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

resource "aws_launch_configuration" "new_michaniki" {
  image_id = "ami-de752aa6"
  instance_type = "p2.xlarge"
  security_groups = ["${aws_security_group.instance_sg.id}"]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "instance_sg" {
  name = "new-michaniki-instance"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "michaniki_asg" {
  launch_configuration = "${aws_launch_configuration.new_michaniki.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 1
  max_size = 3

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
    target = "HTTP:${var.server_port}/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
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
