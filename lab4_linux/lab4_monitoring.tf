# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

data "aws_iam_policy_document" "cw_policy_doc" {
  statement {

    effect = "Allow"

    actions = [
      "autoscaling:Describe*",
      "cloudwatch:*",
      "logs:*",
      "sns:*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "cw_policy" {
  name   = "EC2WebServerAccess"
  path   = "/"
  policy = "${data.aws_iam_policy_document.cw_policy_doc.json}"
}

resource "aws_iam_role" "ec2_web_server_role" {
  name = "WebServerCloudWatch"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cw-attach" {
  role      = "${aws_iam_role.ec2_web_server_role.name}"
  policy_arn = "${aws_iam_policy.cw_policy.arn}"
}

resource "aws_iam_instance_profile" "role_profile" {
  name  = "cw_role_profile"
  role = "${aws_iam_role.ec2_web_server_role.name}"
}


resource "aws_security_group" "http_ssh" {
  name        = "HTTP and SSH Access"
  description = "Access to port 80 and SSH"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "SSH Access"
  }
}

resource "aws_instance" "i" {
  ami           = "ami-d874e0a0"
  instance_type = "t2.micro"
  subnet_id     = "${var.subnet_id}"
  security_groups = ["${aws_security_group.http_ssh.id}"]
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  iam_instance_profile = "${aws_iam_instance_profile.role_profile.id}" 
  user_data = "${file("webserver.sh")}"

  tags {
    Name = "Web Server"
  }
}

