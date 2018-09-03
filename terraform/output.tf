output "elb_dns_name" {
  value = "${aws_elb.cloudup_elb.dns_name}"
}