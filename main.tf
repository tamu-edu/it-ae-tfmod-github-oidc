terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.27.0"
    }
  }
}

locals {
  provider_id = "token.actions.githubusercontent.com"
  tag_key     = "CreatedByOidcModuleId"
}

resource "random_uuid" "this" {}

data "aws_caller_identity" "current" {}

# See if a GitHub OIDC provider already exists
data "awscc_iam_oidc_providers" "all" {}

locals {
  oidc_providers_filtered = [for id in data.awscc_iam_oidc_providers.all.ids : id if strcontains(id, local.provider_id)]
  oidc_provider_exists    = length(local.oidc_providers_filtered) > 0
}

# If one does, look it up to get the tags
data "aws_iam_openid_connect_provider" "existing" {
  count = local.oidc_provider_exists ? 1 : 0
  arn   = local.oidc_providers_filtered[0]
}

# If an OIDC provider doesn't exist, we'll create it so it will be owned by this module
# Otherwise, check if it was created by this module so it stays in scope by a tag
locals {
  create_oidc_provider = local.oidc_provider_exists == false ? true : (
    try(data.aws_iam_openid_connect_provider.existing[0].tags[local.tag_key], "") == random_uuid.this.result
  )
}

# Create if it doesn't exist, or if this module owns it
resource "aws_iam_openid_connect_provider" "github" {
  count = local.create_oidc_provider ? 1 : 0

  url             = "https://${local.provider_id}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    CreatedByOidcModuleId = random_uuid.this.result
  }
}

locals {
  oidc_provider_arn = local.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : local.oidc_providers_filtered[0]
  role_name = length(var.name) > 64 ? substr(var.name, 0, 38) : var.name # truncated to 64 characters
}

resource "aws_iam_role" "github_actions" {
  name_prefix        = local.role_name
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

  tags = merge(var.tags, {
    CreatedByOidcModuleId = random_uuid.this.result
    FullRoleName = replace(var.name, "/[^\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]/", "_")
  })

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

