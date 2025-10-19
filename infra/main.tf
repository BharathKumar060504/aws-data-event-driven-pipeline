terraform {
  backend "s3" {
    bucket = "flights-data-pipeline-bharath-2025"
    key    = "terraform/state.tfstate"
    region = "ap-south-1"
  }
}

# --------------------------
#  S3 Bucket for Data
# --------------------------
resource "aws_s3_bucket" "data_bucket" {
  bucket = "flights-data-pipeline-bharath-2025" # must be globally unique
  force_destroy = true
}

# --------------------------
#  DynamoDB Table
# --------------------------
resource "aws_dynamodb_table" "flights_table" {
  name         = "FlightsData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# --------------------------
# IAM Role for Lambda
# --------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "flights_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# --------------------------
#  IAM Policy for Lambda
# --------------------------
resource "aws_iam_role_policy" "lambda_policy" {
  name = "flights_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.flights_table.arn
      }
    ]
  })
}
