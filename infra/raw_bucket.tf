# stores original log files, never modified
data "aws_caller_identity" "current" {}

# Account ID suffix keeps the name unique without hard-coding it
resource "aws_s3_bucket" "raw" {
  bucket = "s3-table-siem-raw-${data.aws_caller_identity.current.account_id}"
}

# Keeps every file version so annotations and events can link to an exact version
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 encryption, inherited by annotations
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Blocks all public access to the security logs
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}