provider "aws" { 
  profile = "${data.terraform_remote_state.vpc.outputs.profile}"
  region  = "${data.terraform_remote_state.vpc.outputs.region}"
}

# Store terraform state in the S3 bucket
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "zdevco-tf-state"
    key            = "dev/global/loadbalancer/terraform.tfstate"
    region         = "eu-central-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "zdevco-tf-locks"
    encrypt        = true
  }
}

# Retrieve state of other terraform stacks (VPC)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    # Replace this with your bucket name!
    bucket = "zdevco-tf-state"
    key    = "dev/dev01/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}        

# ############################################################
# Front Application Load Balancer
# ############################################################

resource "aws_lb" "front_lb" {
  name               = "${data.terraform_remote_state.vpc.outputs.environment}-front-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.vpc.outputs.front-lb-sg]
  subnets            = data.terraform_remote_state.vpc.outputs.col_nets

  enable_deletion_protection = false

  access_logs {
    bucket  = "zdevco-tf-logging"
    prefix  = "${data.terraform_remote_state.vpc.outputs.environment}-front-lb"
    enabled = true
  }

  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.environment}-front-lb"
    Environment = "${data.terraform_remote_state.vpc.outputs.environment}"
  }
}

resource "aws_lb_listener" "front" {
  load_balancer_arn = aws_lb.front_lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_lb_tg.arn
  }
}

resource "aws_lb_target_group" "front_lb_tg" {
  name     = "tf-front-lb-tg"
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  port     = 8080

  lifecycle {
        create_before_destroy = true
        ignore_changes = [name]
    }
}

resource "aws_lb_target_group_attachment" "front_lb_jira" {
  count            = var.numAZs
  target_group_arn = aws_lb_target_group.front_lb_tg.arn
  target_id        = aws_instance.jiraserver[count.index].id
  port = 8080
}

# ############################################################
# Internal Application Load Balancer
# ############################################################
resource "aws_lb" "internal" {
  name               = "${data.terraform_remote_state.vpc.outputs.environment}-internal-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.vpc.outputs.internal-lb-sg]
  subnets            = data.terraform_remote_state.vpc.outputs.col_nets

  enable_deletion_protection = false

  access_logs {
    bucket  = "zdevco-tf-logging"
    prefix  = "${data.terraform_remote_state.vpc.outputs.environment}-internal-lb"
    enabled = true
  }

  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.environment}-internal-lb"
    Environment = "${data.terraform_remote_state.vpc.outputs.environment}"
  }
}