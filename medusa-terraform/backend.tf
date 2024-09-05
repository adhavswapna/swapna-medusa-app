terraform {
  backend "s3" {
    bucket         = "ecs-s3-tf-bucket"  # Replace with your actual bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecs-statelock-tf-dynamodb"  # Replace with your actual DynamoDB table name
    encrypt        = true
  }
}

resource "aws_iam_policy" "s3-ecs-tf-access-policy" {
  name = "s3-ecs-tf-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:ListMultipartUploadParts"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "s3:*",
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::ecs-statelock-tf-bucket",
          "arn:aws:s3:::ecs-statelock-tf-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb-ecs-tf-access-policy" {
  name = "dynamodb-ecs-tf-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "dynamodb:List*",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "dynamodb:*",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}