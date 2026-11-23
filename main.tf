terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "rahul_p22_logs" {
  bucket        = "rahul-p22-log-archive-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name    = "rahul-p22-log-archive"
    Project = "P22-S3-Log-Archive-Lifecycle"
  }
}

resource "aws_s3_object" "app_log_1" {
  bucket  = aws_s3_bucket.rahul_p22_logs.id
  key     = "logs/app-2026-11-23.log"
  content = <<-LOG
    2026-11-23T05:30:01Z INFO  [auth-service] User session initialized
    2026-11-23T05:31:14Z INFO  [api-gateway] GET /v1/health 200 OK (4ms)
    2026-11-23T05:32:49Z WARN  [worker-node] High memory watermark detected (78%)
  LOG
}

resource "aws_s3_object" "app_log_2" {
  bucket  = aws_s3_bucket.rahul_p22_logs.id
  key     = "logs/access-2026-11-23.log"
  content = <<-LOG
    10.0.1.14 - - [23/Nov/2026:05:35:00 +0000] "GET /index.html HTTP/1.1" 200 1024
    10.0.1.22 - - [23/Nov/2026:05:36:12 +0000] "POST /api/metrics HTTP/1.1" 202 64
  LOG
}

resource "aws_s3_bucket_lifecycle_configuration" "rahul_p22_lifecycle" {
  bucket = aws_s3_bucket.rahul_p22_logs.id

  rule {
    id     = "rahul-p22-log-expiration-rule"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.rahul_p22_logs.id
}
