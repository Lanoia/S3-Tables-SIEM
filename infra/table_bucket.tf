# Table bucket for parsed event tables (names only need to be unique per account and Region)
resource "aws_s3tables_table_bucket" "siem" {
  name = "s3-table-siem"
}

# Namespace for SIEM tables, appears as a database in Athena
resource "aws_s3tables_namespace" "siem" {
  namespace        = "siem"
  table_bucket_arn = aws_s3tables_table_bucket.siem.arn
}