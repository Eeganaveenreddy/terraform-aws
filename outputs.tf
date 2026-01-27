output "private_instance_ips" {
  value = {
    for name, instance in module.ec2 : name => instance.private_ip
  }
  description = "Private IP addresses for all deployed instances"
}
