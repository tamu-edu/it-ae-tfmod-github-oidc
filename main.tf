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

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name        = "${var.name}"
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
                    "Federated":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
                }
            }
        ],
        "Version":"2012-10-17"
    }
  EOF

  dynamic "inline_policy" {
    for_each = var.inline_policies
    content {
      name   = "inline_policy_${inline_policy.key}"
      policy = inline_policy.value
    }
  }

  managed_policy_arns = var.managed_policy_arns

  tags = var.tags
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
