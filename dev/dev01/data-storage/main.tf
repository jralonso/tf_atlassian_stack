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

# ############################################################
# Database RDS
# ############################################################

resource "aws_db_instance" "rds" {
  allocated_storage           = "${var.rds.allocated_storage}"
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t3.medium"
  name                        = "${var.rds.dbname}"
  username                    = "${var.rds.dbuser}"
  password                    = "${var.rds.dbpass}"
  parameter_group_name        = "${aws_db_parameter_group.rds.id}"
  option_group_name           = "default:mysql-5-7"
  port                        = var.rds.port
  publicly_accessible         = "${var.rds.publicly_accessible}"
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.db-sg]
  storage_encrypted           = false
  multi_az                    = false
  backup_retention_period     = 0
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = false
  final_snapshot_identifier   = "terraform-mysql"
  skip_final_snapshot         = "${var.rds.skip_final_snapshot}"

  tags = {
    environment = var.environment
  }
}

resource "aws_db_parameter_group" "rds" {
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
