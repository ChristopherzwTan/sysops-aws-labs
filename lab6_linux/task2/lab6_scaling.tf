# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_ami_from_instance" "web_ami" {
  name = "WebServer"
  source_instance_id = "${var.ami_source_id}"
}

// ELB is classic load balancer
resource "aws_elb" "ws_lb" {
  name               = "webserverloadbalancer"
  subnets = ["${var.public_subnet_id}"]
  security_groups = ["${var.sg_id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    target              = "HTTP:80/ec2-stress/index.php"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 300

  tags {
    Name = "Webserver"
  }
}

resource "aws_launch_configuration" "ws_lc" {
  name          = "WebServerLaunchConfiguration"
  image_id      = "${aws_ami_from_instance.web_ami.id}"
  instance_type = "t2.micro"
  security_groups = ["${var.sg_id}"]
  key_name = "${var.default_key_name}"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "WebServerScaleOutAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "50"
  alarm_description         = "This metric monitors ec2 cpu utilization to scale up"
  
  alarm_actions     = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = "WebServerScaleInAlarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "30"
  alarm_description         = "This metric monitors ec2 cpu utilization to scale down"
    
  alarm_actions     = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "Increase Group Size"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ws_ag.name}"
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "Decrease Group Size"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ws_ag.name}"
}

resource "aws_autoscaling_group" "ws_ag" {
  name                      = "WebServersASGroup"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ws_lc.name}"
  vpc_zone_identifier       = ["${var.private_subnet_id}"]
  
  load_balancers = ["${aws_elb.ws_lb.name}"]
}
