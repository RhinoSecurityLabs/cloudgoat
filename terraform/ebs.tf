resource "aws_ebs_volume" "unattached_volume" {
    availability_zone = "${var.availability_zone}"
    size = 8
    snapshot_id = "snap-091cfd2896206df7a"
}
