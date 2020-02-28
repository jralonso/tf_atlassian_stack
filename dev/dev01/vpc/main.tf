provider "aws" { 
  profile = "${var.profile}"
  region  = "${var.region}"
}

# Store terraform state in the S3 bucket
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "zdevco-tf-state"
    key            = "dev/dev01/vpc/terraform.tfstate"
    region         = "eu-central-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "zdevco-tf-locks"
    encrypt        = true
  }
}

# ############################################
# Security groups
# ############################################

# Bastion 
resource "aws_security_group" "bastion" {
  name          = "${var.environment}-bastion-sg"
  description   = "SG general access to bastion host from zooplus network"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.225.25.138/32","212.230.26.242/32","213.97.254.165/32","91.223.129.16/29"]
  }
  egress {
    from_port   = "${var.dbport}"
    to_port     = "${var.dbport}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.environment}-bastion-sg"
    Value = "${var.environment}"
  }
}

# Database
resource "aws_security_group" "rds" {
  name          = "${var.environment}-rds-sg"
  description   = "SG general access to database from zooplus network"
  ingress {
    from_port   = "${var.rds.port}"
    to_port     = "${var.rds.port}"
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id, aws_security_group.jira-server.id]
  }

  tags = {
    Name  = "${var.environment}-rds-sg"
    Value = "${var.environment}"
  }
}

# Jira Server
resource "aws_security_group" "jira-server" {
  name          = "${var.environment}-jira-server-sg"
  description   = "Access to Jira server Instance"
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["77.225.25.138/32","212.230.26.242/32","213.97.254.165/32","91.223.129.16/29"]
  }
  egress {
    from_port   = "${var.rds.port}"
    to_port     = "${var.rds.port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Needed for docker install
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.environment}-jira-server-sg"
    Value = "${var.environment}"
  }
}

# Front LB 
resource "aws_security_group" "front" {
  name = "${var.environment}-front-lb-sg"
  description   = "Access to Load Balancer from Internet"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["77.225.25.138/32","212.230.26.242/32","213.97.254.165/32","91.223.129.16/29"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.environment}-front-lb-sg"
    Value = "${var.environment}"
  }
}

# Internal LB
resource "aws_security_group" "int_lb_sg" {
  name = "${var.environment}-internal-lb-sg"
  description   = "Access to Load Balancer from VPC"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.jira-server.id]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.jira-server.id]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.jira-server.id]
  }
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.jira-server.id]
  }
  tags = {
    Name  = "${var.environment}-internal-lb-sg"
    Value = "${var.environment}"
  }
}