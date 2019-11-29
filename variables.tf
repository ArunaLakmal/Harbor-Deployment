variable "aws_region" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = "map"
}
data "aws_availability_zones" "available" {}