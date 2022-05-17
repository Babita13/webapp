resource "aws_launch_template" "foo" {
  name = "foo-test"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
      encrypted = true
    }
  }

    block_device_mappings {
    device_name = "/dev/sdb"

    ebs {
      volume_size = 20
      encrypted = true
    }
  }


  image_id = lookup(var.AMI, var.AWS_REGION)


  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.ssh_allowed.id]


  user_data = filebase64("${path.module}/httpd.sh")
}


resource "aws_security_group" "elb_sg" {
  vpc_id = aws_vpc.vpc.id

  egress = [{
    from_port        = 0
    to_port          = 0
    protocol         = -1
    description      = "all open"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  ingress = [
    //If you do not add this rule, you can not reach the httpd  
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "for http"

      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false

  }]
}


resource "aws_security_group" "ssh_allowed" {
  vpc_id = aws_vpc.vpc.id

  egress = [{
    from_port        = 0
    to_port          = 0
    protocol         = -1
    description      = "all open"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  ingress = [{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "for SSH"
    // This means, all ip address are allowed to ssh ! 
    // Do not do it in the production. 
    // Put your office or home address in it! 
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    },
    //If you do not add this rule, you can not reach the NGIX  
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "for http"

      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.elb_sg.id]
      self             = false

  }]

}

resource "aws_autoscaling_group" "bar" {
  desired_capacity   = 1
  max_size           = 5
  min_size           = 1
  vpc_zone_identifier = tolist(aws_subnet.private_subnet.*.id)
  termination_policies      = ["OldestInstance"]
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.foo.id
    version = "$Latest"
  }
}



resource "aws_alb" "test_alb" {
  name = "foobar-terraform-elb"
  internal           = false
  load_balancer_type = "application"
  subnets                     = tolist(aws_subnet.public_subnet.*.id)
  security_groups             = [aws_security_group.elb_sg.id]

}

resource "aws_lb_target_group" "test_tg" {
  name     = "test-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}
resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_alb.test_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test_tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.bar.id
  lb_target_group_arn    = aws_lb_target_group.test_tg.arn
}



resource "aws_autoscaling_policy" "mygroup_policy" {
  name                   = "autoscalegroup_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.bar.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "70"
  alarm_actions = [
        "${aws_autoscaling_policy.mygroup_policy.arn}"
    ]
dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.bar.name}"
  }
}