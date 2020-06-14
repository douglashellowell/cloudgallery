# Needed:
# VPC
# Security Group
# EC2
# AMI role ✅
# security policy ✅
# role/policy joiner
# s3 bucket

# ? need
# Lambda func
# DynamoDB
# Permissions for those
# cloudwatch logs

# Result
# upload to s3
# triggers lambda
# sends upload data to dynamoDB
# nextJS site serves images
# + upload feature?

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# AWS provder
provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

#Variables
variable "bucket_name" {
  description = "s3 bucket name"
}
variable "key_name" {
  description = "pem key name on local machine"
}

# s3 bucket
resource "aws_s3_bucket" "image_bucket" {
  bucket = var.bucket_name
}

# dynamoDB table
resource "aws_dynamodb_table" "dynamo_bucket_registry" {
  name = "bucket_image_registry"
  # ?? idk what these do
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "ImageID"
  range_key      = "ImageTitle"

  attribute {
    name = "ImageID"
    type = "S"
  }

  attribute {
    name = "ImageTitle"
    type = "S"
  }

  attribute {
    name = "Score"
    type = "N"
  }

  global_secondary_index {
    name = "ImageIndex"
    hash_key = "ImageTitle"
    range_key = "Score"
    write_capacity = 10
    read_capacity = 10
    projection_type = "INCLUDE"
    non_key_attributes = ["ImageID"]
  }
}

# iam role
resource "aws_iam_role" "bucket_db_access" {
  name               = "bucket_db_access"
  #  needs s3?
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dynamodb.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "log.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
  EOF
}

# iam policy
# ? add lambda, dynamoDB access too??
resource "aws_iam_policy" "bucket_db_access_policy" {
  name = "bucket_db_access_policy"
  #   NOTE: this works with file() or EOF, leaving it as EOF for readibility
  policy = <<EOF
{ 
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "${aws_s3_bucket.image_bucket.arn}",
        "${aws_s3_bucket.image_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:*"],
      "Resource": [
        "${aws_dynamodb_table.dynamo_bucket_registry.arn}",
        "${aws_dynamodb_table.dynamo_bucket_registry.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["lambda:*"],
      "Resource": [
        "${aws_lambda_function.register_image_function.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

#  iam instance
resource "aws_iam_instance_profile" "iam_profile" {
  name = "iam_profile"
  role = aws_iam_role.bucket_db_access.name
}

# iam policy attachment
resource "aws_iam_role_policy_attachment" "iam_policy_attachment" {
  role       = aws_iam_role.bucket_db_access.name
  policy_arn = aws_iam_policy.bucket_db_access_policy.arn
}

#  AMI
data "aws_ami" "amazon_linux_2" {
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]

  most_recent = true
}

# VPC
data "aws_vpc" "default" {
  # ????
  default = true
}

#  security group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance
resource "aws_instance" "s3_access" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name = var.key_name

  security_groups = [aws_security_group.allow_ssh.name]

  iam_instance_profile = aws_iam_instance_profile.iam_profile.name

  tags = {
      Name = "S3-access"
  }
}

# Lambda 
data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda.js"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "register_image_function" {
  filename = "lambda_function.zip"
  function_name = "register_image_function"
  role = aws_iam_role.bucket_db_access.arn
  handler = "lambda.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime = "nodejs12.x"
}

# allow execution from s3 bucket
resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_image_function.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.image_bucket.arn
}

# allow write to DyndamoDB
# resource "aws_lambda_permission" "allow_dynamoDB" {
  
# }


resource "aws_s3_bucket_notification" "bucket_trigger" {
  bucket = aws_s3_bucket.image_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.register_image_function.arn
    events = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # Prev .tf config # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# provider "aws" {
#   profile = "default"
#   region = "eu-west-1"
# }


# # you can declare varibles
# variable "bucket_name" {}
# variable "key_name" {}



# # declares resource type comes from terraform docs
# resource "aws_s3_bucket" "example" {
#     bucket  = var.bucket_name
# }

# resource "aws_iam_role" "s3_bucket_access" {
#   name = "s3-bucket-access"
#   assume_role_policy = <<EOF
# {
#     "Verison" : "2012-10-17",
#     "Statement": [
#         {
#             "Action": "sts:AssumeRole",
#             "Principal": {
#                 "Service" : "ec2.amazonaws.com"
#             },
#             "Effect": "Allow"
#         }
#     ]
# }
# EOF
# }


# resource "aws_iam_policy" "bucket_access_policy" {
#     name    = "BucketAccessPolicy"
#     policy  = <<EOF
# {
#         "Version": "2012-10-17",
#         "Statement": [
#             {
#                 "Effect": "Allow",
#                 "Action": ["s3:*"],
#                 "Resource": [
#                     "${aws_s3_bucket.example.arn}",
#                     "${aws_s3_bucket.example.arn}/*"
#                 ]
#             }
#         ]
#     }
#     EOF
# }


# resource "aws_iam_instance_profile" "s3_access" {
#   name = "s3_access"
#   role = aws_iam_role.s3_bucket_access.name
# }


# resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
#   role = aws_iam_role.s3_bucket_access.name
#   policy_arn = aws_iam_policy.bucket_access_policy.arn
# }

# data "aws_ami" "amazon_linux_2" {
#     filter {
#         name = "name"
#         values = ["amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"]
#     }

#     filter {
#         name = "virtualization-type"
#         values = [ "hvm"]
#     }

#     owners = ["amazon"]

#     most_recent = true
# }

# data "aws_vpc" "default" {
#     # ????
#     default = true
# }

# resource "aws_security_group" "allow_ssh" {
#   name = "allow_ssh"
#   description = "allow SSH inbound traffic"
#   vpc_id = data.aws_vpc.default.id

#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "s3_access" {
#   ami = data.aws_ami.amazon_linux_2.id
#   instance_type = "t2.micro"
#   key_name = var.key_name

#   security_groups = [aws_security_group.allow_ssh.name]

#   iam_instance_profile = aws_iam_instance_profile.s3_access.name

#   tags = {
#       Name = "S3-access"
#   }
# }


# # EC2 instance - needs:
# # AMI
# # VPC
# # Security groups
# # Role%
