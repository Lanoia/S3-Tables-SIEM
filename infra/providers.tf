provider "aws" {
  region  = "ap-southeast-2"
  profile = "s3-table-siem"

  default_tags {
    tags = {
      project = "s3-table-siem"
    }
  }
}