provider "aws" { 
  profile = "${data.terraform_remote_state.vpc.outputs.profile}"
  region  = "${data.terraform_remote_state.vpc.outputs.region}"
}

locals {
    subnet_id = "${data.terraform_remote_state.vpc.outputs.col_nets[data.terraform_remote_state.vpc.outputs.indexAZ]}"
}

# Store terraform state in the S3 bucket
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "zdevco-tf-state"
    key            = "dev/dev01/services/bastion/terraform.tfstate"
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

# Retrieve state of other terraform stacks (VPC)
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    # Replace this with your bucket name!
    bucket = "zdevco-tf-state"
    key    = "dev/dev01/data-storage/terraform.tfstate"
    region = "eu-central-1"
  }
}

# ############################################################
# Bastion Host
# ############################################################

# Create a new instance of the latest Amazon Linux  on an
# t2.micro node with an AWS Tag naming it for the environment
resource "aws_instance" "bastion" {
  ami           = "${var.bastion_ami}"
  instance_type = "${var.bastion_instancetype}"
  subnet_id     = local.subnet_id
  associate_public_ip_address = true
  key_name                    = "${var.key_name}"
  disable_api_termination     = false
  monitoring                  = false
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.bastion-sg]

  user_data = <<-EOT
          #!/bin/bash -ex
          # Install mysql
          # Documentation: https://dev.mysql.com/doc/mysql-repo-excerpt/5.7/en/linux-installation-yum-repo.html
          yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm          
          yum install -y mysql-community-client
          # Download database backup
          aws s3 cp s3://"${var.bucketDBbackup}" /tmp
          # Decompress database backup
          sudo bzip2 -d /tmp/"${var.bucketDBbackup}"
          # Set up database
          echo "DROP DATABASE IF EXISTS ${data.terraform_remote_state.db.outputs.dbname};" >> /tmp/setup.mysql
          #echo "CREATE DATABASE ${JiraDBName} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;" >> /tmp/setup.mysql
          echo "CREATE USER '${data.terraform_remote_state.db.outputs.dbuser}'@'%' IDENTIFIED BY '${data.terraform_remote_state.vpc.outputs.dbpass}';" >> /tmp/setup.mysql
          echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,REFERENCES,ALTER,INDEX on ${data.terraform_remote_state.db.outputs.dbuser}.* TO '${data.terraform_remote_state.db.outputs.dbuser}'@'%';" >> /tmp/setup.mysql
          echo "FLUSH PRIVILEGES;" >> /tmp/setup.mysql
          mysql -u${data.terraform_remote_state.db.outputs.dbuser} -p${data.terraform_remote_state.db.outputs.dbpass} -h${data.terraform_remote_state.db.outputs.dbendpoint} < /tmp/setup.mysql
          mysql -u${data.terraform_remote_state.db.outputs.dbuser} -p${data.terraform_remote_state.db.outputs.dbpass} -h${data.terraform_remote_state.db.outputs.dbendpoint} < /tmp/dev-jira-02_backup.sql
          EOT

  tags = {
    Name = "[${data.terraform_remote_state.vpc.outputs.environment}] Bastion"
    Environment = "${data.terraform_remote_state.vpc.outputs.environment}"
  }  
}