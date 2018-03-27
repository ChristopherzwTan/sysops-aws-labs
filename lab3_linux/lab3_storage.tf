# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "sysops-lab3"
  acl    = "private"

  tags {
    Name        = "S3 Lab 3 Bucket"
  }
}

data "aws_iam_policy_document" "s3_policy_doc" {
  statement {
    sid = "VisualEditor0"

    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:HeadBucket",
      "s3:ListObjects"    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "VisualEditor1"

    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::sysops-lab3/*",
      "arn:aws:s3:::sysops-lab3"
    ]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "s3_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.s3_policy_doc.json}"
}

resource "aws_iam_role" "s3_role" {
  name = "S3BucketAccess"
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

resource "aws_iam_role_policy_attachment" "s3-attach" {
  #name       = "s3-policy-attachment"
  role      = "${aws_iam_role.s3_role.name}"
  policy_arn = "${aws_iam_policy.s3_policy.arn}"
}

resource "aws_iam_instance_profile" "role_profile" {
  name  = "s3_role_profile"
  role = "${aws_iam_role.s3_role.name}"
}


resource "aws_security_group" "ssh" {
  name        = "SSH Access"
  description = "Access via SSH"
  vpc_id      = "${var.vpc_id}"

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
    Name = "SSH Access"
  }
}

resource "aws_instance" "i" {
  ami           = "ami-d874e0a0"
  instance_type = "t2.micro"
  subnet_id     = "${var.subnet_id}"
  security_groups = ["${aws_security_group.ssh.id}"]
  key_name = "${var.default_key_name}"
  associate_public_ip_address = "true"
  iam_instance_profile = "${aws_iam_instance_profile.role_profile.id}" 
  user_data = "${file("update.sh")}"

  tags {
    Name = "Processor"
  }
}

