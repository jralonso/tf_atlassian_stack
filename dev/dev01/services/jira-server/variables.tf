# ######################################
# Jira Server parameters
# ######################################

variable "jira" {
  type = object({
    ami = string
    instance_class = string
    recovery_admin = bool
    recovery_admin_password = string
    jira_data_volume_GB = number
    jira_logs_volume_GB = number
    tomcat_logs_volume_GB = number
  })

  default = {
    ami = "ami-0b418580298265d5c" #Ubuntu Server 18.04 LTS 
    instance_class = "m5.xlarge"
    recovery_admin = true
    recovery_admin_password = "12345678"
    jira_data_volume_GB = 200
    jira_logs_volume_GB = 20
    tomcat_logs_volume_GB = 20
  }
}

# Key Pairs
variable "key_name" {
  default = "devColl"
}