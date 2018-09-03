provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "all" {}

module "cloudup_vpc" {
  source = "vpc"
}

resource "aws_launch_configuration" "new_cloudup" {
  image_id = "ami-de752aa6"
  instance_type = "p2.xlarge"
  security_groups = ["${aws_security_group.instance_sg.id}"]
  key_name = "${var.fellow_name}-IAM-keypair"
  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
				nohup busybox httpd -f -p "80" &
				yum update -y

                yum install -y mysql
                mysql --host "${aws_route53_record.db.name}" --port 3306 -u root -pcloudupusers -e "USE cloudupdb;
                CREATE TABLE IF NOT EXISTS users(id INT(11) AUTO_INCREMENT PRIMARY KEY, email VARCHAR(55),
                                                username VARCHAR(30), password VARCHAR(100), aws_access_key_id VARCHAR(100),
                                                aws_secret_access_key VARCHAR(100), register_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

				yum install -y docker
                service docker start
                usermod -a -G docker ec2-user
                curl -L https://github.com/docker/compose/releases/download/1.20.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
                chown root:docker /usr/local/bin/docker-compose

				distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
				curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | tee /etc/yum.repos.d/nvidia-docker.repo
				yum install -y nvidia-docker2-2.0.3-1.docker17.12.1.ce.amzn1
				pkill -SIGHUP dockerd

                cd /home/ec2-user
                yum install git
                git clone https://github.com/mw123/Cloud-Up.git
                chown -R ec2-user:ec2-user /home/ec2-user/Cloud-Up
                chmod -R 777 /home/ec2-user/Cloud-Up
                /usr/local/bin/docker-compose -f /home/ec2-user/Cloud-Up/docker-compose.yml up --build
              EOF

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "instance_sg" {
  name = "cloudup-server-sg"
  tags {
    Name = "cloudup-server-sg"
  }
  vpc_id = "${module.cloudup_vpc.vpc_id}"

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

resource "aws_autoscaling_group" "cloudup_asg" {
  launch_configuration = "${aws_launch_configuration.new_cloudup.id}"
  vpc_zone_identifier = ["${module.cloudup_vpc.public_subnet_id}"]

  min_size = 1
  max_size = 5

  load_balancers = ["${aws_elb.cloudup_elb.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "cloudup-asg-primary"
    propagate_at_launch = true
  }
}

resource "aws_elb" "cloudup_elb" {
  name = "cloudup-elb-primary"
  security_groups = ["${aws_security_group.elb_sg.id}"]
  subnets = ["${module.cloudup_vpc.public_subnet_id}"]

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
  name = "cloudup-elb-sg-primary"
  vpc_id = "${module.cloudup_vpc.vpc_id}"
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

resource "aws_db_instance" "cloudup_mysql" {
  allocated_storage = 100 # 100 GB of storage, gives us more IOPS than a lower number
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.small" # use micro if you want to use the free tier
  identifier = "cloudup-mysql"
  name = "cloudupdb"
  username = "root" # username
  password = "cloudupusers" # password
  db_subnet_group_name = "${module.cloudup_vpc.db_subnet_group}"
  multi_az = "true" # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]
  storage_type = "gp2"
  backup_retention_period = 30 # how long you’re going to keep your backups
  skip_final_snapshot = true

  tags {
    Name = "cloudupdb-instance"
  }
}

resource "aws_security_group" "db_sg" {
  name = "cloudup-db-sg"
  tags {
    Name = "cloudup-db-sg"
  }
  vpc_id = "${module.cloudup_vpc.vpc_id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.instance_sg.id}"]
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

resource "aws_route53_record" "db" {
  name = "db.cloud-up-insight.com"
  type = "CNAME"
  zone_id = "${var.route53_zone_id}"
  ttl = "300"
  records = ["${aws_db_instance.cloudup_mysql.address}"]
}






/*resource "aws_instance" "db_az0" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = "false"
  subnet_id = "${module.cloudup_vpc.db_subnet_ids[0]}"
  vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]
  key_name = "${var.fellow_name}-IAM-keypair"
  tags {
    Name = "db-az0"
  }
  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install -y mysql55-server
  service mysqld start
  /usr/bin/mysqladmin -u root password 'secret'
  mysql -u root -psecret -e "create user 'root'@'%' identified by 'secret';" mysql
  mysql -u root -psecret -e 'CREATE TABLE mytable (mycol varchar(255));' test
  mysql -u root -psecret -e "INSERT INTO mytable (mycol) values ('Cloud Up') ;" test
HEREDOC
}*/