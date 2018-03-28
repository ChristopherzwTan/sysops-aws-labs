variable "access_key" {}

variable "secret_key" {}

variable "aws_region" {}

variable "vpc_id" {
    default = ""
}

variable "public_subnet_id" {
    default = "
}

variable "private_subnet_id" {
    default = ""
}

variable "default_key_name" {}

variable "ami_id" {}
