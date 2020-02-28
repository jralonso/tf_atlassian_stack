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
    key            = "dev/dev01/data-storage/terraform.tfstate"
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

data "aws_availability_zones" "available" {
  state = "available"
}

# ############################################################
# Database RDS
# ############################################################

resource "aws_db_instance" "mysql" {
  allocated_storage           = "${var.mysql.allocated_storage}"
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t3.medium"
  availability_zone           = "${data.aws_availability_zones.available.names[data.terraform_remote_state.vpc.outputs.indexAZ]}"
  name                        = "${var.mysql.dbname}"
  username                    = "${var.mysql.dbuser}"
  password                    = "${var.mysql.dbpass}"
  parameter_group_name        = "${aws_db_parameter_group.mysql.id}"
  option_group_name           = "default:mysql-5-7"
  port                        = data.terraform_remote_state.vpc.outputs.dbport
  db_subnet_group_name        = aws_db_subnet_group.mysql.name
  publicly_accessible         = "${var.mysql.publicly_accessible}"
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.db-sg]
  storage_encrypted           = false
  multi_az                    = false
  backup_retention_period     = 0
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = false
  final_snapshot_identifier   = "terraform-mysql"
  skip_final_snapshot         = "${var.mysql.skip_final_snapshot}"

  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.environment} Database"
    Environment = "${data.terraform_remote_state.vpc.outputs.environment}"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name       = "${data.terraform_remote_state.vpc.outputs.environment}-subnet-gr"
  subnet_ids = data.terraform_remote_state.vpc.outputs.col_nets

  tags = {
    Name = "${data.terraform_remote_state.vpc.outputs.profile} DB subnet group"
  }
}

resource "aws_db_parameter_group" "mysql" {
  family = "mysql5.7"
  description = "Parameters for Jira MySQL 5.7"

  parameter {
    name  = "sql_mode"
    value = "NO_ENGINE_SUBSTITUTION"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_bin"
  }

  parameter {
    name  = "innodb_default_row_format"
    value = "DYNAMIC"
  }

  parameter {
    name  = "innodb_large_prefix"
    value = "1"
  }

  parameter {
    name  = "innodb_file_format"
    value = "Barracuda"
  }

  parameter {
    name  = "innodb_log_file_size"
    value = "2147483648"
    apply_method = "pending-reboot" // Cannot be applied without rebooting
  }

  parameter {
    name  = "max_allowed_packet"
    value = "268435456"
  }

  parameter {
    name  = "binlog_format"
    value = "row"
  }

  parameter {
    name  = "tx_isolation"
    value = "READ-COMMITTED"
  }
}
