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


data "aws_subnet_ids" "public" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "Public Subnet 1"
  }
}

resource "aws_instance" "i" {
  ami           = "ami-d874e0a0"
  instance_type = "t2.micro"
  subnet_id     = "${data.aws_subnet_ids.public.ids[0]}"
  security_groups = ["${aws_security_group.http.id}"]
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  user_data = "${file("UserData.txt")}"

  tags {
    Name = "Web Server"
  }
}

resource "aws_ami" "web_ami" {
  name = "WebServer"

  virtualization_type = "hvm"
  root_device_name = "/dev/xvda"

  ebs_block_device {
      device_name = "/dev/xvda"
      snapshot_id = "snap-xxxxxxxx"
      volume_size = 8
  }  
}

// ELB is classic load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  access_logs {
    bucket        = "foo"
    bucket_prefix = "bar"
    interval      = 60
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = ["${aws_instance.foo.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "foobar-terraform-elb"
  }
}
