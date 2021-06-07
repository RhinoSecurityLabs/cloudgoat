
resource "aws_launch_configuration" "ecs_launch_config" {
    image_id             = "ami-07fde2ae86109a2af"
    iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
    security_groups      = [aws_security_group.ecs_sg.id]
    user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config"
    instance_type        = "t2.micro"
    associate_public_ip_address = true
}

resource "aws_autoscaling_group" "ecs_asg" {
    name                      = "asg"
    vpc_zone_identifier       = [aws_subnet.priv_subnet.id]
    launch_configuration      = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 2
    min_size                  = 1
    max_size                  = 10
    health_check_grace_period = 300
    health_check_type         = "EC2"
}