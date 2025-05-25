provider "aws" {
  region = "ap-south-1"
}

# Create an SQS Queue
resource "aws_sqs_queue" "event_queue" {
  name                      = "sample-event-queue"
  visibility_timeout_seconds = 30
}

# Create an IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "sample-lambda_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

}

# Attach permissions to access SQS
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_sqs_access"
  description = "Allows Lambda to read messages from SQS"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "logs:*",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# zip file creation for deployment of python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda.zip"
}

# Create a Lambda Function
resource "aws_lambda_function" "lambda" {
  function_name    = "sample_python_lambda"
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  role            = aws_iam_role.lambda_role.arn
  filename        = "lambda.zip" # Make sure you have a zip of the Python function

  source_code_hash = filebase64sha256("lambda.zip")
}

# SQS Trigger for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn  = aws_sqs_queue.event_queue.arn
  function_name     = aws_lambda_function.lambda.arn
  batch_size        = 5
}
