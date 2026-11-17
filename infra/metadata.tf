# Role that S3 Metadata assumes to read annotations from the raw bucket
resource "aws_iam_role" "annotation_table" {
  name = "s3-table-siem-annotation-table"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "metadata.s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        ArnLike      = { "aws:SourceArn" = aws_s3_bucket.raw.arn }
      }
    }]
  })
}

# Read-only access to annotations and the object listing
resource "aws_iam_role_policy" "annotation_table" {
  name = "read-annotations"
  role = aws_iam_role.annotation_table.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectAnnotation", "s3:GetObjectVersionAnnotation"]
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:ListBucketVersions"]
        Resource = aws_s3_bucket.raw.arn
      }
    ]
  })
}

# S3 Metadata config: journal table is required, inventory table not needed
resource "aws_s3_bucket_metadata_configuration" "raw" {
  bucket = aws_s3_bucket.raw.bucket

  metadata_configuration {
    inventory_table_configuration {
      configuration_state = "DISABLED"
    }

    # Journal records expire after 7 days to keep storage cost low
    journal_table_configuration {
      record_expiration {
        days       = 7
        expiration = "ENABLED"
      }
    }
  }
}