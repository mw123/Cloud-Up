resource "aws_route_table" "cloudup_public_rt" {
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "cloudup-public-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cloudup_gw.id}"
  }
}

resource "aws_route_table_association" "api" {
  route_table_id = "${aws_route_table.cloudup_public_rt.id}"
  subnet_id = "${aws_subnet.api_subnet.id}"
}
/*
resource "aws_route_table" "cloudup_private_rt" {
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "cloudup-private-rt"
  }
  route {
    cidr_block = "${var.vpc_cidr}"
  }
}

resource "aws_route_table_association" "server" {
  route_table_id = "${aws_route_table.cloudup_private_rt.id}"
  subnet_id = "${aws_subnet.api_subnet.id}"
}
*/
resource "aws_route_table" "cloudup_private_rt_nat" {
  vpc_id = "${aws_vpc.cloudup_vpc.id}"
  tags {
    Name = "cloudup_private_rt_nat"
  }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
}

resource "aws_route_table_association" "db_az0" {
  route_table_id = "${aws_route_table.cloudup_private_rt_nat.id}"
  subnet_id = "${aws_subnet.db_subnet_az0.id}"
}

resource "aws_route_table_association" "db_az1" {
  route_table_id = "${aws_route_table.cloudup_private_rt_nat.id}"
  subnet_id = "${aws_subnet.db_subnet_az1.id}"
}
/*
resource "aws_route_table_association" "db_az2" {
  route_table_id = "${aws_route_table.cloudup_private_rt.id}"
  subnet_id = "${aws_subnet.db_subnet_az2.id}"
}
*/