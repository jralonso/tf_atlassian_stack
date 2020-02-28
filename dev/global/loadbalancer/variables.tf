output "front-lb-dns" {
  value = "${aws_lb.front_lb.dns_name}"
}

output "internal-lb-dns" {
  value = "${aws_lb.internal_lb.dns_name}"
}