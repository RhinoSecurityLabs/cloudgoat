// # below is the filter which will detect events
// resource "aws_cloudwatch_log_metric_filter" "yada" {
//   name           = "MyAppAccessCount"
//   pattern        = ""
//   log_group_name = "${aws_cloudwatch_log_group.dada.name}"

//   metric_transformation {
//     name      = "EventCount"
//     namespace = "YourNamespace"
//     value     = "1"
//   }
// }

// #below is the alert which specifies the event threshold
// resource "aws_cloudwatch_metric_alarm" "foobar" {
//   alarm_name                = "terraform-test-foobar5"
//   comparison_operator       = "GreaterThanOrEqualToThreshold"
//   evaluation_periods        = "2"
//   metric_name               = "CPUUtilization"
//   namespace                 = "AWS/EC2"
//   period                    = "120"
//   statistic                 = "Average"
//   threshold                 = "80"
//   alarm_description         = "This metric monitors ec2 cpu utilization"
//   insufficient_data_actions = []
// }