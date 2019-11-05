resource "aws_s3_bucket" "secure-baseline-bucket" {
  bucket = local.environment-bucket-name
  acl    = "private"

  tags = {
    Name = local.environment-bucket-name
  }
  lifecycle {
    prevent_destroy = false
  }
}