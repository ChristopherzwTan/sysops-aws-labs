# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.50.0.0/16"
  instance_tenancy = "default"

  tags {
    Name = "Lab VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.50.0.0/24"

  tags {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.50.1.0/24"

  tags {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Public Subnet Gateway"
  }
}

resource "aws_route_table" "pub_r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.pub_r.id}"
}

resource "aws_route_table" "pri_r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.NAT_server.id}"
  }

  tags {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "pri_a" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.pri_r.id}"
}

resource "aws_security_group" "NAT" {
  name        = "NAT Security Group"
  description = "Security for the NAT server instance"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.50.1.0/24"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "NAT Security Group"
  }
}

resource "aws_instance" "NAT_server" {
  ami           = "ami-d874e0a0"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
  security_groups = ["${aws_security_group.NAT.id}"]
  source_dest_check = "false"
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  user_data = "${file("NAT_init.sh")}"

  tags {
    Name = "NAT Server"
  }
}

resource "aws_security_group" "Bastion" {
  name        = "Bastion Security Group"
  description = "Security for the bastion server instance"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "Bastion Security Group"
  }
}

resource "aws_instance" "Bastion_server" {
  ami           = "ami-d874e0a0"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
  security_groups = ["${aws_security_group.Bastion.id}"]
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  user_data = "${file("update.sh")}"

  tags {
    Name = "Bastion Host"
  }
}
