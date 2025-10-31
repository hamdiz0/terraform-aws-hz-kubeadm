## interanl lb for the k8s api ###
resource "aws_lb" "internal_lb" {
  count              = var.use_internal_lb ? 1 : 0
  name               = "k8s-api-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.private_subnet[*].id
  depends_on = [aws_lb_target_group_attachment.k8s_masters]
  tags = {
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

resource "aws_lb_target_group" "internal_lb_target_group" {
  count       = var.use_internal_lb ? 1 : 0
  name        = "k8s-api-tg"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  health_check {
    protocol            = "TCP"
    port                = 6443
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "k8s_api_lb_listener" {
  count             = var.use_internal_lb ? 1 : 0
  load_balancer_arn = aws_lb.internal_lb[0].arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_lb_target_group[0].arn
  }
}

resource "aws_lb_target_group_attachment" "k8s_masters" {
  count            = var.use_internal_lb ? var.control_plane_number : 0
  target_group_arn = aws_lb_target_group.internal_lb_target_group[0].arn
  target_id        = aws_instance.master[count.index].private_ip
  port             = 6443
}