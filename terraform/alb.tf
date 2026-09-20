resource "aws_lb" "alb" {
  name               = "django-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
  tags = {
    Name = "django_alb"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name        = "django-alb-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.django_vpc.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "django_alb_target_group"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
  tags = {
    Name = "django_alb_listener"
  }
}

resource "aws_lb_target_group_attachment" "alb_target_group_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}
