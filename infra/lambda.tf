# --------------------------
# Lambda: process_flights_data
# --------------------------
resource "aws_lambda_function" "process_flights_data" {
  function_name = "process_flights_data"
  role          = aws_iam_role.lambda_role.arn
  handler       = "process_flights_data.lambda_handler"
  runtime       = "python3.10"
  filename      = "${path.module}/../process_flights_data.zip"

  environment {
    variables = {
      DYNAMO_TABLE = aws_dynamodb_table.flights_table.name
    }
  }
}

# --------------------------
# Lambda: generate_daily_report
# --------------------------
resource "aws_lambda_function" "generate_daily_report" {
  function_name = "generate_daily_report"
  role          = aws_iam_role.lambda_role.arn
  handler       = "generate_daily_report.lambda_handler"
  runtime       = "python3.10"
  filename      = "${path.module}/../generate_daily_report.zip"
}

# --------------------------
# S3 Event Notification for process_flights_data
# --------------------------
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_flights_data.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# --------------------------
# Lambda Permission to allow S3 to invoke
# --------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_flights_data.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}

# --------------------------
# CloudWatch Event to trigger generate_daily_report daily
# --------------------------
resource "aws_cloudwatch_event_rule" "daily_report" {
  name                = "daily_report_rule"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "daily_report_target" {
  rule      = aws_cloudwatch_event_rule.daily_report.name
  target_id = "generate_daily_report"
  arn       = aws_lambda_function.generate_daily_report.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_daily_report.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report.arn
}

