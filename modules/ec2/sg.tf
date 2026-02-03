resource "aws_security_group" "sg" {
  name        = "${var.server_name}-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
  for_each = var.ingress_ports
  iterator = port_info
  
  content {
    from_port = port_info.value # Now you use the custom name
    to_port   = port_info.value
    protocol  = "tcp"
    
    # If the port is 80 (App), don't use CIDR. Use null instead.
    cidr_blocks = contains([8069, 8080], port_info.value) ? [] : ["0.0.0.0/0"]

    # If the port is 80 (App), attach the ALB Security Group ID.
    security_groups = contains([8069, 8080], port_info.value) ? [var.alb_sg_id] : []

  }
}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.server_name}-sg"
    Environment = var.env
  }
}