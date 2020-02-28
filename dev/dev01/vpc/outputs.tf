output "vpc_id" {
  value       = "${var.vpc_id}"
  description = "VPC ID in collaboration dev account"
}
output "col_nets" {
  value       = "${var.col_nets}"
  description = "Subnet IDs in VPC development collaboration account"
}

output "environment" {
  value       = "${var.environment}"
  description = "Environment prefix"    
}

output "region" {
  value       = "${var.region}"
  description = "Environment region"  
}

output "indexAZ" {
  value       = "${var.indexAZ}"
  description = "Index used to choose one AZ in the list of subnets. Values available are: 0,1,2"  
}

output "dbport" {
  value       = "${var.dbport}"
  description = "Databse port"  
}

output "profile" {
  value       = "${var.profile}"
  description = "AWS Profle"  
}