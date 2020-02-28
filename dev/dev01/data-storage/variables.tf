# ######################################
# Database parameters
# ######################################

variable "mysql" {
  type = object({
    port = number
    dbname = string
    dbuser = string
    dbpass = string
    allocated_storage = number
    instance_class = string
    publicly_accessible = bool
    skip_final_snapshot = bool
  })

  default = {
    port = 3306
    dbname = "jira"
    dbuser = "jira"
    dbpass = "12345678"
    allocated_storage = 50
    instance_class = "db.t3.large"
    publicly_accessible = false
    skip_final_snapshot = true
  }
}  