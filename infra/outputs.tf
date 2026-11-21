output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "annotation_table_role_arn" {
  value = aws_iam_role.annotation_table.arn
}

output "table_bucket_arn" {
  value = aws_s3tables_table_bucket.siem.arn
}