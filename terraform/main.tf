data "aws_ami" "deployment_ami" {
  most_recent = true

  owners = var.AMI_OWNERS

  filter {
    name = "name"
    values = ["${var.PROJECT}_${var.VERSION}*"]
  }
}

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

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.ALLOWED_SSH_SOURCES
  }

  tags = {
    Name = "Allow SSH Security Group"
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

resource "aws_lb_listener" "web_server_lb_listener_http" {
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

  tag {
    key = "Version"
    value = var.VERSION
    propagate_at_launch = true
  }

  tag {
    key = "Enviornment"
    value = var.ENVIORNMENT
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "web_server_as_conf" {
  name = "web-${var.PROJECT}-${var.ENVIORNMENT}-conf"
  image_id = data.aws_ami.deployment_ami.image_id
  instance_type = var.INSTANCE_TYPE

  security_groups = [ 
    aws_security_group.allow_http.id,
    aws_security_group.allow_ssh.id
  ]

  key_name = var.KEY_NAME

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

resource "aws_cloudwatch_dashboard" "web" {
  dashboard_name = "${var.PROJECT}-${var.ENVIORNMENT}-web-dashboard"
  dashboard_body = templatefile("${path.module}/dashboard.json.tftpl", { target_group = aws_lb_target_group.web_server_lb_tg, load_balancer =  aws_lb.web_server_lb, region=var.REGION})
}