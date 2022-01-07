variable "AWS_REGION" {
  description = "AWS region.  Example: us-east-2"
}

terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "1.0.1"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

data "http" "lw_install_script" {
  url = var.lacework_install_script
}

provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}

resource "aws_key_pair" "jenkins-server-key" {
  key_name   = "jenkins-server-key"
  public_key = tls_private_key.keypair.public_key_openssh
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

resource "aws_instance" "jenkins-server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.ingress-ssh-from-all.id, aws_security_group.ingress-port-8080-from-alb.id]

  key_name   = "jenkins-server-key"
  depends_on = [aws_key_pair.jenkins-server-key, aws_security_group.ingress-ssh-from-all]
}

resource "aws_alb" "jenkins_alb" {
  name            = "jenkins-alb"
  subnets         = [aws_subnet.subnet.id, aws_subnet.subnet1.id]
  security_groups = [aws_security_group.ingress-port-8080-to-world.id]
  internal        = false
}

resource "aws_alb_listener" "jenkins_alb_listener" {
  load_balancer_arn = aws_alb.jenkins_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.jenkins_alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group" "jenkins_alb_target_group" {
  name     = "jenkins-alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/login"
    port                = 8080
  }
}

resource "aws_alb_target_group_attachment" "svc_physical_external" {
  target_group_arn = aws_alb_target_group.jenkins_alb_target_group.arn
  target_id        = aws_instance.jenkins-server.id
  port             = 8080
}

data "archive_file" "docker_compose_bundle" {
  type        = "zip"
  source_dir  = "${path.module}/files/jenkins_docker"
  output_path = "${path.module}/files/jenkins_docker.zip"
}

data "archive_file" "docker_compose_launch" {
  type        = "zip"
  output_path = "${path.module}/files/docker_compose_launch.zip"

  source {
    content = sensitive(templatefile("${path.module}/files/jenkins_up.sh.tpl", {
      dockerhub_access_token = var.dockerhub_access_token
      dockerhub_access_user  = var.dockerhub_access_user
      jenkins_admin          = var.jenkins_admin
      jenkins_admin_password = var.jenkins_admin_password
      lw_access_account      = var.lw_access_account
      lw_access_token        = var.lw_access_token
      k8s_build_robot_token  = var.k8s_build_robot_token
      jenkins_url            = "http://${aws_instance.jenkins-server.private_dns}:8080"
      jenkins_auth           = "${var.jenkins_admin}:${var.jenkins_admin_password}"
      k8s_cluster_name       = data.terraform_remote_state.eks.outputs.cluster_arn
      k8s_context_name       = data.terraform_remote_state.eks.outputs.cluster_arn
      k8s_server_url         = data.terraform_remote_state.eks.outputs.cluster_endpoint
      server                 = aws_instance.jenkins-server.private_ip
      instance               = "server"
    }))
    filename = "jenkins_up.sh"
  }

  source {
    content = templatefile("${path.module}/files/jenkins_create_job.sh.tpl", {
      jenkins_admin          = var.jenkins_admin
      jenkins_admin_password = var.jenkins_admin_password
    })
    filename = "jenkins_create_job.sh"
  }
}

resource "ssh_resource" "server_setup" {
  host        = aws_instance.jenkins-server.public_ip
  host_user   = "ubuntu"
  user        = "ubuntu"
  private_key = tls_private_key.keypair.private_key_pem

  file {
    destination = "/home/ubuntu/setup.sh"
    content     = file("${path.module}/files/setup.sh")
    permissions = "0700"
  }

  file {
    destination = "/home/ubuntu/setup_pkg.sh"
    content     = file("${path.module}/files/setup_pkg.sh")
    permissions = "0700"
  }

  file {
    destination = "/home/ubuntu/docker_compose_launch.zip"
    source      = data.archive_file.docker_compose_launch.output_path
    permissions = "0660"
  }

  file {
    destination = "/home/ubuntu/docker_compose_bundle.zip"
    source      = data.archive_file.docker_compose_bundle.output_path
    permissions = "0660"
  }

  commands = [
    "bash -x ./setup_pkg.sh",
    "unzip -o docker_compose_bundle.zip",
    "unzip -o docker_compose_launch.zip",
    "bash -x ./setup.sh"
  ]

  depends_on = [
    data.archive_file.docker_compose_bundle,
    data.archive_file.docker_compose_launch,
  ]
}

resource "ssh_resource" "install_lw" {
  host        = aws_instance.jenkins-server.public_ip
  host_user   = "ubuntu"
  user        = "ubuntu"
  private_key = tls_private_key.keypair.private_key_pem

  file {
    destination = "/home/ubuntu/install_lw.sh"
    content     = data.http.lw_install_script.body
    permissions = "0700"
  }

  commands   = ["sudo bash -x ./install_lw.sh"]
  depends_on = [data.http.lw_install_script, ssh_resource.server_setup]
}

resource "aws_instance" "jenkins-agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.ingress-ssh-from-all.id]

  key_name = "jenkins-server-key"
}

resource "ssh_resource" "agent_setup" {
  host        = aws_instance.jenkins-agent.public_ip
  host_user   = "ubuntu"
  user        = "ubuntu"
  private_key = tls_private_key.keypair.private_key_pem

  file {
    destination = "/home/ubuntu/setup_pkg.sh"
    content     = file("${path.module}/files/setup_pkg.sh")
    permissions = "0700"
  }

  file {
    destination = "/home/ubuntu/jenkins-agent-launch.sh"
    content     = file("${path.module}/files/jenkins-agent-launch.sh")
    permissions = "0700"
  }

  file {
    destination = "/home/ubuntu/jenkins-agent.sh"
    content = sensitive(templatefile("${path.module}/files/jenkins-agent.tpl", {
      jenkins_url  = "http://${aws_instance.jenkins-server.private_ip}:8080"
      jenkins_auth = "${var.jenkins_admin}:${var.jenkins_admin_password}"
    }))
    permissions = "0700"
  }

  commands = [
    "bash -x ./setup_pkg.sh",
    "bash -x ./jenkins-agent-launch.sh",
  ]

  depends_on = [aws_instance.jenkins-agent, ssh_resource.server_setup]
}

resource "ssh_resource" "install_lw_agent" {
  host        = aws_instance.jenkins-agent.public_ip
  host_user   = "ubuntu"
  user        = "ubuntu"
  private_key = tls_private_key.keypair.private_key_pem

  file {
    destination = "/home/ubuntu/install_lw.sh"
    content     = data.http.lw_install_script.body
    permissions = "0700"
  }

  commands   = ["sudo bash -x ./install_lw.sh"]
  depends_on = [data.http.lw_install_script, ssh_resource.agent_setup]
}

output "aws_lb" {
  value = aws_alb.jenkins_alb.dns_name
}
