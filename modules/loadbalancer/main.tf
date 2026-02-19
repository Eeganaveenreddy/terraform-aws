resource "aws_lb" "test" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_id
  idle_timeout       = 300

  # enable_deletion_protection = true

  tags = {
    Environment = "uat"
    Name        = "alb-terrafrom"
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
  port = each.key == "jenkins-terraform" ? 8080 : 8069

  health_check {
    # Use lightweight login endpoints for faster checks.
    path                = each.key == "jenkins-terraform" ? "/jenkins/login" : "/web/login"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = each.key == "jenkins-terraform" ? "200,403" : "200-399"
    healthy_threshold   = each.key == "jenkins-terraform" ? 3 : 3
    unhealthy_threshold = each.key == "jenkins-terraform" ? 5 : 5
    interval            = 30
    timeout             = each.key == "jenkins-terraform" ? 15 : 15
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "tg-${each.key}"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg["app-terraform"].arn
        weight = 1
      }
      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "jenkins_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg["jenkins-terraform"].arn
        weight = 1
      }
    }
  }

  condition {
    path_pattern {
      values = ["/jenkins", "/jenkins/*"]
    }
  }

  depends_on = [aws_lb_target_group.tg]
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

  ingress {
    from_port   = 443
    to_port     = 443
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
