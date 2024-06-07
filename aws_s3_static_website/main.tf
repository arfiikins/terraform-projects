# This is an IaC to upload an html file in S3 and can be accessed by from anywhere
provider "aws" {
  region     = "us-west-1"
}

# Creating a JSON document IAM policy 
data "aws_iam_policy_document" "allow_s3GetObject_to_all" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.static_website.arn}/*",
    ]
  }
}

# Creating an S3 bucket
resource "aws_s3_bucket" "static_website" {
  bucket = "flappy-bird-static-website"
  
}

# Enable Versioning (optional)
resource "aws_s3_bucket_versioning" "static-websit-versioning-enabled" { 
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable static website 
resource "aws_s3_bucket_website_configuration" "static-website-config" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

# Create an S3 Bucket Policy from the data we have created aboce and attach it to the created bucket
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = data.aws_iam_policy_document.allow_s3GetObject_to_all.json
}


resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.static_website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Make S3 bucket have public access since it will be a static website
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Create an S3 bucket ACL to have public access
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.static_website.id
  acl    = "public-read"
}

# Upload the object (or the our htl file) from current working directory
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = "index.html"
  source       = "./flappy.html"                     #data.github_repository_file.flappy_file.file
  content_type = "text/html"
}

# Use the value this outputs on CLI and paste it to the browser
output "website_url" {
  value = aws_s3_bucket_website_configuration.static-website-config.website_endpoint
}
