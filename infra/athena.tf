# Workgroup for all project queries and results stored by Athena 
resource "aws_athena_workgroup" "siem" {
  name = "s3-table-siem"

  configuration {
    enforce_workgroup_configuration = true

    # Cancels any query that would scan more than 1 GB
    bytes_scanned_cutoff_per_query = 1073741824

    managed_query_results_configuration {
      enabled = true
    }
  }
}