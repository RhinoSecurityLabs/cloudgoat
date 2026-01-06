####################################
# Data Source for Solution Stack
####################################

data "aws_elastic_beanstalk_solution_stack" "python_stack" {
  most_recent = true # Get the latest version matching the regex
  name_regex  = "^64bit Amazon Linux 2023.*running Python 3.11$"
}


#############################
# Elastic Beanstalk Application
#############################

resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "${var.cgid}-app"
  description = "Elastic Beanstalk application for insecure secrets scenario"
}

#############################
# Elastic Beanstalk Environment
#############################

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = replace("${var.cgid}-env", "_", "-")
  application         = aws_elastic_beanstalk_application.eb_app.name
  # Dynamically use the latest Python solution stack found by the data source
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.python_stack.name

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECONDARY_ACCESS_KEY"
    value     = aws_iam_access_key.secondary_key.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECONDARY_SECRET_KEY"
    value     = aws_iam_access_key.secondary_key.secret
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }
  # Launch this in the CG VPC
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.subnet.id
  }
}