# #####################################
# Account defaults
# #####################################

# ######################################
# Bastion parameters
# ######################################
variable "bastion_ami" {
  default = "ami-0df0e7600ad0913a9"  
}

variable "bastion_instancetype" {
  default = "t2.micro"  
}

# Key Pairs
variable "key_name" {
  default = "devColl"
}

# Key Pairs
variable "key_name" {
  default = "devColl"
}

# Key Pairs
variable "bucketDBbackup" {
  default = "devcollaboration001.s3.eu-central-1.amazonaws.com/dev-jira-02_backup.sql.bz2"
}