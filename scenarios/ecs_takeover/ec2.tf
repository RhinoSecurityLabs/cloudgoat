
resource "aws_key_pair" "seb" {
  key_name   = "seb-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiCN9xO8LnlRik28o2hzfwWuKnTrB2nYGGHw78ZtLSpxyjoY8JXIHrUf/+6KS7q8r4wSDRvVaDTwLmuhrCqyJ4c34C5o4BmazVvblxB1mnjv+k7rYQxiN2V+OkLZirzTaiAFdGG0nvZ8ITDTOBYQJqxv4RTMlg+zJMZz6VtNvbjgzvNEznJFOSYy6vm66eTIpKdL5Nk1+64ojzoDWEwNJX3Dh5vUabSjmn3WpTMlbSYINlj1FFyKQogn+AYko/FaUTVP126czPcHuu32bOPidYqN4yWtszb3WcnnlMVyvIlctylsQBWLMkiYZOaYguRw/HKtp9HnuKg8YkZnA7hKw9"
}


resource "aws_launch_configuration" "ecs_launch_config" {
    image_id             = "ami-09821bb7e5aa7e648"
    iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
    security_groups      = [aws_security_group.ecs_sg.id]
    user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config"
    instance_type        = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.seb.key_name
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
    name                      = "asg"
    vpc_zone_identifier       = [aws_subnet.priv_subnet.id]
    launch_configuration      = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 4
    min_size                  = 1
    max_size                  = 10
    health_check_grace_period = 300
    health_check_type         = "EC2"
}