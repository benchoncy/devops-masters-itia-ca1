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
    Project = var.PROJECT
  }
}

resource "aws_elb" "web_server_elb" {
  name = "${var.PROJECT}-${var.DEPLOYMENT}-elb"
  security_groups = [ aws_security_group.allow_http.id ]
  subnets = [ aws_subnet.public_sn.id ]

  cross_zone_load_balancing = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}

resource "aws_autoscaling_group" "web_server_as_group" {
  name = "${aws_launch_configuration.web_server_as_conf.name}-as-group"

  max_size = var.MAX_INSTANCES
  min_size = var.MIN_INSTANCES
  desired_capacity = var.TARGET_INSTANCES

  health_check_grace_period = var.HEALTH_CHECK_GRACE_PERIOD
  health_check_type = "ELB"

  load_balancers = [ aws_elb.web_server_elb.id ]

  launch_configuration = aws_launch_configuration.web_server_as_conf.name

  force_delete = true
  vpc_zone_identifier = [ aws_subnet.public_sn.id ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "${var.PROJECT}-${var.DEPLOYMENT}-web-sever"
    propagate_at_launch = true
  }

  tag {
    key = "Project"
    value = var.PROJECT
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "web_server_as_conf" {
  name_prefix = "web-${var.PROJECT}-"
  image_id = var.AMI
  instance_type = var.INSTANCE_TYPE

  security_groups = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "web_server_sdp" {
  name = "${var.PROJECT}-${var.DEPLOYMENT}-sdp"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_as_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_server_cpu_sda" {
  alarm_name = "${var.PROJECT}-${var.DEPLOYMENT}-web-server-cpu-down"
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
  name = "${var.PROJECT}-${var.DEPLOYMENT}-sup"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_server_as_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_server_cpu_sua" {
  alarm_name = "${var.PROJECT}-${var.DEPLOYMENT}-web-server-cpu-up"
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
  alarm_actions = [ aws_autoscaling_policy.web_server_sdp.arn ]
}

output "elb_dns_name" {
  value = aws_elb.web_server_elb.dns_name
}