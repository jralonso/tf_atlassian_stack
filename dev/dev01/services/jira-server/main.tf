provider "aws" { 
  profile = "${data.terraform_remote_state.vpc.outputs.profile}"
  region  = "${data.terraform_remote_state.vpc.outputs.region}"
}

locals {
    subnet_id = "${data.terraform_remote_state.vpc.outputs.col_nets[data.terraform_remote_state.vpc.outputs.indexAZ]}"
    environment = "${data.terraform_remote_state.vpc.outputs.environment}"
}

# Store terraform state in the S3 bucket
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "zdevco-tf-state"
    key            = "dev/dev01/services/jira-server/terraform.tfstate"
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
# Jira Server Host
# ############################################################

# Ubuntu version
resource "aws_instance" "jira" {
  ami           = "${var.jira.ami}"
  instance_type = "${var.jira.instance_class}"
  subnet_id     = local.subnet_id
  associate_public_ip_address = true 
  key_name                    = "${var.key_name}"
  disable_api_termination     = false
  monitoring                  = false
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.jira-server-sg]

  user_data = <<-EOT
          #!/bin/bash -ex
          # Send user data logs to a file
          exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
          # Install mysql client          
          # Documentation: https://dev.mysql.com/doc/mysql-repo-excerpt/5.7/en/linux-installation-yum-repo.html
          apt-get update -y
          apt-get install mysql-client -y       
          # Install docker
          # Install the requirements for docker
          # Add DEBIAN_FRONTEND=noninteractive to avoid interactive apt-get questions (things that -y does not prevent)
          DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
          # Add Docker's GPG key
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
          # Use the following command to set up the stable repository
          add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu  \
          $(lsb_release -cs) \
          stable"          
          # Update the apt package index.
          apt-get update -y
          # Install the latest version of Docker Engine - Community and containerd, 
          # add -y flag to install unattended
          apt-get install docker-ce docker-ce-cli containerd.io -y
          # Add the user to the supplementary group(s)
          usermod -aG docker ubuntu
          # Create volumes and mount points
          # mount points for future named volumes
          mkdir /var/lib/docker/volumes/jiradata_volume
          mkdir /var/lib/docker/volumes/tomcatlogs_volume
          # format volumes
          mkfs -t ext4 /dev/nvme1n1
          mkfs -t ext4 /dev/nvme2n1
          # Mount host volumes
          mount /dev/nvme1n1 /var/lib/docker/volumes/jiradata_volume
          mount /dev/nvme2n1 /var/lib/docker/volumes/tomcatlogs_volume
          # Create named Volumes
          docker volume create --name jiradata_volume
          docker volume create --name tomcatlogs_volume
          docker run -v jiradata_volume:/var/atlassian/application-data/jira \
          -v tomcatlogs_volume:/opt/atlassian/jira/logs \
          --name="jira" -d -p 8080:8080 atlassian/jira-software
          EOT

  tags = {
    Name = "[${local.environment}] Jira Server"
    Environment = "${${local.environment}}"
  }  
}

# ##########################################################
# Jira server external volumes  
# ##########################################################

resource "aws_ebs_volume" "jira_data" {
  availability_zone = "${aws_instance.jira.availability_zone}"
  size              = "${var.jira.jira_data_volume_GB}"
  type              = "gp2"

  tags = {
    Name = "[${local.environment}]-jira_data-ebs"
    Environment = "${local.environment}"
  }
}

resource "aws_ebs_volume" "tomcat_logs" {
  availability_zone = aws_instance.jira.availability_zone
  size              = "${var.jira.tomcat_logs_volume_GB}"
  type              = "gp2"

  tags = {
    Name = "[${local.environment}]-tomcat_logs-ebs"
    Environment = "${local.environment}"
  }
}

resource "aws_volume_attachment" "jira_data_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jira_data.id
  instance_id = aws_instance.jira.id
}

resource "aws_volume_attachment" "tomcat_logs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.tomcat_logs.id
  instance_id = aws_instance.jira.id
}