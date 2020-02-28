# ######################################
# Account parameters
# ######################################

variable "profile" {
  default = "575877736355_OperatorAccess"
}

# ######################################
# Environment parameters
# ######################################

variable "environment" {
  type = "string"
  default = "dev01"
}

# ######################################
# Network parameters
# ######################################

variable "vpc_id" {
  # Value for Development, won't work on prod
  default = "vpc-053920233cea88382"
}

variable "col_nets" {
  type = "list"
  default = ["subnet-0a5730616505c2573", "subnet-02fefa00a515eabd9", "subnet-04138e6d787c92a08"]
}

# Define Region for the infraestructure
variable "region" {
  default = "eu-central-1"
}

variable "indexAZ" {
  type = number
  default = 0
}

# ######################################
# Database parameters
# ######################################

variable "dbport" {
  type = number
  default = 3306
}

