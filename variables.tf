variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = "map"
}
variable "hbr_key_name" {}
variable "public_key_path" {}
variable "hbr_instance" {}
variable "hbr_ami" {}
