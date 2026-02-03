output "sg_id" {
  value = aws_security_group.sg.id
}

output "public_ip" {
  value = aws_instance.instances.public_ip
}

output "private_ip" {
  value = aws_instance.instances.private_ip
}

output "instance_id" {
  value = aws_instance.instances.id
}