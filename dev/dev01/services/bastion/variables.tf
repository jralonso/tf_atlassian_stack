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