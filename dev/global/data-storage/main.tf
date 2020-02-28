provider "aws" { 
  profile = var.profile
  region  = var.region
}

# Bucket for remote state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "devc-tf-state"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Dynamo DB for locking state
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "devc-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}