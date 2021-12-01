variable "AWS_REGION" {
  description = "AWS region.  Example: us-east-2"
}

variable "DEPLOYMENT_NAME" {
  description = "Name of deployment - used for the cluster name.  Example: rotate"
}

variable "VOTE_URL" {
  description = "Vote app url"
}

variable "RESULT_URL" {
  description = "Result app url"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
  required_version = "> 0.14"
}

provider "aws" {
  region = var.AWS_REGION
}

locals {
  instance_name = "ec2-traffic-${var.DEPLOYMENT_NAME}"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "traffic" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = local.instance_name
  }

  user_data = "${templatefile(
                  "../../scripts/loadgen-vm-setup-script.sh",
                  {
                    "VOTE_URL"=var.VOTE_URL,
                   "RESULT_URL"=var.RESULT_URL
                  }
                )}"
}