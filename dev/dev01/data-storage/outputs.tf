output "dbname" {
  value = "${aws_db_instance.mysql.name}"
}

output "dbuser" {
  value = "${aws_db_instance.mysql.username}"
}

output "dbpass" {
  value = "${var.mysql.dbpass}"
}

output "dbendpoint" {
  value = "${aws_db_instance.mysql.address}"
}



