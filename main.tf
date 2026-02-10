terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}


# See if the GitHub OIDC provider already exists
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # This will return empty if not found, rather than error
  count = 1
}

locals {
  oidc_provider_exists = length(data.aws_iam_openid_connect_provider.github) > 0 && try(data.aws_iam_openid_connect_provider.github[0].arn, "") != ""
}

# Only create if it doesn't exist
resource "aws_iam_openid_connect_provider" "github" {
  count = local.oidc_provider_exists ? 0 : 1

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Use this output to reference the ARN regardless of creation method
locals {
  oidc_provider_arn = local.oidc_provider_exists ? data.aws_iam_openid_connect_provider.github[0].arn : aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_role" "github_actions" {
  name        = var.name
  description = "${var.name} role for GitHub Actions to assume"

  assume_role_policy = <<-EOF
    {
        "Statement": [
            {
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition":{
                    "ForAllValues:StringLike": {
                        "token.actions.githubusercontent.com:aud":"sts.amazonaws.com",
                        "token.actions.githubusercontent.com:sub":${jsonencode(var.subjects)}
                    }
                },
                "Effect":"Allow",
                "Principal":{
                    "Federated":"${local.oidc_provider_arn}"
                }
            }
        ],
        "Version":"2012-10-17"
    }
  EOF

  tags = var.tags

  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy" "policy" {
  for_each = var.policies

  name   = "${aws_iam_role.github_actions.name}_${each.key}"
  role   = aws_iam_role.github_actions.name
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}

