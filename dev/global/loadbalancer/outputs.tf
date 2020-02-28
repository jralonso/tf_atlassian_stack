output "front-lb-dns" {
  value = "${aws_lb.front.dns_name}"
}

output "internal-lb-dns" {
  value = "${aws_lb.internal.dns_name}"
}