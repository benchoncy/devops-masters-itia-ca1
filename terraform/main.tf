resource "aws_security_group" "allow_http" {
  name = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}

resource "aws_lb" "web_server_lb" {
  name = "${var.PROJECT}-${var.ENVIORNMENT}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.allow_http.id ]
  subnets = aws_subnet.public_sns[*].id
}

resource "aws_lb_target_group" "web_server_lb_tg" {
  name = "${var.PROJECT}-${var.ENVIORNMENT}-lb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "web_server_lb_listener" {
  load_balancer_arn = aws_lb.web_server_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_server_lb_tg.arn
  }
}

resource "aws_autoscaling_group" "web_server_as_group" {
  name = "${aws_launch_configuration.web_server_as_conf.name}-as-group"

  max_size = var.MAX_INSTANCES
  min_size = var.MIN_INSTANCES
  desired_capacity = var.TARGET_INSTANCES

  health_check_grace_period = var.HEALTH_CHECK_GRACE_PERIOD
  health_check_type = "ELB"

  target_group_arns = [ aws_lb_target_group.web_server_lb_tg.arn ]

  launch_configuration = aws_launch_configuration.web_server_as_conf.name

  force_delete = true
  vpc_zone_identifier = aws_subnet.public_sns[*].id

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "${var.PROJECT}-${var.ENVIORNMENT}-web-sever"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "web_server_as_conf" {
  name = "web-${var.PROJECT}-${var.ENVIORNMENT}-conf"
  image_id = var.AMI
  instance_type = var.INSTANCE_TYPE

  security_groups = [ aws_security_group.allow_http.id ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "web_server_sdp" {
  name = "${var.PROJECT}-${var.ENVIORNMENT}-sdp"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_as_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_server_cpu_sda" {
  alarm_name = "${var.PROJECT}-${var.ENVIORNMENT}-web-server-cpu-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "15"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_server_as_group.name
  }

  alarm_description = "Monitor EC2 web server instance for low CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_server_sdp.arn ]
}

resource "aws_autoscaling_policy" "web_server_sup" {
  name = "${var.PROJECT}-${var.ENVIORNMENT}-sup"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_as_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_server_cpu_sua" {
  alarm_name = "${var.PROJECT}-${var.ENVIORNMENT}-web-server-cpu-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "75"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_server_as_group.name
  }

  alarm_description = "Monitor EC2 web server instance for high CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_server_sup.arn ]
}