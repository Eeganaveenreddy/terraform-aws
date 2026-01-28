resource "aws_lb" "test" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_id

  # enable_deletion_protection = true

  tags = {
    Environment = "demo-testing"
    Name = "alb-terrafrom"
  }
}

# resource "aws_lb_target_group" "lb_tg" {
#   # name = "${var.alb_name}-tg"
#   name_prefix = "t-tg-"
#   vpc_id = var.vpc_id
#   protocol = "HTTP"
#   port = "80"

#   lifecycle {
#     create_before_destroy = true
#   }
  
#   health_check {
#     path = "/"
#     port = "80"
#   }
# }

resource "aws_lb_target_group" "tg" {
  for_each = { for k, v in var.server_config : k => v if v.alb_enabled }

  name_prefix = "tg-${substr(each.key, 0, 3)}"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  
  # Map port 8080 for Jenkins, 8069 for App
  port        = each.key == "jenkins-terraform" ? 8080 : 8069

  health_check {
    # Jenkins usually responds at /login, App at /
    path = each.key == "jenkins-terraform" ? "/jenkins/login" : "/web/database/selector"
    port = "traffic-port"
    protocol            = "HTTP"
    matcher             = each.key == "jenkins-terraform" ? "200,403" : "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "tg-${each.key}"
  }
}

resource "aws_lb_listener" "test_lb_listener" {
  load_balancer_arn = aws_lb.test.arn
  protocol = "HTTP"
  port = 80

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg["app-terraform"].arn
  }
}

resource "aws_lb_listener_rule" "jenkins_rule" {
  listener_arn = aws_lb_listener.test_lb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["jenkins-terraform"].arn
  }

  condition {
    path_pattern {
      values = ["/jenkins", "/jenkins/*"]
    }
  }

  depends_on = [ aws_lb_target_group.tg ]
}

# Security Group for the ALB
resource "aws_security_group" "alb_sg" {
  name   = "${var.alb_name}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
