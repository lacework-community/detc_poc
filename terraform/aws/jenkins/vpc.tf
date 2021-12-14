resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "jenkins_vpc"
  }
}
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "jenkins_subnet"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet1
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-2c"
  tags = {
    Name = "jenkins_subnet1"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "jenkins_igw"
  }
}
resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "default route table"
  }
}
resource "aws_security_group" "ingress-ssh-from-all" {
  name   = "jenkins-allow-all-ssh-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-port-8080-from-alb" {
  name   = "jenkins-allow-ui-traffic"
  vpc_id = aws_vpc.vpc.id

  ingress {
    security_groups = [aws_security_group.ingress-port-8080-to-world.id, aws_security_group.ingress-ssh-from-all.id]
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
  }

  ingress {
    security_groups = [aws_security_group.ingress-port-8080-to-world.id, aws_security_group.ingress-ssh-from-all.id]
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-port-8080-to-world" {
  name   = "jenkins-allow-ui-traffic-to-alb"
  vpc_id = aws_vpc.vpc.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
