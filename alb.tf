resource "aws_lb" "application-loadbalancer" {
  count                      = var.application_loadbalancer ? 1 : 0
  name                       = "${var.infrastructurename}-alb"
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.alb-sg[0].id]
  subnets                    = local.public_subnet_ids
  # [ELB.6] Application, Gateway, and Network Load Balancers should have deletion protection enabled
  enable_deletion_protection = true
  idle_timeout               = 300
  tags                       = var.tags
}

resource "aws_lb_listener" "httplistener" {
  count             = var.application_loadbalancer ? 1 : 0
  load_balancer_arn = aws_lb.application-loadbalancer[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "httpslistener" {
  count             = var.application_loadbalancer ? 1 : 0
  load_balancer_arn = aws_lb.application-loadbalancer[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetgroup[0].arn
  }

  tags = var.tags
}

resource "aws_lb_target_group" "targetgroup" {
  count           = var.application_loadbalancer ? 1 : 0
  name            = "${substr(var.infrastructurename, 0, 32 - 7)}-alb-tg"
  port            = 443
  protocol        = "HTTPS"
  target_type     = "ip"
  ip_address_type = "ipv4"
  vpc_id          = local.vpc_id
  health_check {
    path     = "/healthz"
    protocol = "HTTPS"
  }

  depends_on = [module.eks-addons]

  tags = var.tags
}


resource "aws_security_group" "alb-sg" {
  count       = var.application_loadbalancer ? 1 : 0
  name        = "${var.infrastructurename}-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic on Application Load Balancer"
  vpc_id      = local.vpc_id

  ingress = [
    {
      description      = "Allow ingoing HTTP traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow ingoing HTTPS traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "Allow all outgoing traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false

    }
  ]

  tags = var.tags
}
