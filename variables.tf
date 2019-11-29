variable "aws_region" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = "map"
}
data "aws_availability_zones" "available" {}
variable "hbr_key_name" {}
variable "public_key_path" {}
variable "hbr_instance" {}
variable "hbr_ami" {}
