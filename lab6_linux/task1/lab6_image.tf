# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_security_group" "http" {
  name        = "HTTP Access"
  description = "Access to port 80"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "HTTP Access"
  }
}

resource "aws_instance" "webserver" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"
  subnet_id     = "${var.public_subnet_id}"
  security_groups = ["${aws_security_group.http.id}"]
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  user_data = "${file("UserData.txt")}"

  tags {
    Name = "Web Server"
  }
}

