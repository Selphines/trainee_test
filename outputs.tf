
output "EIP" {
  value = aws_eip.my_static_ip.public_ip
}

output "WebServer1_Public_ip" {
  value = aws_instance.Web1.public_ip
}

output "WebServer2_Public_ip" {
  value = aws_instance.Web2.public_ip
}
