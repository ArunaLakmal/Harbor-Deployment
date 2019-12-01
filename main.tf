provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#---- VPC ----

resource "aws_vpc" "hbr_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "hbr_vpc"
  }
}

#---- IGW ----
resource "aws_internet_gateway" "hbr_igw" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  tags = {
    Name = "hbr_igw"
  }
}
#---- NAT GW ----

resource "aws_eip" "hbr_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.hbr_igw"]

  tags = {
    Name = "hbr_nat_gw"
  }
}

resource "aws_nat_gateway" "hbr_nat_gw" {
  allocation_id = "${aws_eip.hbr_eip.id}"
  subnet_id     = "${aws_subnet.hbr_public1_subnet.id}"
  depends_on    = ["aws_internet_gateway.hbr_igw"]

  tags = {
    Name = "hbr_nat_gateway"
  }
}

#---- Public RT ----
resource "aws_route_table" "hbr_pub_rt" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.hbr_igw.id}"
  }
  tags = {
    Name = "hbr_pub_rt"
  }
}

#---- Private RT ----
resource "aws_route_table" "hbr_pvt_rt" {
  vpc_id = "${aws_vpc.hbr_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.hbr_nat_gw.id}"
  }

  tags = {
    Name = "hbr_pvt_rt"
  }
}

#---- Subnets ----

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "hbr_public1_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "hbr_public1"
  }
}
resource "aws_subnet" "hbr_public2_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "hbr_public2"
  }
}
resource "aws_subnet" "hbr_private1_subnet" {
  vpc_id                  = "${aws_vpc.hbr_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "hbr_private1"
  }

}

#---- Route Table Associations ----
resource "aws_route_table_association" "hbr_public1_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_public1_subnet.id}"
  route_table_id = "${aws_route_table.hbr_pub_rt.id}"
}
resource "aws_route_table_association" "hbr_public2_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_public2_subnet.id}"
  route_table_id = "${aws_route_table.hbr_pub_rt.id}"
}
resource "aws_route_table_association" "hbr_private1_rt_assoc" {
  subnet_id      = "${aws_subnet.hbr_private1_subnet.id}"
  route_table_id = "${aws_route_table.hbr_pvt_rt.id}"
}

#---- Security Group ----
resource "aws_security_group" "hbr_public_sg" {
  name        = "hbr_public_security_group"
  description = "harbor public security group"
  vpc_id      = "${aws_vpc.hbr_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "hbr_private_sg" {
  name        = "hbr_private_security_group"
  description = "habor private group"
  vpc_id      = "${aws_vpc.hbr_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#---- Key Pair ----
resource "aws_key_pair" "hbr_key" {
  key_name   = "${var.hbr_key_name}"
  public_key = "${file(var.public_key_path)}"
}
#---- EC2 Instance -----
resource "aws_instance" "hbr_instance" {
  instance_type = "${var.hbr_instance}"
  ami           = "${var.hbr_ami}"

  tags = {
    Name = "hbr_registry"
  }

  key_name               = "${aws_key_pair.hbr_key.id}"
  vpc_security_group_ids = ["${aws_security_group.hbr_public_sg.id}"]
  subnet_id              = "${aws_subnet.hbr_public1_subnet.id}"

  provisioner "local-exec" {
    command = <<EOD
    cat <<EOF > harbor_hosts
  [harborhosts]
  ${aws_instance.hbr_instance.public_ip}
  EOF
  EOD
  }
  provisioner "local-exec" {
    command = "sudo sed -i '1ihostname: ${aws_instance.hbr_instance.public_ip}' harbor.yml"
  }
}

resource "null_resource" "docker_config" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.hbr_instance.id} --profile superhero && ansible-playbook -i harbor_hosts ansible-docker-deploy.yaml"
  }
}

resource "null_resource" "hbr_config" {
  provisioner "local-exec" {
    command = "ansible-playbook -i harbor_hosts ansible-docker-deploy.yaml"
  }
}